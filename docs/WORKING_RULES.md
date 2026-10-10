# Minecraft Models — Working Rules

This document is the authoritative development standard for `nusretm/minecraft_models`. Read this file, the **current** `docs/continuity/CURRENT_TARGET.md`, and `docs/continuity/CONSUMER_INTEGRATION.md` before any development or consumer migration. Historical foundation plans or archived continuity are not current API specifications.

## Scope and ownership

- Package: `minecraft_models`, an independent pure-Dart repository shared by `mtn_launcher` and `minecraft_loader_version_list`.
- Common value models/enums and a single public, constructible `MtnMinecraftGameLoaderVersionList` belong here. Internal helper and five provider subclasses implement loader-specific metadata discovery.
- The public VersionList owns shared HTTP metadata requests, best-effort JSON cache, error handling, and dispatch by `MtnMinecraftLoaderType`. An internal `MtnMinecraftGameLoaderVersionListHelper` owns a reference to that VersionList; Vanilla, Fabric, Quilt, Forge and NeoForge helpers own their endpoint URLs and upstream wire parsing. Artifact installation, UI and game launch stay outside this package.
- Keep dependency direction one way: consumers depend on `minecraft_models`; models never import consumers.
- Avoid speculative class hierarchies/frameworks and duplicating types already owned here.

## Workflow and approval

- Before work, establish `main`/feature branch, HEAD, local changes and authoritative current target; do not overwrite user files or test logs.
- Work in small, reviewable checkpoints. Present design and public API before implementation.
- **No production implementation or change of an agreed API without explicit user approval.**
- Use scoped feature branches and GitHub commits/PRs. No merge without separate explicit user approval; inspect the actual diff.
- No backwards-compatibility or deprecated alias layers before the first release unless the user explicitly requests them.
- Keep `docs/continuity/CURRENT_TARGET.md` and design/handoff docs updated for each substantive checkpoint.

## Shared model rules

- One semantic type has one implementation. Consumers import or re-export the same Dart type; do not add conversion wrappers for copied enums.
- `MtnMinecraftGameVersionType` describes Minecraft game version type.
- `MtnMinecraftGameLoaderChannel` describes loader-build publication channel; an unknown channel is not automatically stable.
- `MtnMinecraftLoaderType` is the canonical, exported Minecraft loader identity shared with the launcher (vanilla, fabric, forge, neoforge, quilt). Avoid duplicate enum definitions or alias strings in consumers. `fromName` trims and ignores case; unknown inputs return null instead of implicitly selecting Vanilla.
- Preserve exact upstream IDs and source URLs without case normalization, truncation or reconstruction.
- Models should be immutable, small and explicit about nullability/default values. Use deterministic and validated JSON for data that must serialize.
- Model-only code cannot assume that a source URL is an installer JAR; URL interpretation belongs to the provider.
- Internal provider helpers own source discovery and provider-specific ordering; the **single public constructible VersionList** preserves returned order, filters Minecraft version/type, and performs best-effort metadata/cache access. Consumer launch and exact/default loader selection remain outside this package.
- VersionList's public constructor accepts `loaderType: MtnMinecraftLoaderType`. It selects one internal provider helper; the helpers override `doLoadFromWeb()` and `doGenerateMinecraftVersionList(mcVersion, types)` and never own separate HTTP/cache/error state. Neither `MtnMinecraftGameLoaderVersionListHelper` nor the five provider subclasses are barrel exports. Keep provider parsing inside provider files, with small shared pure parsing helpers where genuinely needed.
- Cache file identity uses `loaderType.name`, preserving the previous Vanilla/Fabric/Forge/NeoForge/Quilt cache filenames. Do not add a `loaderName` compatibility field before the first release.
- Use `MtnMinecraftError` for cache (1000-range) and download (2000-range) failures. Successful operations use `none(0)`. Expose the typed error plus its numeric code/message; use `VersionList._setError(MtnMinecraftError, [message])` for updates, and include HTTP status details in the message without a separate HTTP status field. Non-fatal failures must not prevent using available catalog data.

## Naming and architecture

- Honor the agreed `MtnMinecraft...` public names and put related classes in a clear family.
- Keep domain names as enums/value identities, not repeated raw strings, except provider-specific wire format boundaries outside this repository.
- No provider-specific switches or wire-format constants inside shared models.
- Do not create additional public models without demonstrated shared demand and approval.

## Dart hygiene and validation

- **Never run `dart format` on pure Dart**, unless the user explicitly requests it; natural long lines may remain for readability.
- From the package root validate with `dart pub get`, `dart analyze`, `dart test`, `git diff --check`, `git diff --stat`, and `git status`.
- Library .gitignore excludes `.dart_tool/`, `build/`, `pubspec.lock`; do not commit generated files or unrelated logs.
- Do not claim tests passed without actual local/Windows or runner evidence.
- Do not generate patch files in place of GitHub commits/PRs.
- Consumers should depend on a fixed approved Git commit/tag, not a drifting `main` ref. Validated PR #7 implementation baseline: `1c4e346ed42bf9f15b0259c8efb2f7d3011758a3`. Follow `docs/continuity/CONSUMER_INTEGRATION.md`; never add duplicate canonical enums or import the internal `src/` helper classes.

## Integration status and next gates

- Shared models and the single public VersionList/helper architecture were implemented, **merged (PR #7)** and Windows validated (40 tests passed and two Minecraft versions checked live on all five loaders).
- `minecraft_tools/minecraft_loader_version_list` migration is **not yet performed** in this repository. Review consumer definitions and APIs in a separate approved checkpoint; prevent competing canonical type identity.
- `mtn_launcher` integration is **not yet performed** in this repository. Pin the validated package SHA; preserve its launcher-specific download manager, task orchestration, artifact verification and execution responsibilities.
- Further Forge installer, trust/source acquisition and runtime execution changes are **independent checkpoints**, requiring their own design, tests and merge approvals.


---

## Shared engineering refinements (2026-10)

The existing project rules and continuity decisions remain authoritative. Apply these refinements to **new code**; do not mass-rename or restructure working implementations without a separate approved checkpoint.

- **Naming and class families:** Abstract classes end in `Abs`; concrete reusable base classes end in `Base`. Concrete specializations retain the conceptual family prefix and append the specialization. Related enums and types retain the prefix (`ClassPageType`, `ClassPageContentHome`). Do not invent inheritance layers merely to satisfy the naming scheme. Respect Rust and framework idioms.
- **Shared logic:** Move semantically shared behavior from sibling implementations to the lowest appropriate common ancestor. Keep specialized behavior at its owner. Avoid sprawling private helpers, forwarding layers, and duplicate conditionals; use composition where inheritance would be artificial.
- **API, state, errors:** Design explicit public contracts and meaningful parameters; identify owners of mutable state and lifecycle. Define relevant invariants, retries, cancellation, cleanup, error/recovery semantics, and resource ownership. Do not suppress failures.
- **Layout:** Use subsystem/domain-first grouping within each language. Multi-language repositories may use root `docs/`, `rust/`, `dart/`, `ui/`, `scripts/`, and generated `build/` when applicable. Do not restructure existing repositories solely to match a template.
- **Build and FFI:** Ignore generated root `build/`. Maintain one authoritative published artifact location and avoid manual binary copies or stale FFI loading; define ABI and memory ownership when relevant.
- **Dependencies and review:** Request approval for new dependencies; preserve project-specific `.gitignore` rules, tracked sources and necessary lockfiles. Review actual diffs for architecture and behavior independently of tests; report synthetic and live validation separately.
