import 'dart:convert';

import '../mtn_minecraft_game_loader_version.dart';
import '../mtn_minecraft_game_loader_version_list.dart';
import 'src/mtn_minecraft_game_loader_version_parsing.dart';

/// Fabric Meta API (game catalog and compatible loader builds).
class MtnMinecraftGameLoaderVersionListFabric extends MtnMinecraftGameLoaderVersionList {
  MtnMinecraftGameLoaderVersionListFabric({required super.cacheDirectory, super.cacheDuration}) : super(loaderName: 'fabric');

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doLoadFromWeb() async {
    final entries = jsonDecode(await downloadUrl('https://meta.fabricmc.net/v2/versions/game')) as List<dynamic>;
    return entries.map((raw) {
      final item = raw as Map<String, dynamic>;
      final id = item['version'] as String;
      return MtnMinecraftGameLoaderVersion(
        mcVersion: minecraftVersionFamily(id),
        version: id, // Supported game-version ID, not a Fabric loader build.
        url: 'https://meta.fabricmc.net/v2/versions/loader/${Uri.encodeComponent(id)}',
        type: minecraftTypeFromId(id, stable: item['stable'] as bool?),
      );
    }).toList();
  }

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doGenerateMinecraftVersionList(String mcVersion, List<MtnMinecraftGameVersionType> types) async {
    final gameType = minecraftTypeFromId(mcVersion);
    if (types.isNotEmpty && !types.contains(gameType)) return [];
    final base = 'https://meta.fabricmc.net/v2/versions/loader/${Uri.encodeComponent(mcVersion)}';
    final entries = jsonDecode(await downloadUrl(base)) as List<dynamic>;
    return entries.map((raw) {
      final loader = (raw as Map<String, dynamic>)['loader'] as Map<String, dynamic>;
      final version = loader['version'] as String;
      return MtnMinecraftGameLoaderVersion(
        mcVersion: mcVersion,
        version: version,
        url: '$base/${Uri.encodeComponent(version)}/profile/json',
        type: gameType,
        channel: loaderChannel(version, stable: loader['stable'] as bool?),
      );
    }).toList();
  }
}
