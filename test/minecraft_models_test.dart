import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

void main() {
  group('MtnLauncherGameVersionType', () {
    test('preserves the existing values and order', () {
      expect(
        MtnLauncherGameVersionType.values.map((value) => value.name),
        [
          'release',
          'snapshot',
          'preRelease',
          'releaseCandidate',
          'beta',
          'alpha',
          'experimental',
          'unknown',
        ],
      );
    });
  });

  group('MtnLauncherGameLoaderMinecraftVersion', () {
    test('preserves exact record values through the public API', () {
      const MtnLauncherGameLoaderMinecraftVersion game = (
        mcVersion: '24w14a family',
        versionId: '24W14a+Exact',
        type: MtnLauncherGameVersionType.snapshot,
      );

      expect(game.mcVersion, '24w14a family');
      expect(game.versionId, '24W14a+Exact');
      expect(game.type, MtnLauncherGameVersionType.snapshot);
    });
  });

  group('MtnLauncherGameLoaderChannel', () {
    test('has the approved values and order', () {
      expect(
        MtnLauncherGameLoaderChannel.values.map((value) => value.name),
        ['stable', 'beta', 'alpha', 'experimental', 'unknown'],
      );
    });
  });

  group('MtnLauncherGameLoaderVersion', () {
    const exactVersion = '0.15.11+Build.Meta-1.20.1';
    const exactUrl = 'HTTPS://Example.invalid/Path/File.JSON?Build=A%2Bb#Part';

    test('defaults an unspecified loader channel to unknown', () {
      const model = MtnLauncherGameLoaderVersion(
        mcVersion: '1.20.1',
        version: exactVersion,
        url: exactUrl,
        type: MtnLauncherGameVersionType.release,
      );

      expect(model.channel, MtnLauncherGameLoaderChannel.unknown);
    });

    test('keeps game version type and loader channel independent', () {
      const model = MtnLauncherGameLoaderVersion(
        mcVersion: '24w14a',
        version: 'loader-build',
        url: exactUrl,
        type: MtnLauncherGameVersionType.snapshot,
        channel: MtnLauncherGameLoaderChannel.stable,
      );

      expect(model.type, MtnLauncherGameVersionType.snapshot);
      expect(model.channel, MtnLauncherGameLoaderChannel.stable);
    });

    test('round-trips every stored field without normalizing identity or URL', () {
      const model = MtnLauncherGameLoaderVersion(
        mcVersion: '1.20.1',
        version: exactVersion,
        url: exactUrl,
        type: MtnLauncherGameVersionType.preRelease,
        channel: MtnLauncherGameLoaderChannel.beta,
      );

      final json = model.toJson();
      expect(json, {
        'mcVersion': '1.20.1',
        'version': exactVersion,
        'url': exactUrl,
        'type': 'preRelease',
        'channel': 'beta',
      });
      expect(MtnLauncherGameLoaderVersion.fromJson(json), model);
    });

    test('validates without trimming accepted strings', () {
      final model = MtnLauncherGameLoaderVersion.fromJson({
        'mcVersion': ' 1.20.1 ',
        'version': ' Build-A ',
        'url': ' HTTPS://Example.invalid/Exact ',
        'type': 'release',
        'channel': 'stable',
      });

      expect(model.mcVersion, ' 1.20.1 ');
      expect(model.version, ' Build-A ');
      expect(model.url, ' HTTPS://Example.invalid/Exact ');
    });

    test('maps only an absent channel to unknown and ignores extra fields', () {
      final model = MtnLauncherGameLoaderVersion.fromJson({
        'mcVersion': '1.20.1',
        'version': exactVersion,
        'url': exactUrl,
        'type': 'releaseCandidate',
        'providerMetadata': 'ignored',
      });

      expect(model.channel, MtnLauncherGameLoaderChannel.unknown);
      expect(model.type, MtnLauncherGameVersionType.releaseCandidate);
      expect(model.toJson()['channel'], 'unknown');
    });

    test('rejects missing required fields', () {
      final valid = <String, Object?>{
        'mcVersion': '1.20.1',
        'version': exactVersion,
        'url': exactUrl,
        'type': 'release',
        'channel': 'stable',
      };

      for (final key in ['mcVersion', 'version', 'url', 'type']) {
        final json = Map<String, Object?>.of(valid)..remove(key);
        expect(
          () => MtnLauncherGameLoaderVersion.fromJson(json),
          throwsFormatException,
          reason: key,
        );
      }
    });

    test('rejects null, non-string, empty, or whitespace-only required fields', () {
      final valid = <String, Object?>{
        'mcVersion': '1.20.1',
        'version': exactVersion,
        'url': exactUrl,
        'type': 'release',
      };

      for (final key in ['mcVersion', 'version', 'url', 'type']) {
        for (final invalid in <Object?>[null, 42, '', ' \t\r\n']) {
          final json = Map<String, Object?>.of(valid)..[key] = invalid;
          expect(
            () => MtnLauncherGameLoaderVersion.fromJson(json),
            throwsFormatException,
            reason: '$key: $invalid',
          );
        }
      }
    });

    test('rejects invalid type names', () {
      expect(
        () => MtnLauncherGameLoaderVersion.fromJson({
          'mcVersion': '1.20.1',
          'version': exactVersion,
          'url': exactUrl,
          'type': 'Release',
        }),
        throwsFormatException,
      );
    });

    test('rejects explicit invalid channel values', () {
      for (final invalid in <Object?>[null, 42, '', '   ', 'preview']) {
        expect(
          () => MtnLauncherGameLoaderVersion.fromJson({
            'mcVersion': '1.20.1',
            'version': exactVersion,
            'url': exactUrl,
            'type': 'release',
            'channel': invalid,
          }),
          throwsFormatException,
          reason: '$invalid',
        );
      }
    });

    test('shortens only an exact leading or trailing Minecraft version', () {
      const leading = MtnLauncherGameLoaderVersion(
        mcVersion: '1.20.1',
        version: '1.20.1-loader-build',
        url: exactUrl,
        type: MtnLauncherGameVersionType.release,
      );
      const trailing = MtnLauncherGameLoaderVersion(
        mcVersion: '1.20.1',
        version: 'loader-build-1.20.1',
        url: exactUrl,
        type: MtnLauncherGameVersionType.release,
      );
      const embedded = MtnLauncherGameLoaderVersion(
        mcVersion: '1.20.1',
        version: 'loader-1.20.1-build',
        url: exactUrl,
        type: MtnLauncherGameVersionType.release,
      );

      expect(leading.text, 'loader-build');
      expect(trailing.text, 'loader-build');
      expect(embedded.text, 'loader-1.20.1-build');
    });

    test('uses structural equality and hashes every stored field', () {
      const first = MtnLauncherGameLoaderVersion(
        mcVersion: '1.20.1',
        version: exactVersion,
        url: exactUrl,
        type: MtnLauncherGameVersionType.release,
        channel: MtnLauncherGameLoaderChannel.stable,
      );
      const equal = MtnLauncherGameLoaderVersion(
        mcVersion: '1.20.1',
        version: exactVersion,
        url: exactUrl,
        type: MtnLauncherGameVersionType.release,
        channel: MtnLauncherGameLoaderChannel.stable,
      );
      const differentValues = [
        MtnLauncherGameLoaderVersion(
          mcVersion: '1.20.2',
          version: exactVersion,
          url: exactUrl,
          type: MtnLauncherGameVersionType.release,
          channel: MtnLauncherGameLoaderChannel.stable,
        ),
        MtnLauncherGameLoaderVersion(
          mcVersion: '1.20.1',
          version: 'different-build',
          url: exactUrl,
          type: MtnLauncherGameVersionType.release,
          channel: MtnLauncherGameLoaderChannel.stable,
        ),
        MtnLauncherGameLoaderVersion(
          mcVersion: '1.20.1',
          version: exactVersion,
          url: 'https://different.invalid/',
          type: MtnLauncherGameVersionType.release,
          channel: MtnLauncherGameLoaderChannel.stable,
        ),
        MtnLauncherGameLoaderVersion(
          mcVersion: '1.20.1',
          version: exactVersion,
          url: exactUrl,
          type: MtnLauncherGameVersionType.snapshot,
          channel: MtnLauncherGameLoaderChannel.stable,
        ),
        MtnLauncherGameLoaderVersion(
          mcVersion: '1.20.1',
          version: exactVersion,
          url: exactUrl,
          type: MtnLauncherGameVersionType.release,
          channel: MtnLauncherGameLoaderChannel.beta,
        ),
      ];

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      final equalSet = <MtnLauncherGameLoaderVersion>{};
      equalSet.add(first);
      equalSet.add(equal);
      expect(equalSet, hasLength(1));
      for (final different in differentValues) {
        expect(first, isNot(different));
      }
    });
  });
}
