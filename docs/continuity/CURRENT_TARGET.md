# Current Target — minecraft_models

Date: 2026-10-09
Repository: `nusretm/minecraft_models`
Dart package: `minecraft_models`
Accepted `main` HEAD at MOD-1 merge: `51aad868649d4c147f5a4645e2c92111a6cae44e`
Merged implementation commit: `82f577466534c70d9a07da89877a415f73c5416d` (PR #2)
Status: **MOD-1 COMPLETE / MERGED — consumer migration pending**

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

`MtnLauncherGameVersion` comparison model remains deferred for separate review; no changes to release ordering semantics or launcher runtime in MOD-1.

## Related repositories and checkpoints

- `nusretm/mtn_launcher`: Forge V1-B1 already merged; V1-B2 trust/source acquisition and V1-B3 TaskList remain separately gated.
- `nusretm/minecraft_tools`: VersionList `feature/minecraft-loader-version-list-foundation`, draft PR #57, is the next separately approved consumer migration. Its current in-package model definitions stay unchanged until that work starts. Pin shared models to Git SHA `51aad868649d4c147f5a4645e2c92111a6cae44e`.
- The VersionList API owns catalog/cache/metadata/selection, not this package.
- CLI future goal: `--loader fabric` resolves a compatible default build, `--loader-ver` selects one exact full build. That selection algorithm is **outside** the shared value models.

## Validation and current checkpoint

- User reported Windows `dart pub get` PASS, `dart analyze` **No issues found**, `dart test` **14/14 PASS**, and Git diff checks clean; no independent GitHub CI run is claimed.
- The full twelve-file PR #2 diff was reviewed; public barrel, immutable model, missing-vs-invalid channel, exact IDs/URLs, display-only text, equality and tests matched approved contracts.
- PR #2 merged into `main` on 2026-10-09 at commit `51aad868649d4c147f5a4645e2c92111a6cae44e`. This commit is the fixed dependency ref; no Git tag was created.
- MOD-1 code implementation is complete. Remaining work: separately approve VersionList migration in `minecraft_tools` and then MTN Launcher integration.
- This docs-only closing checkpoint does not implement or authorize changes in any consumer repository.
