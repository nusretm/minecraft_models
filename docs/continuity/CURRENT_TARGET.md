# Current Target — minecraft_models

Date: 2026-10-10
Repository: `nusretm/minecraft_models`
Dart package: `minecraft_models`
Feature baseline `main` HEAD: `f7649860787f261460e3495bb174e4902aa51f1d`
Active checkpoint: **LVL-I3A optional source SHA-1 metadata — Windows validated; PR #5 open; squash merge pending separate approval**
Historical MOD-1 foundation baseline: `a4139746927902770c8f09eeeba41e3d02216c98` (subsequently merged)

## VersionList resilience — 2026-10-10

- Branch: `fix/game-loader-version-list-resilience`, based on `f764986`.
- Keep `MtnMinecraftGameLoaderVersionList` and `MtnMinecraftGameLoaderVersionListCache` names and public callback contracts unchanged. They represent a generic Minecraft game-loader version index, not a launcher-specific implementation.
- Deliberately non-fatal HTTP/cache failures remain non-fatal to callers. Preserve HTTP statuses, reset diagnostics on success, provide cache write diagnostics, handle filesystem metadata exceptions, retry malformed caches from the provider, and use valid expired cache after a failed refresh.
- Filter returned loader builds by requested Minecraft version and types; do not reorder provider results, whose first element is already the newest compatible published build.
- Public barrel exports the generic VersionList. It never downloads game artifacts, verifies SHA-1, installs loaders or runs Minecraft.
- Focused regression tests are authored but **not executed in this environment**. Windows `dart pub get`, `dart analyze`, `dart test`, source diff review and explicit merge approval remain outstanding.
- The subsequent LVL-I3A section records older model/history and should not be mistaken for evidence of SHA-1 support in the current renamed `MtnMinecraftGameLoaderVersion`.
## LVL-I3A — Optional source SHA-1 metadata (2026-10-10)

- **Approved by user for implementation** as a bounded upstream model contract needed by MtnLauncher Vanilla VersionList migration.
- Implemented and Windows validated (analyzer clean, focused 7/7, full 21/21, diff check passed) on baseline main `6791f0b4ea36f7e7053084d6e96bfa52b0369918`; feature commit `10d7c02b4a3edc69d3f6f685b1e8384ade38a225` pushed to `feature/loader-version-source-sha1-metadata`; [PR #5](https://github.com/nusretm/minecraft_models/pull/5) is open, awaiting separate squash-merge approval.
- Extend existing immutable `MtnLauncherGameLoaderVersion` with optional `String? sha1`: exact provider-provided source checksum metadata associated with `url`. Keep `const` constructor, required values, type, channel and URL identity unchanged. Absent `sha1` => null; `toJson` only emits the key when non-null; explicitly malformed JSON `sha1` fails as `FormatException`. Equality and hashCode include the field.
- No byte hashing, digest trust, downloader, VersionList provider callbacks, cache IO changes, MtnLauncher application changes or sibling repository commits in this checkpoint. `minecraft_loader_version_list` already delegates item serialization to model `toJson/fromJson` but remains pinned to an older model SHA until a separately validated consumer dependency update.
- Full bounded design/acceptance details: `LVL_I3A_SOURCE_SHA1_METADATA.md`. Do not claim source integrity verification or successful consumer integration from model tests alone.

## Authoritative files

- `README.md` — user-authored initial project overview; preserve existing content.
- `docs/WORKING_RULES.md` — authoritative working and architecture standard.
- `docs/continuity/MODEL_FOUNDATION_DESIGN.md` — model scope and consumer migration boundaries.
- This file — current checkpoint/status/handoff.

## Project objective

Provide one pure-Dart model identity for the independent `mtn_launcher` and `minecraft_loader_version_list` packages. No duplicate `MtnMinecraftGameVersionType` or conversion/alias bridge. No HTTP, caching, provider-specific parsing, UI, or game launch in this package.

## Implemented foundation contracts

1. `MtnMinecraftGameVersionType` — existing eight-value Minecraft game-version enum.
2. `MtnMinecraftGameLoaderMinecraftVersion` — named record `(mcVersion, versionId, type)` preserving exact upstream ID.
3. `MtnMinecraftGameLoaderChannel` — `stable, beta, alpha, experimental, unknown` for loader build channel.
4. `MtnMinecraftGameLoaderVersion` — exact version, Minecraft game version, provider-defined URL, game version type and loader channel; immutable JSON-capable value with structural equality.

The loader build constructor defaults `channel` to `unknown`. JSON requires
non-empty `mcVersion`, `version`, `url`, and `type` strings. An absent `channel`
maps to `unknown`; explicit invalid values are rejected. Serialization always
writes the channel. Exact IDs and URLs are preserved without normalization.

`MtnMinecraftGameVersion` comparison model is deferred for separate review; no changes to release ordering semantics or launcher runtime in DOC-0.

## Related repositories and checkpoints

- `nusretm/mtn_launcher`: Forge V1-B1 already merged; V1-B2 trust/source acquisition and V1-B3 TaskList remain separately gated.
- `nusretm/minecraft_tools`: VersionList `feature/minecraft-loader-version-list-foundation`, PR #57, is a later consumer migration. Its current in-package model definitions are retained until the fixed shared model dependency is ready.
- The VersionList API owns catalog/cache/metadata/selection, not this package.
- CLI future goal: `--loader fabric` resolves a compatible default build, `--loader-ver` selects one exact full build. That selection algorithm is **outside** the shared value models.

## Historical MOD-1 validation and checkpoint

- Windows validation passed: `dart pub get`, `dart analyze`, and `dart test` (14 tests).
- Final diff hygiene is checked with `git diff --check`, `git diff --stat`, and `git status`.
- Inspect the complete feature-branch diff before any commit or PR.
- Commit, PR, tag, merge, and consumer migration each remain separately gated.
- After an approved fixed Git SHA/tag exists, migrate VersionList first and MTN Launcher later.

**No commit, PR, tag, merge, or consumer dependency migration is authorized by MOD-1 implementation approval.**
