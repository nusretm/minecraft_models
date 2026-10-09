# Current Target — minecraft_models

Date: 2026-10-09
Repository: `nusretm/minecraft_models`
Proposed Dart package: `minecraft_models`
Baseline `main` HEAD: `5d7c1be0bc0e57dcb07d7cbc49ac258eab787a2a`
Docs branch: `docs/minecraft-models-foundation`
Status: **DOC-0 / documentation foundation only — model code NOT started**

## Authoritative files

- `README.md` — user-authored initial project overview; preserve existing content.
- `docs/WORKING_RULES.md` — authoritative working and architecture standard.
- `docs/continuity/MODEL_FOUNDATION_DESIGN.md` — model scope and consumer migration boundaries.
- This file — current checkpoint/status/handoff.

## Project objective

Provide one pure-Dart model identity for the independent `mtn_launcher` and `minecraft_loader_version_list` packages. No duplicate `MtnLauncherGameVersionType` or conversion/alias bridge. No HTTP, caching, provider-specific parsing, UI, or game launch in this package.

## Proposed initial contracts — NOT IMPLEMENTED

1. `MtnLauncherGameVersionType` — existing eight-value Minecraft game-version enum.
2. `MtnLauncherGameLoaderMinecraftVersion` — named record `(mcVersion, versionId, type)` preserving exact upstream ID.
3. `MtnLauncherGameLoaderChannel` — `stable, beta, alpha, experimental, unknown` for loader build channel.
4. `MtnLauncherGameLoaderVersion` — exact version, Minecraft game version, provider-defined URL, game version type and loader channel; immutable JSON-capable value.

`MtnLauncherGameVersion` comparison model is deferred for separate review; no changes to release ordering semantics or launcher runtime in DOC-0.

## Related repositories and checkpoints

- `nusretm/mtn_launcher`: Forge V1-B1 already merged; V1-B2 trust/source acquisition and V1-B3 TaskList remain separately gated.
- `nusretm/minecraft_tools`: VersionList `feature/minecraft-loader-version-list-foundation`, PR #57, is a later consumer migration. Its current in-package model definitions are retained until the fixed shared model dependency is ready.
- The VersionList API owns catalog/cache/metadata/selection, not this package.
- CLI future goal: `--loader fabric` resolves a compatible default build, `--loader-ver` selects one exact full build. That selection algorithm is **outside** the shared value models.

## Next steps — require user approval

- Approve four model contracts and validation requirements.
- Create minimal pure-Dart `pubspec.yaml`, `lib/`, `test/`, `.gitignore`, `CHANGELOG.md`.
- User Windows validation: `dart pub get`, `dart analyze`, `dart test`; inspect `git diff --check` and actual changed files.
- Upon separate merge authorization record a fixed Git SHA/tag for consumers.
- Migrate VersionList first, then integrate MTN Launcher after another approval.

**No production implementation, tests, dependency migrations, tag or merge is claimed in DOC-0.**
