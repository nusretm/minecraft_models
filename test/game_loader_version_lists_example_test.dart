import '../example/game_loader_version_lists.dart' as example;

import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

void main() {
  test('Minecraft version classification keeps releases and previews distinct', () {
    expect(example.minecraftTypeFromId('1.21.11'), MtnMinecraftGameVersionType.release);
    expect(example.minecraftTypeFromId('1.21.11-pre5'), MtnMinecraftGameVersionType.preRelease);
    expect(example.minecraftTypeFromId('1.21.11-rc3'), MtnMinecraftGameVersionType.releaseCandidate);
    expect(example.minecraftTypeFromId('26.4-snapshot-2'), MtnMinecraftGameVersionType.snapshot);
    expect(example.minecraftTypeFromId('25w46a'), MtnMinecraftGameVersionType.snapshot);
    expect(example.minecraftVersionFamily('1.21.11-pre5'), '1.21.11');
    expect(example.minecraftVersionFamily('25w46a'), '25w46a');
  });

  test('Maven metadata extraction preserves exact release identifiers', () {
    expect(example.mavenVersions('<metadata><versions><version>1.21.1-52.0.1</version><version>1.21.1-52.0.2</version></versions></metadata>'),
        ['1.21.1-52.0.1', '1.21.1-52.0.2']);
    expect(() => example.mavenVersions('<metadata />'), throwsFormatException);
  });

  test('NeoForge version-family mapping covers legacy and modern calendar versions', () {
    expect(example.neoForgeMinecraftVersion('20.2.3-beta'), '1.20.2');
    expect(example.neoForgeMinecraftVersion('21.1.181'), '1.21.1');
    expect(example.neoForgeMinecraftVersion('21.11.10-beta'), '1.21.11');
    expect(example.neoForgeMinecraftVersion('26.1.2.15'), '26.1.2');
    expect(example.neoForgeMinecraftVersion('26.2.0.71'), '26.2');
    expect(example.neoForgeMinecraftVersion('unexpected'), isNull);
  });

  test('Unknown loader channels must not be advertised as stable', () {
    expect(example.loaderChannel('21.1.181'), MtnMinecraftGameLoaderChannel.unknown);
    expect(example.loaderChannel('21.1.181-beta'), MtnMinecraftGameLoaderChannel.beta);
    expect(example.loaderChannel('0.18.4', stable: true), MtnMinecraftGameLoaderChannel.stable);
    expect(example.loaderChannel('0.18.4', stable: false), MtnMinecraftGameLoaderChannel.unknown);
  });
}
