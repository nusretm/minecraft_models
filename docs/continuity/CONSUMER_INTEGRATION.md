# Consumer integration guide — minecraft_models

**Current as of 2026-10-10.** Authoritative implementation: [PR #7](https://github.com/nusretm/minecraft_models/pull/7), squash-merged as `1c4e346ed42bf9f15b0259c8efb2f7d3011758a3`. Confirmed after the merge on Windows: `dart analyze` clean; `dart test` 40/40; live metadata checks for all five providers on Minecraft 1.21.11 and 1.21.1.

This document is for engineers and coding agents working on **`nusretm/mtn_launcher`**, **`nusretm/minecraft_tools`** or another pure-Dart consumer. Read [CURRENT_TARGET.md](CURRENT_TARGET.md) for the final repository state. Do not follow old callbacks or exported provider APIs from PR #6 or older continuity snapshots.

## Why this package is the single owner

Sharing a type's name across packages does not make those Dart types equal. A duplicated `MtnMinecraftLoaderType`, game-version type, loader channel, or VersionList model forces conversion, permits different semantics, and creates silent drift. `minecraft_models` is the **leaf shared dependency**; `mtn_launcher` and `minecraft_tools` depend on it. This package does **not** import those applications.

```text
mtn_launcher         minecraft_tools         other Dart consumers
      \\                   |                      /
                  minecraft_models
            public VersionList + shared types
                           |
               internal helper dispatch
          Vanilla · Fabric · Forge · NeoForge · Quilt
```

The public VersionList handles catalog lifecycle, metadata HTTP, best-effort cache and typed diagnostics once. Its loader-specific helpers handle upstream wire parsing. Consumers handle UI, build-selection policy, materialization, artifact verification, download orchestration, installation, and game execution.

## 1. Add one fixed dependency

In the **consumer's** `pubspec.yaml`, use an approved fixed Git SHA, not a moving branch:

```yaml
dependencies:
  minecraft_models:
    git:
      url: https://github.com/nusretm/minecraft_models.git
      ref: 1c4e346ed42bf9f15b0259c8efb2f7d3011758a3
```

That SHA is the tested implementation from PR #7. Docs-only closure commits do not modify its Dart implementation. If the consuming repository already depends on another version, audit the migration and resolve to **one** package instance/version. Run `dart pub get` after an approved dependency change.

```dart
import 'package:minecraft_models/minecraft_models.dart';
```

This is the **only supported package-wide public import**. Do not import `package:minecraft_models/src/...`, internal helpers, provider implementation files or cache internals.

## 2. Loader identity and unknown input

The canonical enum is `MtnMinecraftLoaderType`, with **exactly** `vanilla`, `fabric`, `forge`, `neoforge`, `quilt` in the current code.

```dart
final MtnMinecraftLoaderType? loader = MtnMinecraftLoaderType.fromName(' FABRIC ');
if (loader == null) {
  throw ArgumentError('Unknown Minecraft loader');
}
final String storedName = loader.name; // "fabric"
```

`fromName(String?)` trims and compares case-insensitively. Null, blank or unsupported names return **null**, not an implicit Vanilla fallback. Prefer `MtnMinecraftLoaderType.values` for a loader picker instead of a second manually updated loader list. Do not create a competing launcher/tool enum, duplicate records or mapper for the same identity.

## 3. Query one loader or all loaders

**One selected loader**, without manually constructing a provider/helper:

```dart
import 'dart:io';
import 'package:minecraft_models/minecraft_models.dart';

Future<void> checkFabric() async {
  final list = MtnMinecraftGameLoaderVersionList(
    cacheDirectory: Directory.systemTemp.path,
    loaderType: MtnMinecraftLoaderType.fabric,
    cacheDuration: const Duration(hours: 1), // optional; this is the default
  );

  final catalog = await list.load();
  final catalogDiagnostic = (list.error, list.errorMessage);

  final builds = await list.getFromMinecraftVersion(
    '1.21.11',
    [MtnMinecraftGameVersionType.release],
  );
  final buildsDiagnostic = (list.error, list.errorMessage);

  stdout.writeln('Catalog entries: ${catalog.length}, compatible builds: ${builds.length}');
  if (catalogDiagnostic.$1 != MtnMinecraftError.none) stdout.writeln('Catalog warning: ${catalogDiagnostic.$2}');
  if (buildsDiagnostic.$1 != MtnMinecraftError.none) stdout.writeln('Build warning: ${buildsDiagnostic.$2}');
  for (final build in builds) {
    stdout.writeln('${build.version} / ${build.channel.name} / ${build.url}');
  }
}
```

For **all** loader types, reuse the tested `example/game_loader_version_lists.dart` pattern:

```dart
for (final loaderType in MtnMinecraftLoaderType.values) {
  final list = MtnMinecraftGameLoaderVersionList(
    cacheDirectory: cacheDirectory,
    loaderType: loaderType,
  );
  final catalog = await list.load();
  final builds = await list.getFromMinecraftVersion(mcVersion);
  // inspect list.error/list.errorMessage; present catalog and builds separately
}
```

Calling `getFromMinecraftVersion()` first also initializes the broad catalog if its cache is missing. The optional positional list filters **Minecraft game-version types**, not loader stable/beta channels. `list.items` exposes the current broad catalog as read-only data.

## 4. Understand what results mean

| Loader | Broad `load()` catalog | `getFromMinecraftVersion(mcVersion)` records | Source `url` |
| --- | --- | --- | --- |
| Vanilla | Mojang Minecraft versions | Matching game versions, including preview families | Mojang version JSON |
| Fabric | Supported Minecraft game-version index | Compatible Fabric loader builds | Fabric profile JSON |
| Quilt | Supported Minecraft game-version index | Compatible Quilt loader builds | Quilt profile JSON |
| Forge | Forge Maven version catalog | Forge versions matching the Minecraft family | Maven installer JAR candidate |
| NeoForge | NeoForge Maven version catalog (optional legacy source) | NeoForge versions matching the Minecraft family | Maven installer JAR candidate |

**Important:** For Fabric and Quilt, entries from `load()` are **not** the loader build list. Use `getFromMinecraftVersion()` to populate the loader version selector. Source URLs are different kinds of resources; clients must not assume every URL is JSON or that an installer URL is guaranteed to exist for every old build.

`MtnMinecraftGameLoaderVersion` fields:
- `mcVersion`: associated Minecraft family.
- `version`: **exact upstream** build/game identifier; use for selection, requests, and persistence.
- `url`: exact provider-specific metadata or installer source; **not** a verified executable.
- `type: MtnMinecraftGameVersionType`: Minecraft game release/snapshot/pre-release/etc., **not** loader maturity.
- `channel: MtnMinecraftGameLoaderChannel`: loader build stability (can be `unknown`; **unknown ≠ stable**).
- `text`: shortened text for UI display only. Do not substitute it for `version` in downloads or exact selection.
- `toJson()/fromJson()`: shared value serialization. There is **no `fromRawData()`**, no SHA-1 field, and no checksum verification in this model.

**Ordering and default selection are NOT solved by the model.** The catalog respects provider ordering; Forge/NeoForge perform provider-level numeric/natural sorting. Actual Quilt results demonstrated `0.20.0-beta.9`, `0.20.0-beta.7`, `0.20.0-beta.8` in that order. Do not assume `builds.first` means chronologically newest, compatible stable, recommended or installable. Make launcher/tool selection logic explicit and test separately.

## 5. Cache, errors and lifecycle

- Default TTL: one hour. VersionList owns the filesystem cache. Cache files derive from `loaderType.name`, Minecraft version and optional type filters (e.g., `fabric.json`, `fabric-1.21.11.json`). Keep a writable, app-controlled cache directory; avoid treating system temp as durable application state.
- `load()` returns the catalog; `getFromMinecraftVersion()` returns matching results after cache/network resolution. They can **return a result or empty list despite a recoverable failure**. Read `list.error`, `list.errorCode` and `list.errorMessage` **after each operation**; later operations may reset diagnostics.
- `MtnMinecraftError.none.code == 0`; cache error codes are in the 1000 range, download error codes in the 2000 range. An HTTP 404 is represented by a typed download error; the HTTP status appears in `errorMessage`, not `errorCode`.
- A corrupt cache can be retried against upstream; a valid expired cache may be used after refresh failure. A catalog failure should not be persisted as a misleading empty per-version success.
- Do not equate an empty result with provider-confirmed no support without examining the diagnostic. The package is best-effort metadata discovery, **not** installation, checksum trust, a loader runtime or game process orchestration.

## 6. Migration boundaries by repository

### mtn_launcher

- Import `minecraft_models.dart`; reuse **the same** `MtnMinecraftLoaderType`, `MtnMinecraftGameVersionType`, `MtnMinecraftGameLoaderChannel`, `MtnMinecraftGameLoaderVersion` and `MtnMinecraftGameLoaderVersionList`. Audit existing same-purpose definitions first, then remove duplication in a **separate approved migration**.
- Resolve CLI/UI loader names with `MtnMinecraftLoaderType.fromName` (handle null) and show `MtnMinecraftLoaderType.values` in the picker.
- Create a VersionList with `loaderType`. Use `getFromMinecraftVersion()` for compatible build selection; do not directly construct `...VersionListFabric`, `...VersionListForge`, etc., or parse upstream metadata in the launcher.
- Keep manifest loading, installer handling, source validation, TaskList/DownloadList orchestration, Java runtime management, installation, package execution and Rust/FFI concerns **in the launcher**. URLs differ by provider, so interpret/install them in a launcher-specific approved workflow rather than assuming a uniform profile document.
- If a previously named launcher type has additional semantics, document the distinction before replacement rather than doing an unsafe bulk rename.

### minecraft_tools / minecraft_loader_version_list

- Audit the existing package for competing VersionList, cache, loader enum and version model definitions. Remove/replace duplicative identities only after assessing consumer API impact in a **separate approved checkpoint**.
- Prefer the shared `MtnMinecraftGameLoaderVersionList` and shared value/enum types to parallel callback-centric implementations. Do not preserve provider parsing in the consumer just to reproduce the new shared helpers.
- Keep Minecraft-world/server/NBT/discovery responsibilities in the tools repository; do not push them into this common loader models package.

### Both consumers: acceptance checklist

1. Pin a reviewed immutable Git SHA; one canonical package version/type identity in the dependency graph.
2. Ensure the public import compiles without any `src/` imports or callback-provider construction.
3. Confirm null-handling for `fromName`, game `type` versus loader `channel`, and exact `version`/`url` preservation.
4. Validate both a release family and non-release/legacy behavior as relevant, plus cache fallback/typed diagnostics.
5. Run consumer-specific `dart analyze`, tests and at least one live metadata smoke; separately validate real installation or game launch where applicable.
6. Merge and cleanup only with the consumer repository's **separate explicit approval**.

## Proven validation and known limits

User's Windows run on merged `main` at `1c4e346`: `dart pub get` succeeded; `dart analyze` reported no issues; `dart test` **40/40 passed**. Live example:
- Minecraft **1.21.11**: Vanilla 9, Fabric 253, Forge 31, NeoForge 45, Quilt 307 matches.
- Minecraft **1.21.1**: Vanilla 2, Fabric 253, Forge 66, NeoForge 254, Quilt 307 matches.

Both runs completed with source URLs displayed and provider results retrieved. **This proves metadata discovery in that environment, not future API availability, installer artifact existence, default build correctness, download validation or launch success.**

This checkpoint creates **documentation only** and does not migrate, edit or authorize changes in either consumer repository.
