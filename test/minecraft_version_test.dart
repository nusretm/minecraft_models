import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

void main() {
  MtnMinecraftVersion version(
    String raw, [
    MtnMinecraftGameVersionType type = MtnMinecraftGameVersionType.release,
  ]) => MtnMinecraftVersion.parse(raw, type: type);

  group('MtnMinecraftVersion', () {
    test('parses one to three numeric components without changing raw text', () {
      final one = version('1');
      expect(one.raw, '1');
      expect(one.major, 1);
      expect(one.minor, isNull);
      expect(one.build, isNull);
      expect(one.qualifier, isNull);
      expect(one.componentCount, 1);
      expect(one.type, MtnMinecraftGameVersionType.release);
      expect(one.toString(), '1');

      final two = version('1.21');
      expect(two.major, 1);
      expect(two.minor, 21);
      expect(two.build, isNull);
      expect(two.componentCount, 2);

      final three = version('26.1.2');
      expect(three.major, 26);
      expect(three.minor, 1);
      expect(three.build, 2);
      expect(three.componentCount, 3);
    });

    test('retains numeric qualifiers and opaque snapshot identifiers', () {
      final qualified = version(
        '26.3-snapshot-10',
        MtnMinecraftGameVersionType.snapshot,
      );
      expect(qualified.raw, '26.3-snapshot-10');
      expect(qualified.major, 26);
      expect(qualified.minor, 3);
      expect(qualified.componentCount, 2);
      expect(qualified.qualifier, 'snapshot-10');
      expect(qualified.type, MtnMinecraftGameVersionType.snapshot);

      final opaque = version('24w14a', MtnMinecraftGameVersionType.snapshot);
      expect(opaque.raw, '24w14a');
      expect(opaque.componentCount, 0);
      expect(opaque.major, isNull);
      expect(opaque.minor, isNull);
      expect(opaque.build, isNull);
      expect(opaque.qualifier, isNull);

      final unexpected = version('1.21.2.4');
      expect(unexpected.raw, '1.21.2.4');
      expect(unexpected.componentCount, 0);
    });

    test('requires non-empty untrimmed input and explicit game version type', () {
      expect(() => version(''), throwsArgumentError);
      expect(() => version('  '), throwsArgumentError);
      expect(() => version(' 1.21.4'), throwsArgumentError);
      expect(() => version('1.21.4 '), throwsArgumentError);
      expect(
        version('1.21.4').contains(
          <MtnMinecraftGameVersionType>[
            MtnMinecraftGameVersionType.snapshot,
            MtnMinecraftGameVersionType.release,
          ],
        ),
        isTrue,
      );
      expect(
        version('1.21.4').contains(
          <MtnMinecraftGameVersionType>[MtnMinecraftGameVersionType.snapshot],
        ),
        isFalse,
      );
    });

    test('compares unqualified numeric releases using normalized components', () {
      expect(version('1.21.1') < version('1.21.2'), isTrue);
      expect(version('1.21.2') <= version('1.21.3'), isTrue);
      expect(version('1.21.3') < version('1.21.4'), isTrue);
      expect(version('26.1.2') > version('1.21.4'), isTrue);
      expect(version('1.22') >= version('1.21.4'), isTrue);
      expect(version('1.21').compareTo(version('1.21.0')), 0);
      expect(version('1').compareTo(version('1.0.0')), 0);
      expect(version('1.21.10') > version('1.21.9'), isTrue);
      expect(version('1.21.2') < version('1.22'), isTrue);
    });

    test('never guesses ordering for snapshots, qualifiers or opaque releases', () {
      final release = version('1.21.4');
      final snapshot = version('24w14a', MtnMinecraftGameVersionType.snapshot);
      final numericSnapshot = version('26.3-snapshot-10', MtnMinecraftGameVersionType.snapshot);
      final releaseWithQualifier = version('1.21.4-rc1');
      final opaqueRelease = version('special');
      final preRelease = version('1.21.4', MtnMinecraftGameVersionType.preRelease);

      expect(() => snapshot.compareTo(release), throwsStateError);
      expect(() => numericSnapshot.compareTo(release), throwsStateError);
      expect(() => release.compareTo(releaseWithQualifier), throwsStateError);
      expect(() => opaqueRelease.compareTo(release), throwsStateError);
      expect(() => preRelease.compareTo(release), throwsStateError);
      expect(() => snapshot.compareTo(snapshot), throwsStateError);
    });

    test('equality and hash code preserve exact semantic identity', () {
      final a = version('1.21');
      final b = version('1.21.0');
      final c = version('1.21.0.0');
      final d = version('1.21', MtnMinecraftGameVersionType.snapshot);
      final opaqueOne = version('24w14a', MtnMinecraftGameVersionType.snapshot);
      final opaqueTwo = version('24w14a', MtnMinecraftGameVersionType.snapshot);
      final opaqueDifferent = version('24w14b', MtnMinecraftGameVersionType.snapshot);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
      expect(<MtnMinecraftVersion>{a, b}, hasLength(1));
      expect(opaqueOne, opaqueTwo);
      expect(opaqueOne.hashCode, opaqueTwo.hashCode);
      expect(opaqueOne, isNot(opaqueDifferent));
      expect(version('1.21.0-rc1'), isNot(version('1.21.0-rc2')));
      expect(version('1.21.0-rc1'), isNot(version('1.21.0')));
    });
  });
}
