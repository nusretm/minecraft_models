import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;

import 'mtn_minecraft_error.dart';
import 'mtn_minecraft_game_loader_version.dart';
import 'mtn_minecraft_game_loader_version_list_cache.dart';
import 'mtn_minecraft_game_version_type.dart';
import 'mtn_minecraft_loader_type.dart';
import 'mtn_minecraft_game_loader_version_list_helper.dart';
import 'loaders/mtn_minecraft_game_loader_version_list_vanilla.dart';
import 'loaders/mtn_minecraft_game_loader_version_list_fabric.dart';
import 'loaders/mtn_minecraft_game_loader_version_list_forge.dart';
import 'loaders/mtn_minecraft_game_loader_version_list_neoforge.dart';
import 'loaders/mtn_minecraft_game_loader_version_list_quilt.dart';

/// Public Minecraft loader catalog. Provider interpretation is delegated to an internal helper.
class MtnMinecraftGameLoaderVersionList {
  MtnMinecraftGameLoaderVersionList({
    required this.cacheDirectory,
    required this.loaderType,
    this.cacheDuration = const Duration(hours: 1),
  });

  final String cacheDirectory;
  final MtnMinecraftLoaderType loaderType;
  final Duration cacheDuration;

  // One provider helper per VersionList instance; created only when first needed.
  late final MtnMinecraftGameLoaderVersionListHelper _helper = switch (loaderType) {
    MtnMinecraftLoaderType.vanilla => MtnMinecraftGameLoaderVersionListVanilla(this),
    MtnMinecraftLoaderType.fabric => MtnMinecraftGameLoaderVersionListFabric(this),
    MtnMinecraftLoaderType.forge => MtnMinecraftGameLoaderVersionListForge(this),
    MtnMinecraftLoaderType.neoforge => MtnMinecraftGameLoaderVersionListNeoForge(this),
    MtnMinecraftLoaderType.quilt => MtnMinecraftGameLoaderVersionListQuilt(this),
  };

  List<MtnMinecraftGameLoaderVersion> _items = [];
  List<MtnMinecraftGameLoaderVersion> get items => UnmodifiableListView(_items);

  MtnMinecraftGameLoaderVersion? getFromVersionStr(String version) =>
      _items.firstWhereOrNull((item) => item.version == version);

  MtnMinecraftError _error = MtnMinecraftError.none;
  String _errorMessage = '';

  MtnMinecraftError get error => _error;
  int get errorCode => _error.code;
  String get errorMessage => _errorMessage;

  void _setError(MtnMinecraftError error, [String message='']) {
    _error = error;
    _errorMessage = message;
  }

  /// HTTP requests are performed here so all loaders share error reporting.
  /// Errors are recorded and thrown: the caller's callback needs no try/catch.
  Future<String> downloadUrl(String url) async {
    _setError(MtnMinecraftError.none);

    Uri uri;
    try {
      uri = Uri.parse(url);
      if (uri.scheme != 'https' && uri.scheme != 'http') throw FormatException('Unsupported URL scheme: ${uri.scheme}');
    } catch (error) {
      _setError(MtnMinecraftError.downloadInvalidUrl, 'Invalid URL: $error');
      rethrow;
    }

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'MTNMinecraft-VersionList/1.0',
        'Accept': 'application/json, application/xml, text/xml, */*',
      }).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        _setError(MtnMinecraftError.downloadHttpFailed, 'HTTP ${response.statusCode}: $uri');
        throw HttpException(errorMessage, uri: uri);
      }
      final result = utf8.decode(response.bodyBytes);
      _setError(MtnMinecraftError.none);
      return result;
    } on HttpException {
      rethrow;
    } on TimeoutException catch (error) {
      _setError(MtnMinecraftError.downloadTimeout, 'Request timed out: $uri ($error)');
      rethrow;
    } on SocketException catch (error) {
      _setError(MtnMinecraftError.downloadNetworkFailed, 'Network error: $uri ($error)');
      rethrow;
    } on http.ClientException catch (error) {
      _setError(MtnMinecraftError.downloadClientFailed, 'HTTP client error: $uri ($error)');
      rethrow;
    } catch (error) {
      _setError(MtnMinecraftError.downloadFailed, 'Download failed: $uri ($error)');
      rethrow;
    }
  }

  void sortItems(List<MtnMinecraftGameLoaderVersion> versions) {
    versions.sort((a, b) {
      final minecraftOrder = _compareNatural(b.mcVersion, a.mcVersion);
      if (minecraftOrder != 0) return minecraftOrder;
      return _compareNatural(b.text, a.text);
    });
  }

  int _compareNatural(String a, String b) {
    final aParts = RegExp(r'\d+|\D+').allMatches(a).map((match) => match.group(0)!).toList();
    final bParts = RegExp(r'\d+|\D+').allMatches(b).map((match) => match.group(0)!).toList();

    for (int i = 0; i < aParts.length && i < bParts.length; i++) {
      final left = aParts[i];
      final right = bParts[i];
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      final difference = leftNumber != null && rightNumber != null
          ? leftNumber.compareTo(rightNumber)
          : left.toLowerCase().compareTo(right.toLowerCase());
      if (difference != 0) return difference;
    }

    if (aParts.length == bParts.length) return 0;
    if (aParts.length < bParts.length) {
      final suffix = bParts[aParts.length];
      return suffix.startsWith('-') || suffix.startsWith('+') ? 1 : -1;
    }
    final suffix = aParts[bParts.length];
    return suffix.startsWith('-') || suffix.startsWith('+') ? -1 : 1;
  }

  /// Returns compatible builds without altering the provider's newest-first order.
  Future<List<MtnMinecraftGameLoaderVersion>> getFromMinecraftVersion(String mcVersion, [List<MtnMinecraftGameVersionType> types = const []]) async {
    final cacheFile = MtnMinecraftGameLoaderVersionListCache(versionList: this, mcVersion: mcVersion, types: types);
    final cached = cacheFile.load();
    if (cached != null) {
      _setError(MtnMinecraftError.none);
      return cached.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
    }

    _setError(MtnMinecraftError.none);
    try {
      if (_items.isEmpty) await load();
      final catalogError = _error;
      final catalogErrorMessage = _errorMessage;
      final loaded = await _helper.doGenerateMinecraftVersionList(mcVersion, types);
      // A failed catalog refresh is not a legitimate empty version list.
      // Keep it retryable instead of persisting a misleading empty cache file.
      if (_items.isEmpty && catalogError != MtnMinecraftError.none && loaded.isEmpty) {
        if (_error == MtnMinecraftError.none) _setError(catalogError, catalogErrorMessage);
        return [];
      }
      final result = loaded.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
      cacheFile.save(result);
      if (cacheFile.error != MtnMinecraftError.none) {
        _setError(cacheFile.error, cacheFile.errorMessage ?? '');
      }
      return result;
    } catch (error) {
      if (_error == MtnMinecraftError.none) {
        _setError(MtnMinecraftError.downloadFailed, 'Loader version discovery failed: $error');
      }
      final stale = cacheFile.load(includeExpired: true);
      if (stale != null) return stale.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
      return [];
    }
  }

  /// Loads the complete provider index and retains usable data after refresh errors.
  Future<List<MtnMinecraftGameLoaderVersion>> load() async {
    final cacheFile = MtnMinecraftGameLoaderVersionListCache(versionList: this);
    final cached = cacheFile.load();
    if (cached != null) {
      _items = cached;
      _setError(MtnMinecraftError.none);
      return _items;
    }

    _setError(MtnMinecraftError.none);
    try {
      _items = await _helper.doLoadFromWeb();
      cacheFile.save(_items);
      if (cacheFile.error != MtnMinecraftError.none) {
        _setError(cacheFile.error, cacheFile.errorMessage ?? '');
      }
    } catch (error) {
      if (_error == MtnMinecraftError.none) {
        _setError(MtnMinecraftError.downloadFailed, 'Loader catalog refresh failed: $error');
      }
      if (_items.isEmpty) _items = cacheFile.load(includeExpired: true) ?? _items;
    }
    return _items;
  }
}
