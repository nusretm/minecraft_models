import 'mtn_launcher_game_loader_channel.dart';
import 'mtn_launcher_game_version_type.dart';

/// An immutable loader build for a Minecraft game-version family.
final class MtnLauncherGameLoaderVersion {
  const MtnLauncherGameLoaderVersion({
    required this.mcVersion,
    required this.version,
    required this.url,
    required this.type,
    this.channel = MtnLauncherGameLoaderChannel.unknown,
    this.sha1,
  });

  /// The Minecraft version family associated with this loader build.
  final String mcVersion;

  /// The exact full upstream loader build identifier.
  final String version;

  /// The exact provider-defined source URL.
  ///
  /// Its resource type is intentionally not interpreted by this package.
  final String url;

  /// The Minecraft game version type, not the loader publication channel.
  final MtnLauncherGameVersionType type;

  /// The loader build publication channel.
  final MtnLauncherGameLoaderChannel channel;

  /// Optional SHA-1 of the source bytes at [url] (e.g. a version profile).
  /// Raw source metadata only: no validation of downloaded bytes happens here.
  /// Null means the provider did not declare an SHA-1.
  final String? sha1;

  /// A shortened display value that never replaces [version] as identity.
  String get text {
    final prefix = '$mcVersion-';
    if (version.startsWith(prefix)) return version.substring(prefix.length);

    final suffix = '-$mcVersion';
    if (version.endsWith(suffix)) return version.substring(0, version.length - suffix.length);

    return version;
  }

  /// Serializes every stored field using exact enum names.
  Map<String, Object> toJson() => {
    'mcVersion': mcVersion,
    'version': version,
    'url': url,
    'type': type.name,
    'channel': channel.name,
    if (sha1 != null) 'sha1': sha1!,
  };

  /// Creates a loader build from the package's JSON representation.
  ///
  /// Required strings reject missing, null, non-string, empty, and
  /// whitespace-only values. A missing `channel` maps to [MtnLauncherGameLoaderChannel.unknown]
  /// for records created before the field existed; an explicitly invalid value
  /// is rejected.
  factory MtnLauncherGameLoaderVersion.fromJson(Map<String, Object?> json) {
    final mcVersion = _requiredString(json, 'mcVersion');
    final version = _requiredString(json, 'version');
    final url = _requiredString(json, 'url');
    final typeName = _requiredString(json, 'type');
    final type = _enumByName(typeName, MtnLauncherGameVersionType.values, 'type');

    final MtnLauncherGameLoaderChannel channel;
    if (json.containsKey('channel')) {
      final channelName = _requiredString(json, 'channel');
      channel = _enumByName(channelName, MtnLauncherGameLoaderChannel.values, 'channel');
    } else {
      channel = MtnLauncherGameLoaderChannel.unknown;
    }

    final String? sourceSha1 = json.containsKey('sha1') ? _requiredString(json, 'sha1') : null;

    return MtnLauncherGameLoaderVersion(
      mcVersion: mcVersion,
      version: version,
      url: url,
      type: type,
      channel: channel,
      sha1: sourceSha1,
    );
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('JSON field "$key" must be a non-empty string');
    }
    return value;
  }

  static T _enumByName<T extends Enum>(String name, List<T> values, String key) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('JSON field "$key" has an unknown value: $name');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MtnLauncherGameLoaderVersion &&
            other.mcVersion == mcVersion &&
            other.version == version &&
            other.url == url &&
            other.type == type &&
            other.channel == channel &&
            other.sha1 == sha1;
  }

  @override
  int get hashCode => Object.hash(mcVersion, version, url, type, channel, sha1);

  @override
  String toString() {
    return 'MtnLauncherGameLoaderVersion(mcVersion: $mcVersion, version: $version, url: $url, type: ${type.name}, channel: ${channel.name}, sha1: $sha1)';
  }
}
