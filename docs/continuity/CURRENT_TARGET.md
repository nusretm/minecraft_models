# Current Target — minecraft_models

Date: 2026-10-09
Repository: `nusretm/minecraft_models`
Dart package: `minecraft_models`
Baseline `main` HEAD: `a4139746927902770c8f09eeeba41e3d02216c98`
Implementation branch: `feature/mod-1-model-foundation`
Status: **MOD-1 foundation implemented and locally validated — review pending**

## Authoritative files

- `README.md` — user-authored initial project overview; preserve existing content.
- `docs/WORKING_RULES.md` — authoritative working and architecture standard.
- `docs/continuity/MODEL_FOUNDATION_DESIGN.md` — model scope and consumer migration boundaries.
- This file — current checkpoint/status/handoff.

## Project objective

Provide one pure-Dart model identity for the independent `mtn_launcher` and `minecraft_loader_version_list` packages. No duplicate `MtnLauncherGameVersionType` or conversion/alias bridge. No HTTP, caching, provider-specific parsing, UI, or game launch in this package.

## Implemented foundation contracts

1. `MtnLauncherGameVersionType` — existing eight-value Minecraft game-version enum.
2. `MtnLauncherGameLoaderMinecraftVersion` — named record `(mcVersion, versionId, type)` preserving exact upstream ID.
3. `MtnLauncherGameLoaderChannel` — `stable, beta, alpha, experimental, unknown` for loader build channel.
4. `MtnLauncherGameLoaderVersion` — exact version, Minecraft game version, provider-defined URL, game version type and loader channel; immutable JSON-capable value with structural equality.

The loader build constructor defaults `channel` to `unknown`. JSON requires
non-empty `mcVersion`, `version`, `url`, and `type` strings. An absent `channel`
maps to `unknown`; explicit invalid values are rejected. Serialization always
writes the channel. Exact IDs and URLs are preserved without normalization.

`MtnLauncherGameVersion` comparison model is deferred for separate review; no changes to release ordering semantics or launcher runtime in DOC-0.

## Related repositories and checkpoints

- `nusretm/mtn_launcher`: Forge V1-B1 already merged; V1-B2 trust/source acquisition and V1-B3 TaskList remain separately gated.
- `nusretm/minecraft_tools`: VersionList `feature/minecraft-loader-version-list-foundation`, PR #57, is a later consumer migration. Its current in-package model definitions are retained until the fixed shared model dependency is ready.
- The VersionList API owns catalog/cache/metadata/selection, not this package.
- CLI future goal: `--loader fabric` resolves a compatible default build, `--loader-ver` selects one exact full build. That selection algorithm is **outside** the shared value models.

## Validation and current checkpoint

- Windows validation passed: `dart pub get`, `dart analyze`, and `dart test` (14 tests).
- Final diff hygiene is checked with `git diff --check`, `git diff --stat`, and `git status`.
- Inspect the complete feature-branch diff before any commit or PR.
- Commit, PR, tag, merge, and consumer migration each remain separately gated.
- After an approved fixed Git SHA/tag exists, migrate VersionList first and MTN Launcher later.

**No commit, PR, tag, merge, or consumer dependency migration is authorized by MOD-1 implementation approval.**
