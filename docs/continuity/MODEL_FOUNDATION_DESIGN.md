# Shared Minecraft Models — Foundation Design

Date: 2026-10-09
Status: **MOD-1 contract approved and implemented on feature branch; review pending**
Repository: `nusretm/minecraft_models`
Consumers: `nusretm/mtn_launcher`, `nusretm/minecraft_tools/minecraft_loader_version_list`

## Why an independent package?

The same Minecraft game version type is currently defined by both consumers. Equal enum names/cases in two packages are still distinct Dart types. A shared models package makes the *type identity itself* common. Renaming one enum and adding `fromLoaderVersionType` would hide duplicate semantics rather than solve the problem.

Architecture: `minecraft_models` is a leaf dependency used by both consumers. The VersionList may additionally be depended on by Launcher. The models package must never import Launcher or VersionList.

## Four foundation models

### MtnLauncherGameVersionType

Keep the exact existing cases, unchanged:

```dart
enum MtnLauncherGameVersionType {
  release,
  snapshot,
  preRelease,
  releaseCandidate,
  beta,
  alpha,
  experimental,
  unknown,
}
```

This denotes the *Minecraft game's* version type, **not** loader stability.

### MtnLauncherGameLoaderMinecraftVersion

Keep the current named-record type from VersionList:

```dart
typedef MtnLauncherGameLoaderMinecraftVersion = ({
  String mcVersion,
  String versionId,
  MtnLauncherGameVersionType type,
});
```

`mcVersion` groups logically selected game versions; `versionId` is the exact original upstream ID. Do not claim a week-numbered snapshot belongs to a particular release without authoritative mapping.

### MtnLauncherGameLoaderChannel

New enum for *loader build* channel:

```dart
enum MtnLauncherGameLoaderChannel {
  stable,
  beta,
  alpha,
  experimental,
  unknown,
}
```

An upstream source without channel metadata yields `unknown`, not `stable`. Provider-specific classification and latest/preferred selection logic stay outside this package.

### MtnLauncherGameLoaderVersion

The shared immutable loader build model retains:
- `String mcVersion`
- `String version`: full upstream loader build identifier, never a shortened display label
- `String url`: preserved provider-defined source URL; potentially manifest JSON, profile JSON, or installer JAR
- `MtnLauncherGameVersionType type`: Minecraft game-version type
- New `MtnLauncherGameLoaderChannel channel`: loader build channel, explicit default `unknown`
- `text`: derived display convenience only; never use it as download/version identity
- `toJson` / `fromJson`: preserve exact identity, URL, type and channel through round-trips
- structural equality and `hashCode` over all five stored fields

`fromJson` requires non-empty, non-whitespace `mcVersion`, `version`, `url`, and
`type` strings. Missing, null, wrong-type, empty, whitespace-only, and unknown
enum values throw `FormatException`. `channel` is the sole missing-field
exception: absence maps to `unknown`, while an explicit null, wrong type, empty,
whitespace-only, or unknown value throws. Extra JSON fields are ignored and
`toJson` always writes `channel`.

The accepted strings are returned unchanged; validation does not trim, change
case, parse, shorten, or reconstruct upstream values. `text` removes at most one
exact `"$mcVersion-"` prefix or, otherwise, one exact `"-$mcVersion"` suffix.
It never changes `version` itself.

## Dart package layout

```text
README.md
docs/WORKING_RULES.md
docs/continuity/CURRENT_TARGET.md
docs/continuity/MODEL_FOUNDATION_DESIGN.md
pubspec.yaml
lib/minecraft_models.dart
lib/src/mtn_launcher_game_version_type.dart
lib/src/mtn_launcher_game_loader_minecraft_version.dart
lib/src/mtn_launcher_game_loader_channel.dart
lib/src/mtn_launcher_game_loader_version.dart
test/minecraft_models_test.dart
CHANGELOG.md
.gitignore
```

Suggested Dart SDK `>=3.5.0 <4.0.0` and first development version `0.1.0-dev.1`. No HTTP, filesystem, or Flutter dependency.

## Deliberately excluded

- `MtnLauncherGameVersion` comparison model: consider independently later; current launcher comparator has narrower release ordering behavior and broad dependencies.
- `MtnLauncherGameLoaderVersionList`, cache status, HTTP, source parsing, version sorting, compatibility, exact/default selection, stable-preference policy, URL downloading, installer acquisition.
- Generic account/mod/world/item models until concrete shared domain need exists.
- Compatibility copies, alias classes or enum conversion bridges.
- Any modification to `minecraft_tools` or `mtn_launcher` in this repository's foundation checkpoint.

## Test and release acceptance

- Enum sets preserve cases; game version type and loader channel remain semantically distinct.
- Named record keeps exact `mcVersion` and `versionId`.
- Build model JSON round-trips exact full version and URL; channel and game-type fields are independent.
- Malformed/missing payload rules are consistent; immutable value cannot be mutated.
- Structural equality includes all stored fields, while `text` remains derived display data.
- Verify Windows `dart pub get`, `dart analyze`, `dart test`, and `git diff --check`.
- User approves implementation and later PR merge separately. Pin a fixed Git commit/tag in VersionList, then migrate Launcher in another checkpoint.

VersionList PR #57 and its five-provider examples are **not** declared ready or tested by this documentation change.
