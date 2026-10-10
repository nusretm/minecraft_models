# Current Target — minecraft_models

Date: 2026-10-10
Repository: `nusretm/minecraft_models`
Package: `minecraft_models`
**Status: COMPLETE — PR #7 MERGED, WINDOWS VALIDATED, FEATURE BRANCHES CLEANED**
Authoritative implementation commit: `1c4e346ed42bf9f15b0259c8efb2f7d3011758a3` (merged into `main`; later docs-only commits do not change the implementation).
Previous feature milestone: PR #6, `8dcaedbee9c2bb4afadcd9a2e7dbecf98ffd2930`.

## Start here: consumers and future contributors

- [Consumer integration and rationale](CONSUMER_INTEGRATION.md) — the **authoritative guide** for `mtn_launcher`, `minecraft_tools`, and other Dart consumers, including a pinned Git dependency and examples.
- [README](../../README.md) — overview and minimal public usage.
- [Working rules](../WORKING_RULES.md) — development and approval constraints.
- [Archived earlier checkpoint notes](ARCHIVE_PRE_PR7_VALIDATION.md) — historical design/validation state, **not** current API.
- [Historical model foundation design](MODEL_FOUNDATION_DESIGN.md) and [historical LVL-I3A](LVL_I3A_SOURCE_SHA1_METADATA.md) — preserved for context only; do not substitute their older contracts for this file.

## Final public contract

Use **only** `package:minecraft_models/minecraft_models.dart` from consumers. It currently exports:

1. `MtnMinecraftLoaderType` — canonical loader identity: `vanilla`, `fabric`, `forge`, `neoforge`, `quilt`. `fromName(String?)` trims, ignores case, returns null for unsupported input; `.name` is the canonical string.
2. `MtnMinecraftGameVersionType` — classification of the Minecraft **game** version, not loader stability.
3. `MtnMinecraftGameLoaderChannel` — loader build channel (`unknown` is **not** stable).
4. `MtnMinecraftGameLoaderVersion` — immutable provider result: `mcVersion`, exact `version`, source `url`, game `type`, loader `channel`; `text` is display-only; `toJson/fromJson` preserve exact identity.
5. `MtnMinecraftGameLoaderVersionList` — constructible single public catalog API. Required `cacheDirectory` and `loaderType`, optional `cacheDuration` (default one hour); `load()`, `getFromMinecraftVersion(mcVersion, [types])`, read-only `items`, `error`, `errorCode`, `errorMessage`, `downloadUrl()`, and `sortItems()`.
6. `MtnMinecraftError` — typed non-fatal cache and download diagnostics (`none=0`, 1000-range cache, 2000-range download).

`MtnMinecraftGameLoaderVersionList` is **not abstract**. **Do not instantiate or import** `MtnMinecraftGameLoaderVersionListHelper` or `MtnMinecraftGameLoaderVersionListVanilla/Fabric/Forge/NeoForge/Quilt` in consumers. They are implementation details under `lib/src/` and are **not exported** by the package barrel.

`MtnMinecraftGameLoaderVersionList` owns HTTP, best-effort disk cache, errors and result lifecycle. A lazy, single per-instance internal helper is selected with an exhaustive switch over `MtnMinecraftLoaderType`. Each helper implements `doLoadFromWeb()` and `doGenerateMinecraftVersionList()` and retains a reference to the owner; it does not own an independent HTTP client/cache/error state. Loader-specific metadata parsing and Maven naming stay inside the helpers. No `fromRawData()` model factory and no public provider callbacks.

### Canonical usage

```dart
import 'dart:io';
import 'package:minecraft_models/minecraft_models.dart';

Future<void> example() async {
  final versions = MtnMinecraftGameLoaderVersionList(
    cacheDirectory: Directory.systemTemp.path,
    loaderType: MtnMinecraftLoaderType.fabric,
  );

  final compatible = await versions.getFromMinecraftVersion('1.21.11');
  if (versions.error != MtnMinecraftError.none) {
    stderr.writeln('Metadata warning ${versions.errorCode}: ${versions.errorMessage}');
  }
  for (final build in compatible) {
    stdout.writeln('${build.mcVersion}: ${build.version} (${build.channel.name}) ${build.url}');
  }
}
```

The complete all-loaders CLI is [`example/game_loader_version_lists.dart`](../../example/game_loader_version_lists.dart). It iterates `MtnMinecraftLoaderType.values` rather than maintaining a second registry.

## Behavior that consumers must preserve

- `load()` returns the broad upstream catalog. `getFromMinecraftVersion()` returns compatible records for a requested Minecraft family and optional `MtnMinecraftGameVersionType` filter; on an uncached first query it loads the general catalog as necessary.
- For **Fabric/Quilt**, `items` from `load()` are *supported Minecraft game-version index entries*, **not loader build versions**. Their actual loader builds come from `getFromMinecraftVersion(mcVersion)`. Vanilla/Forge/NeoForge use their catalog to identify compatible records.
- `MtnMinecraftGameLoaderVersion.url` is a **provider-specific metadata or artifact source**, not a uniform downloadable JSON: Vanilla -> Mojang version manifest JSON; Fabric/Quilt -> profile JSON for a selected build; Forge/NeoForge -> Maven installer JAR candidates. This does **not** install, validate checksums, or launch Minecraft.
- The package preserves provider ordering on discovery results. **Do not universally interpret `versions.first` as the newest/stable/preferred build.** Quilt source output for 1.21.11 was `0.20.0-beta.9`, then `beta.7`, then `beta.8`. Selection policy, stability preference and exact requested build belong to the consumer.
- `type` describes the **Minecraft release class**, not loader stability. `channel` describes loader publication status; `unknown` must not be silently treated as `stable`.
- Default cache TTL is one hour; cache paths use `loaderType.name` (e.g., `fabric.json`, `fabric-1.21.11.json`; type-filtered cache names include type suffixes). Disk/metadata failures are best-effort; a valid expired cache can be returned after refresh failure. Check `error` after each operation and distinguish empty data from a confirmed absence.
- `version` and `url` are exact upstream identities. `text` is only a display convenience. The shared model has **no SHA-1 field** and the package performs no binary/source verification.

## Validation — confirmed on Windows AFTER PR #7

User executed against merged `main` at `1c4e346` on 2026-10-10:

- `dart pub get`: successful.
- `dart analyze`: **No issues found**.
- `dart test`: **40/40 passed**.
- `dart run example/game_loader_version_lists.dart 1.21.11`: compatible records: Vanilla **9**, Fabric **253**, Forge **31**, NeoForge **45**, Quilt **307**.
- `dart run example/game_loader_version_lists.dart 1.21.1`: compatible records: Vanilla **2**, Fabric **253**, Forge **66**, NeoForge **254**, Quilt **307**.
- Feature branch `refactor/version-list-internal-loader-helpers`: **remote deleted, local deleted**; `git fetch --prune` completed. `main` and `origin/main` synchronized, working tree clean; `git log -1 --oneline` confirmed `1c4e346`.

These are real live **metadata lookup** results at the time of testing, **not** guarantee of future availability, upstream artifact existence, successful installation or game execution. No post-PR #7 production implementation changes are included in the docs-only closure.

## Next consumer checkpoints — separately approved

- `nusretm/mtn_launcher`: audit and replace duplicate loader identity/version-list usage with the **one** shared dependency and public `MtnMinecraftGameLoaderVersionList`; preserve launcher-specific manifest assembly, tasks, download manager, runtime and process execution. No launcher changes are part of this repository checkpoint.
- `nusretm/minecraft_tools`: audit `minecraft_loader_version_list` / existing model definitions for duplicate types and provider logic before migrating. Do not retain competing canonical enums or callback-centric VersionList APIs. Migration scope must be approved independently.
- Pin consumers to a **fixed commit SHA** (`1c4e346ed42bf9f15b0259c8efb2f7d3011758a3` is the validated implementation baseline), not `main` or a deleted feature branch. Resolve conflicts and re-run each consumer's analyzer/tests and live validation in its own repo.
- Loader ordering/default preference, especially Quilt, and artifact installation/trust remain future independent decisions.

**No feature work, consumer migration, compatibility layer, release or merge approval is implied by this docs-only continuity closure.** Its only purpose is to make the already-merged, validated implementation unambiguous.
