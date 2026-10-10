import 'dart:convert';
import 'dart:io';

import '../minecraft_models.dart';
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

  String get filename {
    var res = "";
    if(mcVersion != null && mcVersion!.trim().isNotEmpty) {
      res += "-$mcVersion";
      if(types != null && types!.isNotEmpty) {
        types!.forEach((t) => res += "-${t.name}");
      }
    }
    return "${versionList.cacheDirectory}/${versionList.loaderName}$res.json";
  }

  bool get available {
    var cacheFile = File(filename);
    if (cacheFile.existsSync()) {
      var fileLM = cacheFile.lastModifiedSync();
      return versionList.cacheDuration >= DateTime.now().difference(fileLM);
      }
    return cacheFile.existsSync();
  }

  void clear() {
    if(available) {
      try {
        File(filename).deleteSync();
      } catch(_) {}
    }
  }

  void save(List<MtnMinecraftGameLoaderVersion> list) {
    var cacheFile = File(filename);
    try {
      final List<Map<String, dynamic>> jsonList = list.map((item) => item.toJson()).toList();
      cacheFile.writeAsStringSync(jsonEncode(jsonList));
    } catch(_) {}
  }

  List<MtnMinecraftGameLoaderVersion>? load() {
    if(available) {
      try {
        List<MtnMinecraftGameLoaderVersion> res = [];
        var cacheData = jsonDecode(File(filename).readAsStringSync());
        for(var cacheItem in cacheData) {
          res.add(
            MtnMinecraftGameLoaderVersion.fromJson(cacheItem),
          );
        }
        return res;
      } catch(_) {
        clear();
      }
    }
    return null;
  }
}
