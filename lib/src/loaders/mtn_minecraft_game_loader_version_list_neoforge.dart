import '../mtn_minecraft_game_version_type.dart';

import '../mtn_minecraft_game_loader_version.dart';
import '../mtn_minecraft_game_loader_version_list.dart';
import 'src/mtn_minecraft_game_loader_version_parsing.dart';

/// NeoForge Maven metadata, including the optional historical 1.20.1 coordinate.
class MtnMinecraftGameLoaderVersionListNeoForge extends MtnMinecraftGameLoaderVersionList {
  MtnMinecraftGameLoaderVersionListNeoForge({required super.cacheDirectory, super.cacheDuration}) : super(loaderName: 'neoforge');

  static const String mavenBase = 'https://maven.neoforged.net/releases/net/neoforged/neoforge';
  static const String legacyMavenBase = 'https://maven.neoforged.net/releases/net/neoforged/forge';

  /// Interpret NeoForge artifact versions only within this provider.
  static String? minecraftVersionFromBuild(String version) {
    final parts = version.split('-').first.split('+').first.split('.');
    if (parts.length < 3 || parts.any((part) => int.tryParse(part) == null)) return null;
    final major = int.parse(parts[0]);
    if (major >= 20 && major <= 25) {
      final patch = int.parse(parts[1]);
      return patch == 0 ? '1.$major' : '1.$major.$patch';
    }
    if (major >= 26 && parts.length >= 4) {
      final patch = int.parse(parts[2]);
      return patch == 0 ? '${parts[0]}.${parts[1]}' : '${parts[0]}.${parts[1]}.$patch';
    }
    return null;
  }

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doLoadFromWeb() async {
    final result = <MtnMinecraftGameLoaderVersion>[];
    final modern = mavenVersions(await downloadUrl('$mavenBase/maven-metadata.xml'));
    for (final version in modern) {
      final game = minecraftVersionFromBuild(version);
      if (game == null) continue;
      final escaped = Uri.encodeComponent(version);
      result.add(MtnMinecraftGameLoaderVersion(
        mcVersion: game,
        version: version,
        url: '$mavenBase/$escaped/neoforge-$escaped-installer.jar',
        type: minecraftTypeFromId(game),
        channel: loaderChannel(version),
      ));
    }

    // Failure of optional legacy metadata must not discard the modern catalog.
    try {
      final legacy = mavenVersions(await downloadUrl('$legacyMavenBase/maven-metadata.xml'));
      for (final version in legacy) {
        if (!version.startsWith('1.20.1-')) continue;
        final escaped = Uri.encodeComponent(version);
        result.add(MtnMinecraftGameLoaderVersion(
          mcVersion: '1.20.1',
          version: version,
          url: '$legacyMavenBase/$escaped/forge-$escaped-installer.jar',
          type: MtnMinecraftGameVersionType.release,
          channel: loaderChannel(version),
        ));
      }
    } catch (_) {
      // Optional legacy metadata cannot invalidate successfully loaded modern builds.
      // downloadUrl() already records network failures on the VersionList.
    }
    sortItems(result);
    return result;
  }

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doGenerateMinecraftVersionList(String mcVersion, List<MtnMinecraftGameVersionType> types) async {
    return items.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
  }
}
