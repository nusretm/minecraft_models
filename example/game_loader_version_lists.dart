import 'dart:convert';
import 'dart:io';

import 'package:minecraft_models/minecraft_models.dart';

/// Provider-specific interpretation belongs to the example, never VersionList.
MtnMinecraftGameVersionType minecraftTypeFromId(String id, {String? manifestType, bool? stable}) {
  final name = id.toLowerCase();
  if (name.contains('experimental')) return MtnMinecraftGameVersionType.experimental;
  if (RegExp(r'(?:-pre-?\d+|[ -]pre-release[ -]?\d+)$').hasMatch(name)) return MtnMinecraftGameVersionType.preRelease;
  if (RegExp(r'(?:-rc-?\d+|[ -]release candidate[ -]?\d+)$').hasMatch(name)) return MtnMinecraftGameVersionType.releaseCandidate;
  if (manifestType == 'old_alpha' || RegExp(r'^a\d').hasMatch(name)) return MtnMinecraftGameVersionType.alpha;
  if (manifestType == 'old_beta' || RegExp(r'^b\d').hasMatch(name)) return MtnMinecraftGameVersionType.beta;
  if (manifestType == 'snapshot' || RegExp(r'^\d{2}w\d{2}[a-z]$').hasMatch(name) || name.contains('-snapshot-')) return MtnMinecraftGameVersionType.snapshot;
  if (manifestType == 'release' || stable == true || RegExp(r'^\d+\.\d+(?:\.\d+)?$').hasMatch(name)) return MtnMinecraftGameVersionType.release;
  return MtnMinecraftGameVersionType.unknown;
}

/// Group explicit pre/rc identifiers; do not guess the target of week-numbered snapshots.
String minecraftVersionFamily(String id) {
  final preview = RegExp(r'^(\d+\.\d+(?:\.\d+)?)-(?:pre|rc)-?\d+$', caseSensitive: false).firstMatch(id);
  if (preview != null) return preview.group(1)!;
  final snapshot = RegExp(r'^(\d+\.\d+(?:\.\d+)?)-snapshot-\d+$').firstMatch(id);
  return snapshot?.group(1) ?? id;
}

MtnMinecraftGameLoaderChannel loaderChannel(String version, {bool? stable}) {
  if (stable == true) return MtnMinecraftGameLoaderChannel.stable;
  final id = version.toLowerCase();
  if (RegExp(r'(?:^|[.+_-])experimental\d*(?=$|[.+_-])').hasMatch(id)) return MtnMinecraftGameLoaderChannel.experimental;
  if (RegExp(r'(?:^|[.+_-])alpha\d*(?=$|[.+_-])').hasMatch(id)) return MtnMinecraftGameLoaderChannel.alpha;
  if (RegExp(r'(?:^|[.+_-])beta\d*(?=$|[.+_-])').hasMatch(id)) return MtnMinecraftGameLoaderChannel.beta;
  return MtnMinecraftGameLoaderChannel.unknown;
}

List<String> mavenVersions(String xml) {
  final values = RegExp(r'<version>\s*([^<]+?)\s*</version>').allMatches(xml).map((match) => match.group(1)!.trim()).where((value) => value.isNotEmpty).toList();
  if (values.isEmpty) throw const FormatException('Maven metadata has no published versions.');
  return values;
}

/// Mapping of net.neoforged:neoforge build versions; snapshots need provider-specific handling.
String? neoForgeMinecraftVersion(String version) {
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

Future<void> main(List<String> args) async {
  final mcVersion = args.isEmpty ? '1.21.11' : args.first;
  final cacheDirectory = '${Directory.systemTemp.path}${Platform.pathSeparator}mtn_minecraft_game_loader_version_lists';

  // Vanilla: Mojang's catalog already contains exact game-version manifest URLs.
  var versionListVanilla = MtnMinecraftGameLoaderVersionList(
    cacheDirectory: cacheDirectory,
    loaderName: 'vanilla',
    onLoadFromWeb: (list) async {
      final raw = jsonDecode(await list.downloadUrl('https://piston-meta.mojang.com/mc/game/version_manifest_v2.json')) as Map<String, dynamic>;
      return (raw['versions'] as List<dynamic>).map((rawVersion) {
        final item = rawVersion as Map<String, dynamic>;
        final id = item['id'] as String;
        return MtnMinecraftGameLoaderVersion(
          mcVersion: minecraftVersionFamily(id),
          version: id,
          url: item['url'] as String,
          type: minecraftTypeFromId(id, manifestType: item['type'] as String?),
        );
      }).toList();
    },
    onGenerateMinecraftVersionList: (list, mcVersion, types) async {
      return list.items.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
    },
  );

  // Fabric: the game endpoint is a Minecraft-support index; actual loader builds
  // and profile manifest URLs are fetched only for the requested Minecraft version.
  var versionListFabric = MtnMinecraftGameLoaderVersionList(
    cacheDirectory: cacheDirectory,
    loaderName: 'fabric',
    onLoadFromWeb: (list) async {
      final entries = jsonDecode(await list.downloadUrl('https://meta.fabricmc.net/v2/versions/game')) as List<dynamic>;
      return entries.map((raw) {
        final item = raw as Map<String, dynamic>;
        final id = item['version'] as String;
        return MtnMinecraftGameLoaderVersion(
          mcVersion: minecraftVersionFamily(id),
          version: id, // Game index ID, not a Fabric loader build.
          url: 'https://meta.fabricmc.net/v2/versions/loader/${Uri.encodeComponent(id)}',
          type: minecraftTypeFromId(id, stable: item['stable'] as bool?),
        );
      }).toList();
    },
    onGenerateMinecraftVersionList: (list, mcVersion, types) async {
      final gameType = minecraftTypeFromId(mcVersion);
      if (types.isNotEmpty && !types.contains(gameType)) return [];
      final base = 'https://meta.fabricmc.net/v2/versions/loader/${Uri.encodeComponent(mcVersion)}';
      final entries = jsonDecode(await list.downloadUrl(base)) as List<dynamic>;
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
    },
  );

  // Quilt has the same two-step discovery pattern, with its own API schema.
  var versionListQuilt = MtnMinecraftGameLoaderVersionList(
    cacheDirectory: cacheDirectory,
    loaderName: 'quilt',
    onLoadFromWeb: (list) async {
      final entries = jsonDecode(await list.downloadUrl('https://meta.quiltmc.org/v3/versions/game')) as List<dynamic>;
      return entries.map((raw) {
        final item = raw as Map<String, dynamic>;
        final id = item['version'] as String;
        return MtnMinecraftGameLoaderVersion(
          mcVersion: minecraftVersionFamily(id),
          version: id, // Game index ID; the real Quilt builds come from the second callback.
          url: 'https://meta.quiltmc.org/v3/versions/loader/${Uri.encodeComponent(id)}',
          type: minecraftTypeFromId(id, stable: item['stable'] as bool?),
        );
      }).toList();
    },
    onGenerateMinecraftVersionList: (list, mcVersion, types) async {
      final gameType = minecraftTypeFromId(mcVersion);
      if (types.isNotEmpty && !types.contains(gameType)) return [];
      final base = 'https://meta.quiltmc.org/v3/versions/loader/${Uri.encodeComponent(mcVersion)}';
      final entries = jsonDecode(await list.downloadUrl(base)) as List<dynamic>;
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
    },
  );

  // Forge: Maven exposes published builds. The source URL is an installer JAR,
  // NOT a JSON version manifest; processing it is the Forge provider's job.
  const forgeBase = 'https://maven.minecraftforge.net/net/minecraftforge/forge';
  var versionListForge = MtnMinecraftGameLoaderVersionList(
    cacheDirectory: cacheDirectory,
    loaderName: 'forge',
    onLoadFromWeb: (list) async {
      final versions = mavenVersions(await list.downloadUrl('$forgeBase/maven-metadata.xml'));
      final result = <MtnMinecraftGameLoaderVersion>[];
      for (final version in versions) {
        final match = RegExp(r'^(\d+(?:\.\d+){1,2})-').firstMatch(version);
        if (match == null) continue;
        final game = match.group(1)!;
        final escaped = Uri.encodeComponent(version);
        result.add(MtnMinecraftGameLoaderVersion(
          mcVersion: game,
          version: version,
          url: '$forgeBase/$escaped/forge-$escaped-installer.jar',
          type: minecraftTypeFromId(game),
          channel: loaderChannel(version),
        ));
      }
      list.sortItems(result);
      return result;
    },
    onGenerateMinecraftVersionList: (list, mcVersion, types) async {
      return list.items.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
    },
  );

  // NeoForge: modern net.neoforged:neoforge plus the historical 1.20.1
  // net.neoforged:forge coordinates. These URLs are installer JARs.
  const neoBase = 'https://maven.neoforged.net/releases/net/neoforged/neoforge';
  const neoLegacyBase = 'https://maven.neoforged.net/releases/net/neoforged/forge';
  var versionListNeoForge = MtnMinecraftGameLoaderVersionList(
    cacheDirectory: cacheDirectory,
    loaderName: 'neoforge',
    onLoadFromWeb: (list) async {
      final result = <MtnMinecraftGameLoaderVersion>[];
      final modern = mavenVersions(await list.downloadUrl('$neoBase/maven-metadata.xml'));
      for (final version in modern) {
        final game = neoForgeMinecraftVersion(version);
        if (game == null) continue; // Unknown schemes must not be guessed.
        final escaped = Uri.encodeComponent(version);
        result.add(MtnMinecraftGameLoaderVersion(
          mcVersion: game,
          version: version,
          url: '$neoBase/$escaped/neoforge-$escaped-installer.jar',
          type: minecraftTypeFromId(game),
          channel: loaderChannel(version),
        ));
      }
      // Historical 1.20.1 releases use another Maven artifact coordinate.
      final legacy = mavenVersions(await list.downloadUrl('$neoLegacyBase/maven-metadata.xml'));
      for (final version in legacy) {
        if (!version.startsWith('1.20.1-')) continue;
        final escaped = Uri.encodeComponent(version);
        result.add(MtnMinecraftGameLoaderVersion(
          mcVersion: '1.20.1',
          version: version,
          url: '$neoLegacyBase/$escaped/forge-$escaped-installer.jar',
          type: MtnMinecraftGameVersionType.release,
          channel: loaderChannel(version),
        ));
      }
      list.sortItems(result);
      return result;
    },
    onGenerateMinecraftVersionList: (list, mcVersion, types) async {
      return list.items.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
    },
  );

  for (final (label, versionList) in <(String, MtnMinecraftGameLoaderVersionList)>[
    ('Vanilla', versionListVanilla),
    ('Fabric', versionListFabric),
    ('Quilt', versionListQuilt),
    ('Forge', versionListForge),
    ('NeoForge', versionListNeoForge),
  ]) {
    final catalog = await versionList.load();
    final versions = await versionList.getFromMinecraftVersion(mcVersion);
    stdout.writeln('\n$label — catalog: ${catalog.length} entries | Minecraft: $mcVersion | builds: ${versions.length}');
    if (versionList.error != MtnMinecraftError.none) stdout.writeln('  Warning [${versionList.errorCode}]: ${versionList.errorMessage}');
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
