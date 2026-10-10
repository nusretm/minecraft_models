# Current Target — minecraft_models

Date: 2026-10-10
Repository: `nusretm/minecraft_models`
Dart package: `minecraft_models`
Feature baseline `main` HEAD: `f7649860787f261460e3495bb174e4902aa51f1d`
Active checkpoint: **Refactor VersionList to internal loader helpers — approved implementation on `refactor/version-list-internal-loader-helpers`; post-refactor Windows validation pending; merge NOT approved (2026-10-10)**
Historical MOD-1 foundation baseline: `a4139746927902770c8f09eeeba41e3d02216c98` (subsequently merged)

## Internal loader helpers — in progress (2026-10-10)

- Baseline `main`: `8dcaedbee9c2bb4afadcd9a2e7dbecf98ffd2930` (squash merge of PR #6; user confirmed clean and synchronized after deleting local and remote feature branches).
- User explicitly approved implementation of this design after planning; **no merge approval yet**. Work branch: `refactor/version-list-internal-loader-helpers`.
- Public `MtnMinecraftGameLoaderVersionList({required cacheDirectory, required loaderType, cacheDuration})` is now constructible, not abstract. It retains the `items`, `load()`, `getFromMinecraftVersion()`, `downloadUrl()`, `sortItems()`, typed errors and cache lifecycle.
- New `MtnMinecraftGameLoaderVersionListHelper` is an **internal abstract class**, with constructor `(MtnMinecraftGameLoaderVersionList versionList)`, and override hooks `doLoadFromWeb()` and `doGenerateMinecraftVersionList(mcVersion, types)`.
- Internal loader implementations `MtnMinecraftGameLoaderVersionListVanilla/Fabric/Forge/NeoForge/Quilt` now **extend Helper**, not VersionList. Each helper gets its owning `versionList` and calls its public `downloadUrl()`, `items` or `sortItems()` as needed. No helper has independent cache/error/HTTP state.
- VersionList privately dispatches by exhaustive `switch(loaderType)`, lazily creating one helper. Keep helper and five concrete loader classes **out of `lib/minecraft_models.dart` exports**. `MtnMinecraftGameLoaderVersion` remains the public immutable data model, unmodified.
- No loader name/string conversions or provider callback constructors. No new dependencies. Metadata ordering, cache filenames based on `loaderType.name`, error/fallback behavior and provider sources should remain unchanged.
- Example and offline tests are adapted to public VersionList dispatch. **Dart SDK not available in authoring runtime: post-change `dart analyze`, `dart test`, live Vanilla/Fabric/Quilt/Forge/NeoForge smoke and diff validation require Windows execution before considering merge.**
- PR #6's 40 passing tests and live smoke are evidence for the **previous** architecture, not for this new refactor.
- Separate consumer integrations into `mtn_launcher` / `minecraft_tools` are not part of this branch.

## PR #6 — Windows verification and closure gate (2026-10-10)

- User executed validation on branch `fix/game-loader-version-list-resilience` at HEAD `ed4c06626455157b05454b8d202bece72df5189a`: `dart analyze` → no issues; `dart test` → 40/40 passed; `git diff --check origin/main...HEAD` → clean; `git status` → clean and synchronized with origin.
- Live `dart run example/game_loader_version_lists.dart 1.21.11` returned builds for all five: Vanilla 9, Fabric 253, Quilt 307, Forge 31, NeoForge 45. These are metadata discovery results, not validation that all supplied artifact URLs exist or that Minecraft launches.
- Quilt upstream order included `0.20.0-beta.9`, `0.20.0-beta.7`, `0.20.0-beta.8`. Do not infer complete semantic or publication ordering from the first few values. Sorting/selection policy is a separate follow-up, not part of this closure.
- User explicitly authorized **merge and cleanup** after this evidence. Update this continuity record before merge. Final merged SHA and remote/local branch cleanup should be verified after the actual operations; approval alone is not evidence of completion.
- Consumer integration in `mtn_launcher` or `minecraft_tools` is **not** included in this PR. Consumers should pin an approved fixed commit SHA/tag once merged.

## Canonical loader identity — MtnMinecraftLoaderType (2026-10-10)

- Canonical type: `lib/src/mtn_minecraft_loader_type.dart`, exported through `lib/minecraft_models.dart` for both this package and later `MtnLauncher` consumption. Values are `vanilla`, `fabric`, `forge`, `neoforge`, `quilt`.
- Public base field/constructor rename: `loaderName: String` → `loaderType: MtnMinecraftLoaderType`. Provider constructors fix their enum values; consumers still pass only `cacheDirectory` and optional `cacheDuration`.
- `MtnMinecraftLoaderType.fromName(String?)` is case-insensitive and trims whitespace; unsupported names return null without throwing or silently choosing Vanilla. `.name` is the built-in canonical string form.
- The cache key derives from `loaderType.name`; previous provider filenames remain unchanged. No backwards-compatibility property or separate launcher enum is added in this repository.
- Added tests for all five enum values, safe name conversion and provider type identities. Post-change Windows verification was successful (40 passing tests and five live provider lookups); see PR #6 closure gate above.

## Concrete VersionList providers — approved implementation (2026-10-10)

- User explicitly approved implementing the provider architecture. The same `MtnMinecraftGameLoaderVersionList` name is kept as an abstract common base; it owns caching, HTTP, diagnostics and lifecycle.
- Remove public `onLoadFromWeb` and `onGenerateMinecraftVersionList` constructor callbacks. Concrete subclasses override `doLoadFromWeb()` and `doGenerateMinecraftVersionList(mcVersion, types)`. Each fixes its own `loaderType` enum value in the superclass initializer; consumers only pass `cacheDirectory` (optional cache duration).
- Provider sources: `lib/src/loaders/mtn_minecraft_game_loader_version_list_vanilla.dart`, `..._fabric.dart`, `..._quilt.dart`, `..._forge.dart`, `..._neoforge.dart`. All five exported via `minecraft_models.dart`.
- The generic value model `MtnMinecraftGameLoaderVersion` remains unchanged: `fromRawData()` is explicitly canceled. Provider-specific mappings (including NeoForge) are owned by each provider; small reusable parsing rules live in `loaders/src/`.
- `getFromMinecraftVersion()` can initialize the general catalog if needed. It must not persist an empty per-game cache after a catalog failure. Preserve valid stale cache fallback, enum-based errors and provider order.
- `example/game_loader_version_lists.dart` now instantiates the five ready-made providers; it contains no callbacks or wire-format parsing.
- Offline tests include concrete provider fixtures for Vanilla, Fabric, Quilt, Forge, NeoForge; test-only subclasses exercise shared caching/error behavior. Baseline before refactor: 29 tests passed; after refactor and typed enum: `dart analyze` clean, 40 tests passed and all five live provider lookups returned results (user Windows run).
- PR #6 merge and cleanup explicitly approved by user after Windows validation; preserve the post-merge verification and local cleanup gate.

## Earlier VersionList resilience and typed diagnostics — 2026-10-10

- Branch: `fix/game-loader-version-list-resilience`, based on `f764986`.
- Keep `MtnMinecraftGameLoaderVersionList` and `MtnMinecraftGameLoaderVersionListCache` names and public callback contracts unchanged. They represent a generic Minecraft game-loader version index, not a launcher-specific implementation.
- Add `lib/src/mtn_minecraft_error.dart` with `MtnMinecraftError.none`, `unknown`, 1000-range cache failures and 2000-range download failures; preserve `fromIndex`, `fromCode`, `isCacheError`, `isDownloadError`. `VersionList.error` is typed; `errorCode` derives from `.code`, and `_setError(MtnMinecraftError, [message])` centralizes updates. HTTP status may appear in `errorMessage`; no separate HTTP-status field is retained.
- Deliberately non-fatal HTTP/cache failures remain non-fatal to callers. Preserve HTTP failure classification and descriptive messages, reset diagnostics on success, provide cache write diagnostics, handle filesystem metadata exceptions, retry malformed caches from the provider, and use valid expired cache after a failed refresh.
- Filter returned loader builds by requested Minecraft version and types; do not reorder provider results, whose first element is already the newest compatible published build.
- Public barrel exports the generic VersionList. It never downloads game artifacts, verifies SHA-1, installs loaders or runs Minecraft.
- Historical checkpoint: the first five-provider example used `(list, mcVersion, types)` callbacks inside `example/`. The approved concrete-provider refactor above supersedes that structure. Its Forge/NeoForge source URL points to a Maven installer artifact rather than a JSON profile.
- The Fabric/Quilt general cache contains supported Minecraft-version index records (the `version` is the game identifier), while the per-game callback returns actual compatible loader builds. This distinction should not be confused with a full loader build catalog from the first callback.
- Four offline tests cover example parsing and one test confirms that requested `types` reaches the callback.
- Focused regression tests and enum tests are authored but **not executed in this environment**. Windows `dart pub get`, `dart analyze`, `dart test`, source diff review and explicit merge approval remain outstanding.
- The subsequent LVL-I3A section records older model/history and should not be mistaken for evidence of SHA-1 support in the current renamed `MtnMinecraftGameLoaderVersion`.

## Historical LVL-I3A — Optional source SHA-1 metadata (2026-10-10)

- **Approved by user for implementation** as a bounded upstream model contract needed by MtnLauncher Vanilla VersionList migration.
- Implemented and Windows validated (analyzer clean, focused 7/7, full 21/21, diff check passed) on baseline main `6791f0b4ea36f7e7053084d6e96bfa52b0369918`; feature commit `10d7c02b4a3edc69d3f6f685b1e8384ade38a225` pushed to `feature/loader-version-source-sha1-metadata`; [PR #5](https://github.com/nusretm/minecraft_models/pull/5) was merged; this historical checkpoint predates the later `MtnMinecraft...` renaming.
- Extend existing immutable `MtnLauncherGameLoaderVersion` with optional `String? sha1`: exact provider-provided source checksum metadata associated with `url`. Keep `const` constructor, required values, type, channel and URL identity unchanged. Absent `sha1` => null; `toJson` only emits the key when non-null; explicitly malformed JSON `sha1` fails as `FormatException`. Equality and hashCode include the field.
- No byte hashing, digest trust, downloader, VersionList provider callbacks, cache IO changes, MtnLauncher application changes or sibling repository commits in this checkpoint. `minecraft_loader_version_list` already delegates item serialization to model `toJson/fromJson` but remains pinned to an older model SHA until a separately validated consumer dependency update.
- Full bounded design/acceptance details: `LVL_I3A_SOURCE_SHA1_METADATA.md`. Do not claim source integrity verification or successful consumer integration from model tests alone.

## Authoritative files

- `README.md` — user-authored initial project overview; preserve existing content.
- `docs/WORKING_RULES.md` — authoritative working and architecture standard.
- `docs/continuity/MODEL_FOUNDATION_DESIGN.md` — model scope and consumer migration boundaries.
- This file — current checkpoint/status/handoff.

## Project objective

Provide shared pure-Dart Minecraft model identity, a typed loader identity enum and one public constructible `MtnMinecraftGameLoaderVersionList` that delegates provider-specific discovery to internal Vanilla/Fabric/Quilt/Forge/NeoForge helpers. VersionList owns best-effort HTTP metadata/cache handling; helper subclasses own wire parsing. Artifact installation, UI and game launch remain outside this package.

## Implemented foundation contracts

1. `MtnMinecraftGameVersionType` — eight-value Minecraft game-version enum.
2. `MtnMinecraftGameLoaderChannel` — independent loader publication channel enum.
3. `MtnMinecraftGameLoaderVersion` — immutable build identity with exact version/URL, type, channel and JSON/equality.
4. `MtnMinecraftGameLoaderVersionList` — public constructible catalog/cache/HTTP facade dispatching to internal helpers; preserves provider order.
5. `MtnMinecraftGameLoaderVersionListCache` — best-effort JSON persistence with non-fatal read/write failures.
6. `MtnMinecraftLoaderType` — canonical Vanilla/Fabric/Forge/NeoForge/Quilt enum with safe `fromName()`.
7. One internal helper base and five non-exported concrete provider helpers.

The loader build constructor defaults `channel` to `unknown`. JSON requires
non-empty `mcVersion`, `version`, `url`, and `type` strings. An absent `channel`
maps to `unknown`; explicit invalid values are rejected. Serialization always
writes the channel. Exact IDs and URLs are preserved without normalization.

`MtnMinecraftGameVersion` comparison model is deferred for separate review; no changes to release ordering semantics or launcher runtime in DOC-0.

## Related repositories and checkpoints

- `nusretm/mtn_launcher`: Forge V1-B1 already merged; V1-B2 trust/source acquisition and V1-B3 TaskList remain separately gated.
- `nusretm/minecraft_tools`: VersionList `feature/minecraft-loader-version-list-foundation`, PR #57, is a later consumer migration. Its current in-package model definitions are retained until the fixed shared model dependency is ready.
- Historical note (superseded): the VersionList API was formerly maintained separately; this package now contains the approved concrete provider subclasses.
- CLI future goal: `--loader fabric` resolves a compatible default build, `--loader-ver` selects one exact full build. That selection algorithm is **outside** the shared value models.

## Historical MOD-1 validation and checkpoint

- Windows validation passed: `dart pub get`, `dart analyze`, and `dart test` (14 tests).
- Final diff hygiene is checked with `git diff --check`, `git diff --stat`, and `git status`.
- Inspect the complete feature-branch diff before any commit or PR.
- Commit, PR, tag, merge, and consumer migration each remain separately gated.
- After an approved fixed Git SHA/tag exists, migrate VersionList first and MTN Launcher later.

**No commit, PR, tag, merge, or consumer dependency migration is authorized by MOD-1 implementation approval.**
