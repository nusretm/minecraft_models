import 'mtn_launcher_game_version_type.dart';

/// A Minecraft version supported by a loader.
///
/// [versionId] is the exact upstream Minecraft version identifier. [mcVersion]
/// is the version family exposed to consumers and is not inferred from it.
typedef MtnLauncherGameLoaderMinecraftVersion = ({
  String mcVersion,
  String versionId,
  MtnLauncherGameVersionType type,
});
