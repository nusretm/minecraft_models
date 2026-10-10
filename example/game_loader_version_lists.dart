import 'dart:io';

import 'package:minecraft_models/minecraft_models.dart';

Future<void> main(List<String> args) async {
  final mcVersion = args.isEmpty ? '1.21.11' : args.first;
  final cacheDirectory = '${Directory.systemTemp.path}${Platform.pathSeparator}mtn_minecraft_game_loader_version_lists';

  for (final loaderType in MtnMinecraftLoaderType.values) {
    final versionList = MtnMinecraftGameLoaderVersionList(cacheDirectory: cacheDirectory, loaderType: loaderType);
    final catalog = await versionList.load();
    final catalogError = versionList.error;
    final catalogErrorMessage = versionList.errorMessage;
    final versions = await versionList.getFromMinecraftVersion(mcVersion);
    stdout.writeln('\n${loaderType.name} — catalog: ${catalog.length} entries | Minecraft: $mcVersion | builds: ${versions.length}');
    if (catalogError != MtnMinecraftError.none) stdout.writeln('  Catalog warning [${catalogError.code}]: $catalogErrorMessage');
    if (versionList.error != MtnMinecraftError.none) stdout.writeln('  Build warning [${versionList.errorCode}]: ${versionList.errorMessage}');
    if (versions.isEmpty) {
      stdout.writeln('  No compatible records (or metadata unavailable).');
      continue;
    }
    stdout.writeln('  Default candidate (first): ${versions.first.version}');
    for (final version in versions.take(3)) {
      stdout.writeln('  [${version.type.name}/${version.channel.name}] ${version.version}');
      stdout.writeln('    ${version.url}');
    }
  }
}
