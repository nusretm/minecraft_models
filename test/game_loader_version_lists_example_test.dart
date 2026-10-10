import 'package:minecraft_models/src/loaders/src/mtn_minecraft_game_loader_version_parsing.dart' as parsing;

import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

void main() {
  test('Minecraft version classification keeps releases and previews distinct', () {
    expect(parsing.minecraftTypeFromId('1.21.11'), MtnMinecraftGameVersionType.release);
    expect(parsing.minecraftTypeFromId('1.21.11-pre5'), MtnMinecraftGameVersionType.preRelease);
    expect(parsing.minecraftTypeFromId('1.21.11-rc3'), MtnMinecraftGameVersionType.releaseCandidate);
    expect(parsing.minecraftTypeFromId('26.4-snapshot-2'), MtnMinecraftGameVersionType.snapshot);
    expect(parsing.minecraftTypeFromId('25w46a'), MtnMinecraftGameVersionType.snapshot);
    expect(parsing.minecraftVersionFamily('1.21.11-pre5'), '1.21.11');
    expect(parsing.minecraftVersionFamily('25w46a'), '25w46a');
  });

  test('Maven metadata extraction preserves exact release identifiers', () {
    expect(parsing.mavenVersions('<metadata><versions><version>1.21.1-52.0.1</version><version>1.21.1-52.0.2</version></versions></metadata>'),
        ['1.21.1-52.0.1', '1.21.1-52.0.2']);
    expect(() => parsing.mavenVersions('<metadata />'), throwsFormatException);
  });

  test('NeoForge version-family mapping covers legacy and modern calendar versions', () {
    expect(MtnMinecraftGameLoaderVersionListNeoForge.minecraftVersionFromBuild('20.2.3-beta'), '1.20.2');
    expect(MtnMinecraftGameLoaderVersionListNeoForge.minecraftVersionFromBuild('21.1.181'), '1.21.1');
    expect(MtnMinecraftGameLoaderVersionListNeoForge.minecraftVersionFromBuild('21.11.10-beta'), '1.21.11');
    expect(MtnMinecraftGameLoaderVersionListNeoForge.minecraftVersionFromBuild('26.1.2.15'), '26.1.2');
    expect(MtnMinecraftGameLoaderVersionListNeoForge.minecraftVersionFromBuild('26.2.0.71'), '26.2');
    expect(MtnMinecraftGameLoaderVersionListNeoForge.minecraftVersionFromBuild('unexpected'), isNull);
  });

  test('Unknown loader channels must not be advertised as stable', () {
    expect(parsing.loaderChannel('21.1.181'), MtnMinecraftGameLoaderChannel.unknown);
    expect(parsing.loaderChannel('21.1.181-beta'), MtnMinecraftGameLoaderChannel.beta);
    expect(parsing.loaderChannel('0.18.4', stable: true), MtnMinecraftGameLoaderChannel.stable);
    expect(parsing.loaderChannel('0.18.4', stable: false), MtnMinecraftGameLoaderChannel.unknown);
  });
}
