import '../mtn_minecraft_game_version_type.dart';
import '../mtn_minecraft_loader_type.dart';

import '../mtn_minecraft_game_loader_version.dart';
import '../mtn_minecraft_game_loader_version_list.dart';
import 'src/mtn_minecraft_game_loader_version_parsing.dart';

/// Forge Maven metadata. Version URLs are installer JAR candidates, not JSON.
class MtnMinecraftGameLoaderVersionListForge extends MtnMinecraftGameLoaderVersionList {
  MtnMinecraftGameLoaderVersionListForge({required super.cacheDirectory, super.cacheDuration}) : super(loaderType: MtnMinecraftLoaderType.forge);

  static const String mavenBase = 'https://maven.minecraftforge.net/net/minecraftforge/forge';

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doLoadFromWeb() async {
    final versions = mavenVersions(await downloadUrl('$mavenBase/maven-metadata.xml'));
    final result = <MtnMinecraftGameLoaderVersion>[];
    for (final version in versions) {
      final match = RegExp(r'^(\d+(?:\.\d+){1,2})-').firstMatch(version);
      if (match == null) continue;
      final game = match.group(1)!;
      final escaped = Uri.encodeComponent(version);
      result.add(MtnMinecraftGameLoaderVersion(
        mcVersion: game,
        version: version,
        url: '$mavenBase/$escaped/forge-$escaped-installer.jar',
        type: minecraftTypeFromId(game),
        channel: loaderChannel(version),
      ));
    }
    sortItems(result);
    return result;
  }

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doGenerateMinecraftVersionList(String mcVersion, List<MtnMinecraftGameVersionType> types) async {
    return items.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
  }
}
