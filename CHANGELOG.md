## Unreleased — Typed Minecraft error codes
- Add `MtnMinecraftError` with grouped cache/download codes, `fromIndex/fromCode` and group checks.
- Replace VersionList's numeric setter with typed diagnostics; retain `errorCode`, `errorMessage` and separate HTTP status.
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
