# Current Target — minecraft_models

Date: 2026-10-10
Repository: `nusretm/minecraft_models`
Dart package: `minecraft_models`
Feature baseline `main` HEAD: `f7649860787f261460e3495bb174e4902aa51f1d`
Active checkpoint: **Canonical loader enum + concrete provider VersionList architecture, [draft PR #6](https://github.com/nusretm/minecraft_models/pull/6) — post-refactor Windows validation pending, merge not approved**
Historical MOD-1 foundation baseline: `a4139746927902770c8f09eeeba41e3d02216c98` (subsequently merged)

## Canonical loader identity — MtnMinecraftLoaderType (2026-10-10)

- Canonical type: `lib/src/mtn_minecraft_loader_type.dart`, exported through `lib/minecraft_models.dart` for both this package and later `MtnLauncher` consumption. Values are `vanilla`, `fabric`, `forge`, `neoforge`, `quilt`.
- Public base field/constructor rename: `loaderName: String` → `loaderType: MtnMinecraftLoaderType`. Provider constructors fix their enum values; consumers still pass only `cacheDirectory` and optional `cacheDuration`.
- `MtnMinecraftLoaderType.fromName(String?)` is case-insensitive and trims whitespace; unsupported names return null without throwing or silently choosing Vanilla. `.name` is the built-in canonical string form.
- The cache key derives from `loaderType.name`; previous provider filenames remain unchanged. No backwards-compatibility property or separate launcher enum is added in this repository.
- Added tests for all five enum values, safe name conversion and provider type identities. Windows analyzer, test suite and live provider smoke **must be rerun after this change**; no merge approval yet.

## Concrete VersionList providers — approved implementation (2026-10-10)

- User explicitly approved implementing the provider architecture. The same `MtnMinecraftGameLoaderVersionList` name is kept as an abstract common base; it owns caching, HTTP, diagnostics and lifecycle.
- Remove public `onLoadFromWeb` and `onGenerateMinecraftVersionList` constructor callbacks. Concrete subclasses override `doLoadFromWeb()` and `doGenerateMinecraftVersionList(mcVersion, types)`. Each fixes its own `loaderType` enum value in the superclass initializer; consumers only pass `cacheDirectory` (optional cache duration).
- Provider sources: `lib/src/loaders/mtn_minecraft_game_loader_version_list_vanilla.dart`, `..._fabric.dart`, `..._quilt.dart`, `..._forge.dart`, `..._neoforge.dart`. All five exported via `minecraft_models.dart`.
- The generic value model `MtnMinecraftGameLoaderVersion` remains unchanged: `fromRawData()` is explicitly canceled. Provider-specific mappings (including NeoForge) are owned by each provider; small reusable parsing rules live in `loaders/src/`.
- `getFromMinecraftVersion()` can initialize the general catalog if needed. It must not persist an empty per-game cache after a catalog failure. Preserve valid stale cache fallback, enum-based errors and provider order.
- `example/game_loader_version_lists.dart` now instantiates the five ready-made providers; it contains no callbacks or wire-format parsing.
- Offline tests include concrete provider fixtures for Vanilla, Fabric, Quilt, Forge, NeoForge; test-only subclasses exercise shared caching/error behavior. Baseline Windows validation before the refactor: `dart analyze` clean and 29 tests passed (user run). **Post-refactor Dart analysis, tests, and live five-provider smoke still need Windows execution and review.**
- PR #6 remains draft. Do not merge without separate approval.

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

Provide shared pure-Dart Minecraft model identity and the generic callback-driven `MtnMinecraftGameLoaderVersionList` for consumers. The VersionList may use HTTP metadata requests and best-effort filesystem cache. Provider wire-format parsing, artifact installation, UI and game launch are outside this package.

## Implemented foundation contracts

1. `MtnMinecraftGameVersionType` — eight-value Minecraft game-version enum.
2. `MtnMinecraftGameLoaderChannel` — independent loader publication channel enum.
3. `MtnMinecraftGameLoaderVersion` — immutable build identity with exact version/URL, type, channel and JSON/equality.
4. `MtnMinecraftGameLoaderVersionList` — generic callback-owned catalog loading, version filtering and metadata retrieval, preserving provider order.
5. `MtnMinecraftGameLoaderVersionListCache` — best-effort JSON persistence with non-fatal read/write failures.

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
