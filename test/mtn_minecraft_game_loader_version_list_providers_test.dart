import 'dart:io';

import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

class _VanillaFixture extends MtnMinecraftGameLoaderVersionListVanilla {
  _VanillaFixture({required super.cacheDirectory});

  @override
  Future<String> downloadUrl(String url) async {
    expect(url, contains('version_manifest_v2.json'));
    return '{"versions":[{"id":"1.21.11","type":"release","url":"https://example.invalid/1.21.11.json"},{"id":"1.21.11-rc3","type":"snapshot","url":"https://example.invalid/rc3.json"}]}';
  }
}

class _FabricFixture extends MtnMinecraftGameLoaderVersionListFabric {
  _FabricFixture({required super.cacheDirectory});

  @override
  Future<String> downloadUrl(String url) async {
    if (url.endsWith('/versions/game')) return '[{"version":"1.21.11","stable":true}]';
    if (url.endsWith('/versions/loader/1.21.11')) return '[{"loader":{"version":"0.19.5","stable":true}},{"loader":{"version":"0.19.4","stable":false}}]';
    throw StateError('Unexpected Fabric URL: $url');
  }
}

class _QuiltFixture extends MtnMinecraftGameLoaderVersionListQuilt {
  _QuiltFixture({required super.cacheDirectory});

  @override
  Future<String> downloadUrl(String url) async {
    if (url.endsWith('/versions/game')) return '[{"version":"1.21.11","stable":true}]';
    if (url.endsWith('/versions/loader/1.21.11')) return '[{"loader":{"version":"0.20.0-beta.9"}},{"loader":{"version":"0.20.0-beta.8"}}]';
    throw StateError('Unexpected Quilt URL: $url');
  }
}

class _ForgeFixture extends MtnMinecraftGameLoaderVersionListForge {
  _ForgeFixture({required super.cacheDirectory});

  @override
  Future<String> downloadUrl(String url) async {
    expect(url, contains('maven-metadata.xml'));
    return '<metadata><versioning><versions><version>1.21.11-61.2.0</version><version>1.21.1-52.1.16</version><version>1.21.11-61.2.1</version></versions></versioning></metadata>';
  }
}

class _NeoForgeFixture extends MtnMinecraftGameLoaderVersionListNeoForge {
  _NeoForgeFixture({required super.cacheDirectory});

  @override
  Future<String> downloadUrl(String url) async {
    if (url.contains('/neoforge/maven-metadata.xml')) return '<metadata><versions><version>21.11.44</version><version>21.1.257</version><version>21.11.45</version></versions></metadata>';
    if (url.contains('/forge/maven-metadata.xml')) return '<metadata><versions><version>1.20.1-47.1.1</version></versions></metadata>';
    throw StateError('Unexpected NeoForge URL: $url');
  }
}

class _NeoForgeMissingLegacyFixture extends _NeoForgeFixture {
  _NeoForgeMissingLegacyFixture({required super.cacheDirectory});

  @override
  Future<String> downloadUrl(String url) async {
    if (url.contains('/forge/maven-metadata.xml')) throw const SocketException('optional legacy index unavailable');
    return super.downloadUrl(url);
  }
}

void main() {
  late Directory cache;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('minecraft_loader_provider_test_');
  });

  tearDown(() async {
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  test('provider constructors expose fixed loader identities', () {
    expect(MtnMinecraftGameLoaderVersionListVanilla(cacheDirectory: cache.path).loaderName, 'vanilla');
    expect(MtnMinecraftGameLoaderVersionListFabric(cacheDirectory: cache.path).loaderName, 'fabric');
    expect(MtnMinecraftGameLoaderVersionListQuilt(cacheDirectory: cache.path).loaderName, 'quilt');
    expect(MtnMinecraftGameLoaderVersionListForge(cacheDirectory: cache.path).loaderName, 'forge');
    expect(MtnMinecraftGameLoaderVersionListNeoForge(cacheDirectory: cache.path).loaderName, 'neoforge');
  });

  test('Vanilla direct query initializes catalog and groups release candidates', () async {
    final list = _VanillaFixture(cacheDirectory: cache.path);
    final versions = await list.getFromMinecraftVersion('1.21.11');
    expect(list.items, hasLength(2));
    expect(versions.map((v) => v.version), ['1.21.11', '1.21.11-rc3']);
    expect(versions.last.mcVersion, '1.21.11');
    expect(versions.last.type, MtnMinecraftGameVersionType.releaseCandidate);
    expect(versions.first.url, 'https://example.invalid/1.21.11.json');
  });

  test('Fabric loads game index then resolves actual loader builds', () async {
    final list = _FabricFixture(cacheDirectory: cache.path);
    final versions = await list.getFromMinecraftVersion('1.21.11');
    expect(list.items.single.version, '1.21.11');
    expect(versions, hasLength(2));
    expect(versions.first.version, '0.19.5');
    expect(versions.first.channel, MtnMinecraftGameLoaderChannel.stable);
    expect(versions.last.channel, MtnMinecraftGameLoaderChannel.unknown);
    expect(versions.first.url, endsWith('/1.21.11/0.19.5/profile/json'));
    expect(await list.getFromMinecraftVersion('1.21.11', [MtnMinecraftGameVersionType.snapshot]), isEmpty);
  });

  test('Quilt returns real beta loader builds separately from game index', () async {
    final list = _QuiltFixture(cacheDirectory: cache.path);
    final versions = await list.getFromMinecraftVersion('1.21.11');
    expect(list.items.single.version, '1.21.11');
    expect(versions.map((v) => v.version), ['0.20.0-beta.9', '0.20.0-beta.8']);
    expect(versions.first.channel, MtnMinecraftGameLoaderChannel.beta);
    expect(versions.first.url, endsWith('/0.20.0-beta.9/profile/json'));
  });

  test('Forge parses Maven versions and filters by Minecraft version', () async {
    final list = _ForgeFixture(cacheDirectory: cache.path);
    final versions = await list.getFromMinecraftVersion('1.21.11');
    expect(versions.map((v) => v.version), ['1.21.11-61.2.1', '1.21.11-61.2.0']);
    expect(versions.first.type, MtnMinecraftGameVersionType.release);
    expect(versions.first.url, endsWith('/forge-1.21.11-61.2.1-installer.jar'));
  });

  test('NeoForge maps modern builds and optional legacy Maven coordinate', () async {
    final list = _NeoForgeFixture(cacheDirectory: cache.path);
    final builds = await list.getFromMinecraftVersion('1.21.11');
    expect(builds.map((v) => v.version), ['21.11.45', '21.11.44']);
    expect(builds.first.url, endsWith('/neoforge-21.11.45-installer.jar'));
    final legacy = await list.getFromMinecraftVersion('1.20.1');
    expect(legacy, hasLength(1));
    expect(legacy.single.version, '1.20.1-47.1.1');
  });

  test('missing optional NeoForge legacy index does not discard modern builds', () async {
    final list = _NeoForgeMissingLegacyFixture(cacheDirectory: cache.path);
    final builds = await list.getFromMinecraftVersion('1.21.11');
    expect(builds, hasLength(2));
    expect(builds.first.version, '21.11.45');
  });
}
