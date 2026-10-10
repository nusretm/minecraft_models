import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

void main() {
  test('loader names round-trip through the public enum', () {
    for (final loaderType in MtnMinecraftLoaderType.values) {
      expect(MtnMinecraftLoaderType.fromName(loaderType.name), loaderType);
      expect(MtnMinecraftLoaderType.fromName(loaderType.name.toUpperCase()), loaderType);
      expect(MtnMinecraftLoaderType.fromName('  ${loaderType.name}  '), loaderType);
    }
  });

  test('unknown loader names are not silently interpreted as vanilla', () {
    expect(MtnMinecraftLoaderType.fromName(null), isNull);
    expect(MtnMinecraftLoaderType.fromName(''), isNull);
    expect(MtnMinecraftLoaderType.fromName('   '), isNull);
    expect(MtnMinecraftLoaderType.fromName('fabric-api'), isNull);
    expect(MtnMinecraftLoaderType.fromName('not-a-loader'), isNull);
  });

  test('loader identity codes remain the five canonical providers', () {
    expect(MtnMinecraftLoaderType.values, [
      MtnMinecraftLoaderType.vanilla,
      MtnMinecraftLoaderType.fabric,
      MtnMinecraftLoaderType.forge,
      MtnMinecraftLoaderType.neoforge,
      MtnMinecraftLoaderType.quilt,
    ]);
    expect(MtnMinecraftLoaderType.neoforge.name, 'neoforge');
  });
}
