import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'mtn_minecraft_game_loader_version.dart';
import 'mtn_minecraft_game_loader_version_list_cache.dart';
import 'mtn_minecraft_game_version_type.dart';

/// Shared cache and HTTP handling. Loader-specific parsing stays in onLoadFromWeb.
class MtnMinecraftGameLoaderVersionList {
  MtnMinecraftGameLoaderVersionList({
    required this.cacheDirectory,
    required this.loaderName,
    required this.onLoadFromWeb,
    required this.onGenerateMinecraftVersionList,
    this.cacheDuration = const Duration(hours: 1),
  });

  final String cacheDirectory;
  final String loaderName;
  final Future<List<MtnMinecraftGameLoaderVersion>> Function(MtnMinecraftGameLoaderVersionList list) onLoadFromWeb;
  final Future<List<MtnMinecraftGameLoaderVersion>> Function(MtnMinecraftGameLoaderVersionList list, String mcVersion) onGenerateMinecraftVersionList;
  final Duration cacheDuration;

  List<MtnMinecraftGameLoaderVersion> _items = [];
  List<MtnMinecraftGameLoaderVersion> get items => UnmodifiableListView(_items);

  int _errorCode = 0;
  String _errorMessage = '';
  int get errorCode => _errorCode;
  String get errorMessage => _errorMessage;

  void _setError(int code, [String message='']) {
    _errorCode = code;
    _errorMessage = message;
  }

  /// HTTP requests are performed here so all loaders share error reporting.
  /// Errors are recorded and thrown: the caller's callback needs no try/catch.
  Future<String> downloadUrl(String url) async {
    Uri uri;
    try {
      uri = Uri.parse(url);
      if (uri.scheme != 'https' && uri.scheme != 'http') throw FormatException('Unsupported URL scheme: ${uri.scheme}');
    } catch (error) {
      _setError(1, 'Invalid URL: $error');
      rethrow;
    }

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'MTNMinecraft-VersionList/1.0',
        'Accept': 'application/json, application/xml, text/xml, */*',
      }).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        _setError(response.statusCode, 'HTTP ${response.statusCode}: $uri');
        throw HttpException(errorMessage, uri: uri);
      }
      final result = utf8.decode(response.bodyBytes);
      _setError(0, '');
      return result;
    } on HttpException {
      rethrow;
    } on TimeoutException catch (error) {
      _setError(2, 'Request timed out: $uri ($error)');
      rethrow;
    } on SocketException catch (error) {
      _setError(error.osError?.errorCode ?? 3, 'Network error: $uri ($error)');
      rethrow;
    } on http.ClientException catch (error) {
      _setError(4, 'HTTP client error: $uri ($error)');
      rethrow;
    } catch (error) {
      _setError(5, 'Download failed: $uri ($error)');
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
      _setError(0, '');
      return cached.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
    }

    _setError(0, '');
    try {
      final loaded = await onGenerateMinecraftVersionList(this, mcVersion);
      final result = loaded.where((item) => item.mcVersion == mcVersion && (types.isEmpty || types.contains(item.type))).toList();
      cacheFile.save(result);
      if (cacheFile.errorMessage != null) _setError(-1, cacheFile.errorMessage!);
      return result;
    } catch (error) {
      if (_errorCode == 0) _setError(-2, 'Loader version discovery failed: $error');
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
      _setError(0, '');
      return _items;
    }

    _setError(0, '');
    try {
      _items = await onLoadFromWeb(this);
      cacheFile.save(_items);
      if (cacheFile.errorMessage != null) _setError(-1, cacheFile.errorMessage!);
    } catch (error) {
      if (_errorCode == 0) _setError(-2, 'Loader catalog refresh failed: $error');
      if (_items.isEmpty) _items = cacheFile.load(includeExpired: true) ?? _items;
    }
    return _items;
  }
}
