import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

void main() {
  group('MtnMinecraftGameVersionType', () {
    test('preserves the existing values and order', () {
      expect(
        MtnMinecraftGameVersionType.values.map((value) => value.name),
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

  group('MtnMinecraftGameLoaderChannel', () {
    test('has the approved values and order', () {
      expect(
        MtnMinecraftGameLoaderChannel.values.map((value) => value.name),
        ['stable', 'beta', 'alpha', 'experimental', 'unknown'],
      );
    });
  });

  group('MtnMinecraftGameLoaderVersion', () {
    const exactVersion = '0.15.11+Build.Meta-1.20.1';
    const exactUrl = 'HTTPS://Example.invalid/Path/File.JSON?Build=A%2Bb#Part';

    test('defaults an unspecified loader channel to unknown', () {
      const model = MtnMinecraftGameLoaderVersion(
        mcVersion: '1.20.1',
        version: exactVersion,
        url: exactUrl,
        type: MtnMinecraftGameVersionType.release,
      );

      expect(model.channel, MtnMinecraftGameLoaderChannel.unknown);
    });

    test('keeps game version type and loader channel independent', () {
      const model = MtnMinecraftGameLoaderVersion(
        mcVersion: '24w14a',
        version: 'loader-build',
        url: exactUrl,
        type: MtnMinecraftGameVersionType.snapshot,
        channel: MtnMinecraftGameLoaderChannel.stable,
      );

      expect(model.type, MtnMinecraftGameVersionType.snapshot);
      expect(model.channel, MtnMinecraftGameLoaderChannel.stable);
    });

    test('round-trips every stored field without normalizing identity or URL', () {
      const model = MtnMinecraftGameLoaderVersion(
        mcVersion: '1.20.1',
        version: exactVersion,
        url: exactUrl,
        type: MtnMinecraftGameVersionType.preRelease,
        channel: MtnMinecraftGameLoaderChannel.beta,
      );

      final json = model.toJson();
      expect(json, {
        'mcVersion': '1.20.1',
        'version': exactVersion,
        'url': exactUrl,
        'type': 'preRelease',
        'channel': 'beta',
      });
      expect(MtnMinecraftGameLoaderVersion.fromJson(json), model);
    });

    test('validates without trimming accepted strings', () {
      final model = MtnMinecraftGameLoaderVersion.fromJson({
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
      final model = MtnMinecraftGameLoaderVersion.fromJson({
        'mcVersion': '1.20.1',
        'version': exactVersion,
        'url': exactUrl,
        'type': 'releaseCandidate',
        'providerMetadata': 'ignored',
      });

      expect(model.channel, MtnMinecraftGameLoaderChannel.unknown);
      expect(model.type, MtnMinecraftGameVersionType.releaseCandidate);
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
          () => MtnMinecraftGameLoaderVersion.fromJson(json),
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
            () => MtnMinecraftGameLoaderVersion.fromJson(json),
            throwsFormatException,
            reason: '$key: $invalid',
          );
        }
      }
    });

    test('rejects invalid type names', () {
      expect(
        () => MtnMinecraftGameLoaderVersion.fromJson({
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
          () => MtnMinecraftGameLoaderVersion.fromJson({
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
      const leading = MtnMinecraftGameLoaderVersion(
        mcVersion: '1.20.1',
        version: '1.20.1-loader-build',
        url: exactUrl,
        type: MtnMinecraftGameVersionType.release,
      );
      const trailing = MtnMinecraftGameLoaderVersion(
        mcVersion: '1.20.1',
        version: 'loader-build-1.20.1',
        url: exactUrl,
        type: MtnMinecraftGameVersionType.release,
      );
      const embedded = MtnMinecraftGameLoaderVersion(
        mcVersion: '1.20.1',
        version: 'loader-1.20.1-build',
        url: exactUrl,
        type: MtnMinecraftGameVersionType.release,
      );

      expect(leading.text, 'loader-build');
      expect(trailing.text, 'loader-build');
      expect(embedded.text, 'loader-1.20.1-build');
    });

    test('uses structural equality and hashes every stored field', () {
      const first = MtnMinecraftGameLoaderVersion(
        mcVersion: '1.20.1',
        version: exactVersion,
        url: exactUrl,
        type: MtnMinecraftGameVersionType.release,
        channel: MtnMinecraftGameLoaderChannel.stable,
      );
      const equal = MtnMinecraftGameLoaderVersion(
        mcVersion: '1.20.1',
        version: exactVersion,
        url: exactUrl,
        type: MtnMinecraftGameVersionType.release,
        channel: MtnMinecraftGameLoaderChannel.stable,
      );
      const differentValues = [
        MtnMinecraftGameLoaderVersion(
          mcVersion: '1.20.2',
          version: exactVersion,
          url: exactUrl,
          type: MtnMinecraftGameVersionType.release,
          channel: MtnMinecraftGameLoaderChannel.stable,
        ),
        MtnMinecraftGameLoaderVersion(
          mcVersion: '1.20.1',
          version: 'different-build',
          url: exactUrl,
          type: MtnMinecraftGameVersionType.release,
          channel: MtnMinecraftGameLoaderChannel.stable,
        ),
        MtnMinecraftGameLoaderVersion(
          mcVersion: '1.20.1',
          version: exactVersion,
          url: 'https://different.invalid/',
          type: MtnMinecraftGameVersionType.release,
          channel: MtnMinecraftGameLoaderChannel.stable,
        ),
        MtnMinecraftGameLoaderVersion(
          mcVersion: '1.20.1',
          version: exactVersion,
          url: exactUrl,
          type: MtnMinecraftGameVersionType.snapshot,
          channel: MtnMinecraftGameLoaderChannel.stable,
        ),
        MtnMinecraftGameLoaderVersion(
          mcVersion: '1.20.1',
          version: exactVersion,
          url: exactUrl,
          type: MtnMinecraftGameVersionType.release,
          channel: MtnMinecraftGameLoaderChannel.beta,
        ),
      ];

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      final equalSet = <MtnMinecraftGameLoaderVersion>{};
      equalSet.add(first);
      equalSet.add(equal);
      expect(equalSet, hasLength(1));
      for (final different in differentValues) {
        expect(first, isNot(different));
      }
    });
  });
}
