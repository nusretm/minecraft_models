## Unreleased — Documentation / consumer integration handoff (2026-10-10)
- Close PR #7 continuity with the actual merge SHA `1c4e346`, successful post-merge Windows `dart analyze`, 40 passing tests, live Vanilla/Fabric/Forge/NeoForge/Quilt metadata results on 1.21.11 and 1.21.1, and completed feature-branch cleanup.
- Publish `docs/continuity/CONSUMER_INTEGRATION.md` explaining the single public VersionList API, typed loader identity, pinned Git dependency, provider URL differences, cache/error contracts and separate MtnLauncher/Minecraft Tools migrations.
- Move stale in-progress checkpoint notes to a labeled historical archive; refresh README and working rules to keep consumers on the current API. Documentation-only: no Dart source/behavior changes.

## Unreleased — Internal loader helpers and single public VersionList
- Make `MtnMinecraftGameLoaderVersionList` constructible: callers provide `cacheDirectory` and `loaderType`.
- Add internal abstract `MtnMinecraftGameLoaderVersionListHelper` with `versionList` ownership reference and two provider override hooks.
- Convert five loader implementations to internal helper subclasses, selected lazily by the public VersionList.
- Stop barrel-exporting the helper and five provider classes. Keep `MtnMinecraftGameLoaderVersion` as the unchanged public value model.
- Preserve central cache/HTTP/error lifecycle and existing filenames. Adapt example and offline provider/lifecycle fixtures to public dispatch.
- Simplify the live example to iterate `MtnMinecraftLoaderType.values` rather than manually declaring or listing the five loader variants.

## Unreleased — Canonical Minecraft loader type
- Export `MtnMinecraftLoaderType` (vanilla, fabric, forge, neoforge, quilt) from `minecraft_models.dart` for shared launcher use.
- Add a case-insensitive, whitespace-tolerant `fromName(String?)`; unknown values return null, not Vanilla.
- Replace public `VersionList.loaderName` with typed `loaderType` in the base and all five providers; cache filenames continue using `loaderType.name`.
- Update tests for enum round-tripping, safe unknown names, typed provider identities, and existing cache behavior.

## Unreleased — Concrete Minecraft loader VersionList providers
- Convert the existing `MtnMinecraftGameLoaderVersionList` into the abstract shared cache/HTTP lifecycle base without renaming it.
- Replace public loading callbacks with provider overrides `doLoadFromWeb()` and `doGenerateMinecraftVersionList(mcVersion, types)`.
- Add built-in Vanilla, Fabric, Quilt, Forge and NeoForge VersionList subclasses under `lib/src/loaders/`; constructors accept `cacheDirectory` and fix their own `loaderName`.
- Move upstream wire-format parsing out of the example; keep `MtnMinecraftGameLoaderVersion` as a value model, without adding `fromRawData()`.
- Ensure direct version lookup initializes the catalog and does not cache a false empty list after catalog failure.
- Add fixture-backed offline provider tests and retain the validated best-effort cache / typed-error contracts.

## Unreleased — Five-loader upstream metadata example
- Add a single `main()` creating Vanilla, Fabric, Quilt, Forge and NeoForge `MtnMinecraftGameLoaderVersionList` instances using their published metadata endpoints.
- Forward `types` into the provider's `onGenerateMinecraftVersionList(list, mcVersion, types)` callback.
- Add offline example parsing checks for Minecraft release types, Maven metadata, NeoForge version-family mapping and publication channels.

## Unreleased — Typed Minecraft error codes
- Add `MtnMinecraftError` with grouped cache/download codes, `fromIndex/fromCode` and group checks.
- Use `_setError(MtnMinecraftError, [message])` to centralize typed error updates; keep `errorCode` and `errorMessage`, remove separate HTTP status.
- Keep recoverable cache/download errors non-fatal and preserve existing loader/version class names.

## Unreleased — Generic VersionList resilience
- Keep existing `MtnMinecraftGameLoaderVersionList` and cache classes; non-fatal cache/network handling, valid-stale fallback, Minecraft type filtering and HTTP/cache diagnostics.
- Expose the generic VersionList through the package public API without implementing artifact downloads or launcher orchestration.

## Historical LVL-I3A source SHA-1 metadata (superseded by subsequent model renaming)
- Add optional source-byte SHA-1 to the immutable loader version value model while preserving const construction, exact URL identity and existing JSON output when absent.
- Persist optional SHA-1 in JSON and structural equality; reject malformed explicitly supplied JSON metadata.
- No HTTP or checksum verification in the shared models layer.

# Changelog

## 0.1.0-dev.1

- Add the shared Minecraft game-version type.
- Add the loader Minecraft-version record, loader channel, and immutable loader build model.
- Define deterministic JSON serialization for loader builds.
