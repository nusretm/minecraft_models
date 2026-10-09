# LVL-I3A — Shared loader build source SHA-1 metadata

Date: 2026-10-10
Repository: `nusretm/minecraft_models`
Baseline main: `6791f0b4ea36f7e7053084d6e96bfa52b0369918`
State: **Windows validation PASSED on 2026-10-10; feature commit `10d7c02b4a3edc69d3f6f685b1e8384ade38a225` pushed and PR #5 opened; squash merge requires separate user approval.**

## Evidence and scope

MtnLauncher Vanilla's Mojang catalog carries an optional SHA-1 for the exact profile URL in each version entry. Before LVL-I3A, the shared `MtnLauncherGameLoaderVersion` stored source `url` but could not carry SHA-1 through JSON or the VersionList disk cache. Provider-specific side tables would duplicate metadata ownership.

Approved LVL-I3A adds exactly one optional value field to the existing shared loader build model:

```dart
final String? sha1;
```

- `sha1` describes the SHA-1 declared for the bytes returned by the model's exact `url`. It is metadata, not verified integrity or a promise about retrieval.
- Keep the public `const MtnLauncherGameLoaderVersion(...)` constructor; add optional `this.sha1`, defaulting to null. No new model type, dependencies or aliases.
- Preserve exact source string, URL and SHA-1 text, without trimming/case-normalizing accepted JSON values or computing a checksum.
- `toJson()` includes `sha1` **only when non-null**, retaining byte-for-byte-equivalent field structure for previously SHA-less entries.
- `fromJson()` treats missing `sha1` as null. An explicit null, wrong type, empty or whitespace-only field throws `FormatException` so corrupted present metadata is not silently discarded.
- Structural equality, `hashCode` and string representation include the optional SHA-1.
- Existing `mcVersion`, `version`, `url`, `type`, `channel`, unknown-channel handling and `text` remain unchanged.

## Boundary to downstream work

`minecraft_loader_version_list` serializes generated build items with `item.toJson()` and restores them using `MtnLauncherGameLoaderVersion.fromJson(...)`. Its current schema 1 can therefore transport this optional field after it is re-pinned to a validated new model commit. This checkpoint does **not** modify or verify the consumer package; test its on-disk cache round-trip in a separate bounded consumer update.

Vanilla VersionList migration is further complicated by a separate structural issue: `MtnLauncherGameLoaderMinecraftVersion` only records `(mcVersion, versionId, type)`, not the Mojang profile URL or SHA-1. LVL-I3B must design how provider callbacks reconstruct/preserve these data from the catalog without a second mutable selection authority. LVL-I3A does not solve that callback lifetime/state boundary.

No changes to MtnLauncher's Vanilla source, exact target manifest loading, Package flow, or Forge V1 installation. The SHA-1 model field is not a digest-verification engine. Additional checksum algorithms, alternate acceptable digests and catalog record expansion require separately justified changes.

## Validation gate

On a Windows checkout of the prepared files:

```powershell
dart pub get
dart analyze
dart test test/source_sha1_metadata_test.dart
dart test
git diff --check
git diff --stat
git status
```

Expected focused coverage: const model, exact metadata round-trip, historical absent SHA-1, malformed present values, equality/hash and no source-byte verification. Review actual changes separately from test success; never run `dart format` for pure Dart.

## Actual Windows validation (2026-10-10)

- `dart pub get`: passed.
- `dart analyze`: no issues.
- Focused SHA-1 metadata tests: 7/7 passed.
- Full regression: 21/21 passed.
- `git diff --check`: passed.
- Initial analyzer warning `equal_elements_in_set` corrected.
- Structural equality now tests distinct model instances.
- No `dart format` executed.
- Commit and push: complete (`10d7c02b4a3edc69d3f6f685b1e8384ade38a225`).
- Pull request: [#5](https://github.com/nusretm/minecraft_models/pull/5), open; GitHub diff reviewed (6 files, +232/-11, mergeable/clean).
- Squash merge: **not authorized yet**; separate approval required.

## Stop condition

Windows validation and independent diff audit are complete. Await explicit squash-merge approval for PR #5. The VersionList consumer dependency update remains a separate checkpoint after this models change is merged.
