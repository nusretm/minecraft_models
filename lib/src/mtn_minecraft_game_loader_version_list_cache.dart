import 'dart:convert';
import 'dart:io';

import 'mtn_minecraft_error.dart';
import 'mtn_minecraft_game_loader_version.dart';
import 'mtn_minecraft_game_version_type.dart';
import 'mtn_minecraft_game_loader_version_list.dart';

// buradaki try catch kullanımının sebebi: cache yüzünden kod hata vermemeli.
class MtnMinecraftGameLoaderVersionListCache {
  MtnMinecraftGameLoaderVersionListCache({
    required this.versionList,
    this.mcVersion,
    this.types,
  });

  final MtnMinecraftGameLoaderVersionList versionList;
  String? mcVersion;
  List<MtnMinecraftGameVersionType>? types;

  /// Non-fatal filesystem diagnostic for this cache operation.
  MtnMinecraftError _error = MtnMinecraftError.none;
  MtnMinecraftError get error => _error;
  int get errorCode => _error.code;
  String? errorMessage;

  String get filename {
    var res = "";
    if (mcVersion != null && mcVersion!.trim().isNotEmpty) {
      res += "-${Uri.encodeComponent(mcVersion!)}";
      if (types != null && types!.isNotEmpty) {
        for (final type in types!) res += "-${type.name}";
      }
    }
    return "${versionList.cacheDirectory}/${Uri.encodeComponent(versionList.loaderName)}$res.json";
  }

  bool get available {
    try {
      final cacheFile = File(filename);
      return cacheFile.existsSync() && DateTime.now().difference(cacheFile.lastModifiedSync()) <= versionList.cacheDuration;
    } catch (error) {
      _error = MtnMinecraftError.cacheMetadataFailed;
      errorMessage = 'Cache metadata error: $error';
      return false;
    }
  }

  void clear() {
    try {
      final cacheFile = File(filename);
      if (cacheFile.existsSync()) cacheFile.deleteSync();
    } catch (error) {
      _error = MtnMinecraftError.cacheDeleteFailed;
      errorMessage = 'Cache cleanup error: $error';
    }
  }

  void save(List<MtnMinecraftGameLoaderVersion> list) {
    try {
      Directory(versionList.cacheDirectory).createSync(recursive: true);
      final jsonList = list.map((item) => item.toJson()).toList();
      File(filename).writeAsStringSync(jsonEncode(jsonList));
      _error = MtnMinecraftError.none;
      errorMessage = null;
    } catch (error) {
      _error = MtnMinecraftError.cacheWriteFailed;
      errorMessage = 'Cache write error: $error';
    }
  }

  List<MtnMinecraftGameLoaderVersion>? load({bool includeExpired = false}) {
    if (!includeExpired && !available) return null;

    try {
      final cacheFile = File(filename);
      if (!cacheFile.existsSync()) return null;
      final raw = jsonDecode(cacheFile.readAsStringSync());
      if (raw is! List<dynamic>) throw const FormatException('Cache root must be a JSON list');
      final result = <MtnMinecraftGameLoaderVersion>[];
      for (final item in raw) {
        result.add(MtnMinecraftGameLoaderVersion.fromJson(Map<String, Object?>.from(item as Map)));
      }
      _error = MtnMinecraftError.none;
      errorMessage = null;
      return result;
    } catch (error) {
      clear();
      if (_error != MtnMinecraftError.cacheDeleteFailed) {
        _error = MtnMinecraftError.cacheReadFailed;
        errorMessage = 'Cache read error: $error';
      }
      return null;
    }
  }
}
