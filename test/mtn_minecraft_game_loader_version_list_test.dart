import 'dart:convert';
import 'dart:io';

import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

/// Inject HTTP metadata only at the public VersionList boundary.
class _FixtureVersionList extends MtnMinecraftGameLoaderVersionList {
  _FixtureVersionList({
    required super.cacheDirectory,
    required super.loaderType,
    required this.onDownload,
  });

  final Future<String> Function(String url) onDownload;
  int calls = 0;

  @override
  Future<String> downloadUrl(String url) async {
    calls++;
    return onDownload(url);
  }
}

String _mojangCatalog(List<Map<String, String>> entries) => jsonEncode({'versions': entries});

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
    version: '1.21.11',
    url: 'https://example.invalid/release',
    type: MtnMinecraftGameVersionType.release,
  );
  const snapshot = MtnMinecraftGameLoaderVersion(
    mcVersion: '1.21.11',
    version: '1.21.11-snapshot-2',
    url: 'https://example.invalid/snapshot',
    type: MtnMinecraftGameVersionType.snapshot,
  );

  final catalog = _mojangCatalog([
    {'id': release.version, 'type': 'release', 'url': release.url},
    {'id': snapshot.version, 'type': 'snapshot', 'url': snapshot.url},
  ]);

  test('creates cache folder and reuses valid data without a second request', () async {
    final list = _FixtureVersionList(
      cacheDirectory: '${root.path}/cache',
      loaderType: MtnMinecraftLoaderType.vanilla,
      onDownload: (_) async => catalog,
    );

    expect(await list.load(), [release, snapshot]);
    expect(await list.load(), [release, snapshot]);
    expect(list.calls, 1);
    expect(File('${root.path}/cache/vanilla.json').existsSync(), isTrue);
    expect(list.error, MtnMinecraftError.none);
    expect(list.errorCode, MtnMinecraftError.none.code);
    expect(list.errorMessage, '');
  });

  test('invalid fresh cache is replaced from provider data', () async {
    final cache = Directory('${root.path}/cache')..createSync();
    File('${cache.path}/vanilla.json').writeAsStringSync('{invalid JSON');
    final list = _FixtureVersionList(
      cacheDirectory: cache.path,
      loaderType: MtnMinecraftLoaderType.vanilla,
      onDownload: (_) async => catalog,
    );

    expect(await list.load(), [release, snapshot]);
    expect(list.calls, 1);
    expect(jsonDecode(File('${cache.path}/vanilla.json').readAsStringSync()), isA<List>());
    expect(list.error, MtnMinecraftError.none);
  });

  test('expired valid cache is reused after provider failure with diagnostic', () async {
    final cache = Directory('${root.path}/cache')..createSync();
    final cached = File('${cache.path}/forge.json')..writeAsStringSync(jsonEncode([release.toJson()]));
    cached.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 2)));
    final list = _FixtureVersionList(
      cacheDirectory: cache.path,
      loaderType: MtnMinecraftLoaderType.forge,
      onDownload: (_) async => throw StateError('Offline'),
    );

    expect(await list.load(), [release]);
    expect(list.error, MtnMinecraftError.downloadFailed);
    expect(list.errorCode, MtnMinecraftError.downloadFailed.code);
    expect(MtnMinecraftError.isDownloadError(list.error), isTrue);
    expect(list.errorMessage, contains('Offline'));
  });

  test('filters downloaded and cached builds while preserving provider order', () async {
    final list = _FixtureVersionList(
      cacheDirectory: '${root.path}/cache',
      loaderType: MtnMinecraftLoaderType.vanilla,
      onDownload: (_) async => _mojangCatalog([
        {'id': snapshot.version, 'type': 'snapshot', 'url': snapshot.url},
        {'id': release.version, 'type': 'release', 'url': release.url},
      ]),
    );

    expect(await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.release]), [release]);
    expect(await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.release]), [release]);
    expect(list.calls, 1);
    expect(await list.getFromMinecraftVersion('1.21.11'), [snapshot, release]);
  });

  test('unwritable cache does not discard successful provider results', () async {
    final parentFile = File('${root.path}/not-a-directory')..writeAsStringSync('occupied');
    final list = _FixtureVersionList(
      cacheDirectory: parentFile.path,
      loaderType: MtnMinecraftLoaderType.vanilla,
      onDownload: (_) async => catalog,
    );

    expect(await list.load(), [release, snapshot]);
    expect(list.error, MtnMinecraftError.cacheWriteFailed);
    expect(list.errorCode, MtnMinecraftError.cacheWriteFailed.code);
    expect(MtnMinecraftError.isCacheError(list.error), isTrue);
    expect(list.errorMessage, contains('Cache write error'));
  });

  test('cache filenames do not interpret Minecraft IDs as path separators', () async {
    final list = _FixtureVersionList(
      cacheDirectory: '${root.path}/cache',
      loaderType: MtnMinecraftLoaderType.vanilla,
      onDownload: (_) async => catalog,
    );

    expect(await list.getFromMinecraftVersion('../custom'), isEmpty);
    expect(File('${root.path}/cache/vanilla-..%2Fcustom.json').existsSync(), isTrue);
  });

  test('HTTP classification retains status in message and success clears the error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/not-found') request.response.statusCode = 404;
      request.response.write('test');
      await request.response.close();
    });
    final list = MtnMinecraftGameLoaderVersionList(
      cacheDirectory: root.path,
      loaderType: MtnMinecraftLoaderType.vanilla,
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
    final file = File('${cache.path}/fabric-1.21.11-release.json')..writeAsStringSync(jsonEncode([release.toJson(), snapshot.toJson()]));
    file.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 2)));
    final list = _FixtureVersionList(
      cacheDirectory: cache.path,
      loaderType: MtnMinecraftLoaderType.fabric,
      onDownload: (url) async {
        if (url.endsWith('/versions/game')) return '[{"version":"1.21.11","stable":true}]';
        throw StateError('Metadata unavailable');
      },
    );

    expect(await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.release]), [release]);
    expect(list.error, MtnMinecraftError.downloadFailed);
    expect(list.errorCode, MtnMinecraftError.downloadFailed.code);
    expect(MtnMinecraftError.isDownloadError(list.error), isTrue);
  });

  test('requested Minecraft types determine whether provider fetch is needed', () async {
    final requested = <String>[];
    final list = _FixtureVersionList(
      cacheDirectory: '${root.path}/cache',
      loaderType: MtnMinecraftLoaderType.fabric,
      onDownload: (url) async {
        requested.add(url);
        if (url.endsWith('/versions/game')) return '[{"version":"1.21.11","stable":true}]';
        if (url.endsWith('/versions/loader/1.21.11')) return '[{"loader":{"version":"0.19.5","stable":true}}]';
        throw StateError('Unexpected Fabric URL: $url');
      },
    );

    expect(await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.snapshot]), isEmpty);
    expect(requested.where((url) => url.endsWith('/versions/loader/1.21.11')), isEmpty);
    final versions = await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.release]);
    expect(versions, hasLength(1));
    expect(versions.single.version, '0.19.5');
    expect(requested.where((url) => url.endsWith('/versions/loader/1.21.11')), hasLength(1));
  });

  test('failed catalog refresh does not cache a misleading empty version list', () async {
    final list = _FixtureVersionList(
      cacheDirectory: root.path,
      loaderType: MtnMinecraftLoaderType.vanilla,
      onDownload: (_) async => throw const SocketException('offline'),
    );

    expect(await list.getFromMinecraftVersion('1.21.11'), isEmpty);
    expect(list.error, MtnMinecraftError.downloadFailed);
    expect(File('${root.path}/vanilla-1.21.11.json').existsSync(), isFalse);
  });
}
