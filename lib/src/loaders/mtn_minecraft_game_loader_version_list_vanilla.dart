import 'dart:convert';

import '../mtn_minecraft_game_loader_version.dart';
import '../mtn_minecraft_game_loader_version_list.dart';
import 'src/mtn_minecraft_game_loader_version_parsing.dart';

/// Mojang's canonical game-version manifest catalog.
class MtnMinecraftGameLoaderVersionListVanilla extends MtnMinecraftGameLoaderVersionList {
  MtnMinecraftGameLoaderVersionListVanilla({required super.cacheDirectory, super.cacheDuration}) : super(loaderName: 'vanilla');

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doLoadFromWeb() async {
    final raw = jsonDecode(await downloadUrl('https://piston-meta.mojang.com/mc/game/version_manifest_v2.json')) as Map<String, dynamic>;
    return (raw['versions'] as List<dynamic>).map((entry) {
      final item = entry as Map<String, dynamic>;
      final id = item['id'] as String;
      return MtnMinecraftGameLoaderVersion(
        mcVersion: minecraftVersionFamily(id),
        version: id,
        url: item['url'] as String,
        type: minecraftTypeFromId(id, manifestType: item['type'] as String?),
      );
    }).toList();
  }

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doGenerateMinecraftVersionList(String mcVersion, List<MtnMinecraftGameVersionType> types) async {
    return items.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
  }
}
