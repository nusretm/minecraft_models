import 'dart:convert';
import 'dart:io';

import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

/// Test-only subclass exercises the shared lifecycle without a real provider.
class _TestVersionList extends MtnMinecraftGameLoaderVersionList {
  _TestVersionList({
    required super.cacheDirectory,
    required super.loaderName,
    required this.onLoadFromWeb,
    required this.onGenerateMinecraftVersionList,
  });

  final Future<List<MtnMinecraftGameLoaderVersion>> Function(MtnMinecraftGameLoaderVersionList list) onLoadFromWeb;
  final Future<List<MtnMinecraftGameLoaderVersion>> Function(MtnMinecraftGameLoaderVersionList list, String mcVersion, List<MtnMinecraftGameVersionType> types) onGenerateMinecraftVersionList;

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doLoadFromWeb() => onLoadFromWeb(this);

  @override
  Future<List<MtnMinecraftGameLoaderVersion>> doGenerateMinecraftVersionList(String mcVersion, List<MtnMinecraftGameVersionType> types) => onGenerateMinecraftVersionList(this, mcVersion, types);
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('mtn_minecraft_version_list_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  const release = MtnMinecraftGameLoaderVersion(
    mcVersion: '1.21.11',
    version: '0.19.5',
    url: 'https://example.invalid/release',
    type: MtnMinecraftGameVersionType.release,
  );
  const snapshot = MtnMinecraftGameLoaderVersion(
    mcVersion: '1.21.11',
    version: '0.19.4',
    url: 'https://example.invalid/snapshot',
    type: MtnMinecraftGameVersionType.snapshot,
  );

  test('creates cache folder and reuses valid data without a second request', () async {
    var calls = 0;
    final list = _TestVersionList(
      cacheDirectory: '${root.path}/cache',
      loaderName: 'fabric',
      onLoadFromWeb: (_) async { calls++; return [release]; },
      onGenerateMinecraftVersionList: (_, __, ___) async => [release],
    );

    expect(await list.load(), [release]);
    expect(await list.load(), [release]);
    expect(calls, 1);
    expect(File('${root.path}/cache/fabric.json').existsSync(), isTrue);
    expect(list.error, MtnMinecraftError.none);
    expect(list.errorCode, MtnMinecraftError.none.code);
    expect(list.errorMessage, '');
  });

  test('invalid fresh cache is replaced from provider data', () async {
    final cache = Directory('${root.path}/cache')..createSync();
    File('${cache.path}/vanilla.json').writeAsStringSync('{invalid JSON');
    var calls = 0;
    final list = _TestVersionList(
      cacheDirectory: cache.path,
      loaderName: 'vanilla',
      onLoadFromWeb: (_) async { calls++; return [release]; },
      onGenerateMinecraftVersionList: (_, __, ___) async => [release],
    );

    expect(await list.load(), [release]);
    expect(calls, 1);
    expect(jsonDecode(File('${cache.path}/vanilla.json').readAsStringSync()), isA<List>());
    expect(list.error, MtnMinecraftError.none);
    expect(list.errorCode, MtnMinecraftError.none.code);
  });

  test('expired valid cache is reused after provider failure with diagnostic', () async {
    final cache = Directory('${root.path}/cache')..createSync();
    final cached = File('${cache.path}/forge.json')..writeAsStringSync(jsonEncode([release.toJson()]));
    cached.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 2)));
    final list = _TestVersionList(
      cacheDirectory: cache.path,
      loaderName: 'forge',
      onLoadFromWeb: (_) async => throw StateError('Offline'),
      onGenerateMinecraftVersionList: (_, __, ___) async => throw StateError('Offline'),
    );

    expect(await list.load(), [release]);
    expect(list.error, MtnMinecraftError.downloadFailed);
    expect(list.errorCode, MtnMinecraftError.downloadFailed.code);
    expect(MtnMinecraftError.isDownloadError(list.error), isTrue);
    expect(list.errorMessage, contains('Offline'));
  });

  test('filters downloaded and cached builds while preserving provider order', () async {
    var calls = 0;
    final list = _TestVersionList(
      cacheDirectory: '${root.path}/cache',
      loaderName: 'fabric',
      onLoadFromWeb: (_) async => [release, snapshot],
      onGenerateMinecraftVersionList: (_, __, ___) async { calls++; return [snapshot, release]; },
    );

    expect(await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.release]), [release]);
    expect(await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.release]), [release]);
    expect(calls, 1);
    expect(await list.getFromMinecraftVersion('1.21.11'), [snapshot, release]);
  });

  test('unwritable cache does not discard successful provider results', () async {
    final parentFile = File('${root.path}/not-a-directory')..writeAsStringSync('occupied');
    final list = _TestVersionList(
      cacheDirectory: parentFile.path,
      loaderName: 'quilt',
      onLoadFromWeb: (_) async => [release],
      onGenerateMinecraftVersionList: (_, __, ___) async => [release],
    );

    expect(await list.load(), [release]);
    expect(list.error, MtnMinecraftError.cacheWriteFailed);
    expect(list.errorCode, MtnMinecraftError.cacheWriteFailed.code);
    expect(MtnMinecraftError.isCacheError(list.error), isTrue);
    expect(list.errorMessage, contains('Cache write error'));
  });

  test('cache filenames do not interpret Minecraft IDs as path separators', () async {
    final list = _TestVersionList(
      cacheDirectory: '${root.path}/cache',
      loaderName: 'fabric',
      onLoadFromWeb: (_) async => [],
      onGenerateMinecraftVersionList: (_, __, ___) async => [],
    );

    expect(await list.getFromMinecraftVersion('../custom'), isEmpty);
    expect(File('${root.path}/cache/fabric-..%2Fcustom.json').existsSync(), isTrue);
  });

  test('HTTP classification retains status in message and success clears the error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/not-found') request.response.statusCode = 404;
      request.response.write('test');
      await request.response.close();
    });
    final list = _TestVersionList(
      cacheDirectory: root.path,
      loaderName: 'vanilla',
      onLoadFromWeb: (_) async => [],
      onGenerateMinecraftVersionList: (_, __, ___) async => [],
    );

    try {
      await expectLater(list.downloadUrl('http://127.0.0.1:${server.port}/not-found'), throwsA(isA<HttpException>()));
      expect(list.error, MtnMinecraftError.downloadHttpFailed);
      expect(list.errorCode, MtnMinecraftError.downloadHttpFailed.code);
      expect(list.errorMessage, contains('HTTP 404'));
      expect(await list.downloadUrl('http://127.0.0.1:${server.port}/ok'), 'test');
      expect(list.error, MtnMinecraftError.none);
      expect(list.errorCode, MtnMinecraftError.none.code);
      expect(list.errorMessage, '');
    } finally {
      await server.close(force: true);
    }
  });

  test('version-specific expired cache fallback keeps only matching types', () async {
    final cache = Directory('${root.path}/cache')..createSync();
    final file = File('${cache.path}/forge-1.21.11-release.json')..writeAsStringSync(jsonEncode([release.toJson(), snapshot.toJson()]));
    file.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 2)));
    final list = _TestVersionList(
      cacheDirectory: cache.path,
      loaderName: 'forge',
      onLoadFromWeb: (_) async => [],
      onGenerateMinecraftVersionList: (_, __, ___) async => throw StateError('Metadata unavailable'),
    );

    expect(await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.release]), [release]);
    expect(list.error, MtnMinecraftError.downloadFailed);
    expect(list.errorCode, MtnMinecraftError.downloadFailed.code);
    expect(MtnMinecraftError.isDownloadError(list.error), isTrue);
  });
  test('forwards requested Minecraft version types to the provider', () async {
    List<MtnMinecraftGameVersionType>? seenTypes;
    final list = _TestVersionList(
      cacheDirectory: '${root.path}/cache',
      loaderName: 'type-filter',
      onLoadFromWeb: (_) async => [],
      onGenerateMinecraftVersionList: (_, game, types) async {
        expect(game, '1.21.11');
        seenTypes = types;
        return [release, snapshot];
      },
    );

    final result = await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.release]);
    expect(seenTypes, [MtnMinecraftGameVersionType.release]);
    expect(result, [release]);
  });

  test('failed catalog refresh does not cache a misleading empty version list', () async {
    final list = _TestVersionList(
      cacheDirectory: root.path,
      loaderName: 'offline',
      onLoadFromWeb: (_) async => throw const SocketException('offline'),
      onGenerateMinecraftVersionList: (_, __, ___) async => [],
    );

    expect(await list.getFromMinecraftVersion('1.21.11'), isEmpty);
    expect(list.error, MtnMinecraftError.downloadFailed);
    expect(File('${root.path}/offline-1.21.11.json').existsSync(), isFalse);
  });
}
