# Minecraft Models — Working Rules

This document is the authoritative development standard for `nusretm/minecraft_models`. Read this file, `docs/continuity/CURRENT_TARGET.md`, and the active model design before any development.

## Scope and ownership

- Package: `minecraft_models`, an independent pure-Dart repository shared by `mtn_launcher` and `minecraft_loader_version_list`.
- Common value models/enums and the approved generic `MtnMinecraftGameLoaderVersionList` index belong here.
- The VersionList may perform shared HTTP metadata requests and best-effort JSON cache operations. Provider-specific wire parsing, artifact installation, UI and game-launch orchestration do not belong here.
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
- Preserve exact upstream IDs and source URLs without case normalization, truncation or reconstruction.
- Models should be immutable, small and explicit about nullability/default values. Use deterministic and validated JSON for data that must serialize.
- Model-only code cannot assume that a source URL is an installer JAR; URL interpretation belongs to the provider.
- Providers own their newest-first source catalog and build ordering. VersionList preserves that order, filters Minecraft version/type, and performs best-effort metadata/cache access; exact/default loader choice and launcher orchestration belong to consumers.

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
- Consumers should depend on a fixed approved Git commit/tag, not a drifting `main` ref.

## Integration order

1. Approve and implement the four foundation models here.
2. Validate on Windows, record a fixed commit/tag, separately approve merge.
3. Migrate `minecraft_tools/minecraft_loader_version_list` without duplicate types.
4. Integrate `mtn_launcher` in a separate approved checkpoint.
5. Keep Forge V1-B2 legacy libraries and V1-B3 launcher execution changes independently gated.


---

## Shared engineering refinements (2026-10)

The existing project rules and continuity decisions remain authoritative. Apply these refinements to **new code**; do not mass-rename or restructure working implementations without a separate approved checkpoint.

- **Naming and class families:** Abstract classes end in `Abs`; concrete reusable base classes end in `Base`. Concrete specializations retain the conceptual family prefix and append the specialization. Related enums and types retain the prefix (`ClassPageType`, `ClassPageContentHome`). Do not invent inheritance layers merely to satisfy the naming scheme. Respect Rust and framework idioms.
- **Shared logic:** Move semantically shared behavior from sibling implementations to the lowest appropriate common ancestor. Keep specialized behavior at its owner. Avoid sprawling private helpers, forwarding layers, and duplicate conditionals; use composition where inheritance would be artificial.
- **API, state, errors:** Design explicit public contracts and meaningful parameters; identify owners of mutable state and lifecycle. Define relevant invariants, retries, cancellation, cleanup, error/recovery semantics, and resource ownership. Do not suppress failures.
- **Layout:** Use subsystem/domain-first grouping within each language. Multi-language repositories may use root `docs/`, `rust/`, `dart/`, `ui/`, `scripts/`, and generated `build/` when applicable. Do not restructure existing repositories solely to match a template.
- **Build and FFI:** Ignore generated root `build/`. Maintain one authoritative published artifact location and avoid manual binary copies or stale FFI loading; define ABI and memory ownership when relevant.
- **Dependencies and review:** Request approval for new dependencies; preserve project-specific `.gitignore` rules, tracked sources and necessary lockfiles. Review actual diffs for architecture and behavior independently of tests; report synthetic and live validation separately.
