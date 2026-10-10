# Minecraft Models

`minecraft_models` is the shared, pure-Dart source of truth for Minecraft loader identities, version values and version metadata discovery used by MTN Launcher and Minecraft Tools. Shared type identity avoids duplicating enums and provider parsing across projects.

**Current status (2026-10-10):** [PR #7](https://github.com/nusretm/minecraft_models/pull/7) is **merged and Windows-validated**. Verified implementation SHA: `1c4e346ed42bf9f15b0259c8efb2f7d3011758a3`. On merged `main`, `dart analyze` returned no issues, `dart test` passed **40/40**, and live metadata discovery succeeded for all five loaders on Minecraft 1.21.11 and 1.21.1. Feature-branch cleanup was completed; this documentation closure does not change Dart code.

## The public API

Import from the single supported entry point:

```dart
import 'package:minecraft_models/minecraft_models.dart';
```

| Public symbol | Purpose |
| --- | --- |
| `MtnMinecraftLoaderType` | Single loader identity: `vanilla`, `fabric`, `forge`, `neoforge`, `quilt`. Use `values` or `fromName(String?)` (unknown => `null`). |
| `MtnMinecraftGameLoaderVersionList` | **Constructible public facade** for catalogs, Minecraft-compatible loader versions, HTTP, cache and typed errors. |
| `MtnMinecraftGameLoaderVersion` | Immutable data model: `mcVersion`, exact `version`, source `url`, game `type`, loader `channel`; JSON serialization and display-only `text`. |
| `MtnMinecraftGameVersionType` | Type of the Minecraft game version (release, snapshot, preview, etc.). |
| `MtnMinecraftGameLoaderChannel` | Loader build publication channel; `unknown` is **not** stable. |
| `MtnMinecraftError` | Metadata/cache diagnostic (`error`, `errorCode`, `errorMessage` on VersionList). |

There is **one public `MtnMinecraftGameLoaderVersionList`**, not a public VersionList class for each loader. `MtnMinecraftGameLoaderVersionListHelper` and the five provider helper classes live in `lib/src/` and are **not** exported; consumer projects should neither import nor instantiate them. The facade chooses the helper from `loaderType` and owns all HTTP/cache/error state.

## Minimal example

```dart
import 'dart:io';
import 'package:minecraft_models/minecraft_models.dart';

Future<void> main() async {
  final list = MtnMinecraftGameLoaderVersionList(
    cacheDirectory: Directory.systemTemp.path,
    loaderType: MtnMinecraftLoaderType.fabric,
  );

  final builds = await list.getFromMinecraftVersion('1.21.11');
  if (list.error != MtnMinecraftError.none) {
    stderr.writeln('Metadata warning: ${list.errorMessage}');
  }

  for (final build in builds) {
    stdout.writeln('${build.version} — ${build.channel.name} — ${build.url}');
  }
}
```

Use the existing [`example/game_loader_version_lists.dart`](example/game_loader_version_lists.dart) to query **all** `MtnMinecraftLoaderType.values` with one shared code path:

```powershell
dart run example/game_loader_version_lists.dart 1.21.11
dart run example/game_loader_version_lists.dart 1.21.1
```

### Important usage rules

- `load()` retrieves the broad catalog. `getFromMinecraftVersion(mcVersion, [types])` returns matching records; it initializes the catalog when necessary. For **Fabric and Quilt**, broad catalog `items` represent **supported Minecraft game versions**, not actual loader builds. Query a Minecraft version for those.
- `MtnMinecraftGameLoaderVersion.type` is the **Minecraft game release type**; `.channel` is the **loader publication channel**. Neither `channel == unknown` nor `versions.first` guarantees a stable or preferred build.
- `.url` is provider-specific: Mojang version JSON, Fabric/Quilt profile JSON, or Forge/NeoForge Maven installer JAR **candidate**. This package does **not** download/install game artifacts, verify checksums, select a guaranteed newest/stable build, or launch Minecraft.
- `cacheDuration` defaults to one hour. Disk/network failures are best-effort and can return cached data or empty results; **inspect `list.error` after each operation**. Cache paths include `loaderType.name`; `MtnMinecraftLoaderType.fromName` returns `null` for unknown strings, never an implicit Vanilla default.
- Use the exact upstream `version` and `url` when persisting or selecting records. `text` is only for display. The current model has **no SHA-1 field** or `fromRawData()` factory.

## Guide for other repositories

**[Consumer integration guide — MtnLauncher / Minecraft Tools](docs/continuity/CONSUMER_INTEGRATION.md)** provides the pinned Git dependency, full examples, architecture rationale, provider-result distinctions, cache/error behavior and separate consumer migration checklists. Read it **before** replacing duplicate types or upgrading launcher integrations.

**[Current verified architecture and continuity](docs/continuity/CURRENT_TARGET.md)** is the authoritative project state. [Working rules](docs/WORKING_RULES.md) define approval, tests and coding constraints; archived pre-PR #7 continuity is explicitly historical.

Consumer integration is **a separate approved checkpoint**. No changes to `mtn_launcher` or `minecraft_tools` are included here.
