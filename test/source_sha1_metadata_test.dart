import 'dart:convert';

import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

void main() {
  const String sourceUrl = 'HTTPS://Example.invalid/Version/Profile.JSON?Exact=%2B';
  const String checksum = 'A19f49d4b31af176d9699c7e8fdc4ea2d551aa09';

  const MtnLauncherGameLoaderVersion withSha1 = MtnLauncherGameLoaderVersion(
    mcVersion: '1.21.11',
    version: '1.21.11',
    url: sourceUrl,
    type: MtnLauncherGameVersionType.release,
    channel: MtnLauncherGameLoaderChannel.stable,
    sha1: checksum,
  );

  test('optional source SHA-1 keeps the public constructor const and preserves exact bytes', () {
    expect(withSha1.url, sourceUrl);
    expect(withSha1.version, '1.21.11');
    expect(withSha1.sha1, checksum);
    expect(withSha1.type, MtnLauncherGameVersionType.release);
    expect(withSha1.channel, MtnLauncherGameLoaderChannel.stable);
  });

  test('JSON round trip preserves source URL and SHA-1 without normalization', () {
    final Map<String, Object> json = withSha1.toJson();
    expect(json['url'], sourceUrl);
    expect(json['sha1'], checksum);

    final Object? restoredJson = jsonDecode(jsonEncode(json));
    expect(restoredJson, isA<Map<String, dynamic>>());
    final MtnLauncherGameLoaderVersion decoded = MtnLauncherGameLoaderVersion.fromJson(
      Map<String, Object?>.from(restoredJson as Map<String, dynamic>),
    );
    expect(decoded, withSha1);
    expect(decoded.sha1, checksum);
    expect(decoded.toJson(), json);
  });

  test('old JSON without SHA-1 remains valid and does not gain a new key', () {
    final Map<String, Object?> historical = <String, Object?>{
      'mcVersion': '1.21.11',
      'version': '1.21.11',
      'url': sourceUrl,
      'type': 'release',
      'channel': 'unknown',
    };
    final MtnLauncherGameLoaderVersion restored = MtnLauncherGameLoaderVersion.fromJson(historical);
    expect(restored.sha1, isNull);
    expect(restored.toJson(), historical);
    expect(restored.channel, MtnLauncherGameLoaderChannel.unknown);

    const MtnLauncherGameLoaderVersion withoutSha1 = MtnLauncherGameLoaderVersion(
      mcVersion: '1.21.11',
      version: '1.21.11',
      url: sourceUrl,
      type: MtnLauncherGameVersionType.release,
    );
    expect(withoutSha1.sha1, isNull);
    expect(withoutSha1.toJson().containsKey('sha1'), isFalse);
  });

  test('legacy missing channel and missing SHA-1 retain existing defaults', () {
    final MtnLauncherGameLoaderVersion restored = MtnLauncherGameLoaderVersion.fromJson({
      'mcVersion': '1.21.11',
      'version': '1.21.11',
      'url': sourceUrl,
      'type': 'snapshot',
    });
    expect(restored.channel, MtnLauncherGameLoaderChannel.unknown);
    expect(restored.sha1, isNull);
  });

  test('explicit invalid SHA-1 JSON field fails instead of silently dropping metadata', () {
    for (final Object? invalid in <Object?>[null, 3, false, '', ' \t\n']) {
      final Map<String, Object?> json = Map<String, Object?>.from(withSha1.toJson())..['sha1'] = invalid;
      expect(
        () => MtnLauncherGameLoaderVersion.fromJson(json),
        throwsFormatException,
        reason: 'Invalid sha1: $invalid',
      );
    }
  });

  test('SHA-1 participates in structural equality and hashCode', () {
    final MtnLauncherGameLoaderVersion same = MtnLauncherGameLoaderVersion(
      mcVersion: '1.21.11',
      version: '1.21.11',
      url: sourceUrl,
      type: MtnLauncherGameVersionType.release,
      channel: MtnLauncherGameLoaderChannel.stable,
      sha1: checksum,
    );
    const MtnLauncherGameLoaderVersion different = MtnLauncherGameLoaderVersion(
      mcVersion: '1.21.11',
      version: '1.21.11',
      url: sourceUrl,
      type: MtnLauncherGameVersionType.release,
      channel: MtnLauncherGameLoaderChannel.stable,
      sha1: 'B19f49d4b31af176d9699c7e8fdc4ea2d551aa09',
    );
    const MtnLauncherGameLoaderVersion absent = MtnLauncherGameLoaderVersion(
      mcVersion: '1.21.11',
      version: '1.21.11',
      url: sourceUrl,
      type: MtnLauncherGameVersionType.release,
      channel: MtnLauncherGameLoaderChannel.stable,
    );

    expect(identical(same, withSha1), isFalse);
    expect(same, withSha1);
    expect(same.hashCode, withSha1.hashCode);
    expect(different, isNot(withSha1));
    expect(absent, isNot(withSha1));
    expect(<MtnLauncherGameLoaderVersion>{withSha1, same, different, absent}, hasLength(3));
  });

  test('SHA-1 is stored as source metadata; no digest verification is performed', () {
    final MtnLauncherGameLoaderVersion model = MtnLauncherGameLoaderVersion.fromJson({
      'mcVersion': 'old-beta',
      'version': 'old-beta',
      'url': 'https://example.invalid/old.json',
      'type': 'beta',
      'sha1': 'opaque-upstream-value',
    });
    expect(model.sha1, 'opaque-upstream-value');
    expect(model.channel, MtnLauncherGameLoaderChannel.unknown);
  });
}
