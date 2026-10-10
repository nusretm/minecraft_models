import 'mtn_minecraft_game_loader_channel.dart';
import 'mtn_minecraft_game_version_type.dart';

/// An immutable loader build for a Minecraft game-version family.
final class MtnMinecraftGameLoaderVersion {
  const MtnMinecraftGameLoaderVersion({
    required this.mcVersion,
    required this.version,
    required this.url,
    required this.type,
    this.channel = MtnMinecraftGameLoaderChannel.unknown,
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
  final MtnMinecraftGameVersionType type;

  /// The loader build publication channel.
  final MtnMinecraftGameLoaderChannel channel;

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
  };

  factory MtnMinecraftGameLoaderVersion.fromJson(Map<String, Object?> json) {
    final mcVersion = _requiredString(json, 'mcVersion');
    final version = _requiredString(json, 'version');
    final url = _requiredString(json, 'url');
    final typeName = _requiredString(json, 'type');
    final type = _enumByName(typeName, MtnMinecraftGameVersionType.values, 'type');

    final MtnMinecraftGameLoaderChannel channel;
    if (json.containsKey('channel')) {
      final channelName = _requiredString(json, 'channel');
      channel = _enumByName(channelName, MtnMinecraftGameLoaderChannel.values, 'channel');
    } else {
      channel = MtnMinecraftGameLoaderChannel.unknown;
    }

    return MtnMinecraftGameLoaderVersion(
      mcVersion: mcVersion,
      version: version,
      url: url,
      type: type,
      channel: channel,
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
        other is MtnMinecraftGameLoaderVersion &&
            other.mcVersion == mcVersion &&
            other.version == version &&
            other.url == url &&
            other.type == type &&
            other.channel == channel;
  }

  @override
  int get hashCode => Object.hash(mcVersion, version, url, type, channel);

  @override
  String toString() {
    return 'MtnMinecraftGameLoaderVersion(mcVersion: $mcVersion, version: $version, url: $url, type: ${type.name}, channel: ${channel.name})';
  }
}
