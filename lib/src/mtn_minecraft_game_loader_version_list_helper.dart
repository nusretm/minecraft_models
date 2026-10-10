import 'mtn_minecraft_game_loader_version.dart';
import 'mtn_minecraft_game_loader_version_list.dart';
import 'mtn_minecraft_game_version_type.dart';

/// Internal provider contract; catalog lifecycle and diagnostics stay in VersionList.
abstract class MtnMinecraftGameLoaderVersionListHelper {
  MtnMinecraftGameLoaderVersionListHelper(this.versionList);

  final MtnMinecraftGameLoaderVersionList versionList;

  Future<List<MtnMinecraftGameLoaderVersion>> doLoadFromWeb();

  Future<List<MtnMinecraftGameLoaderVersion>> doGenerateMinecraftVersionList(String mcVersion, List<MtnMinecraftGameVersionType> types);
}
