import 'package:minecraft_models/minecraft_models.dart';
import 'package:test/test.dart';

void main() {
  test('reserved numeric codes map to exact enum values', () {
    for (final value in MtnMinecraftError.values) {
      expect(MtnMinecraftError.fromIndex(value.index), value);
      expect(MtnMinecraftError.fromCode(value.code), value);
    }

    expect(MtnMinecraftError.fromIndex(-1), MtnMinecraftError.unknown);
    expect(MtnMinecraftError.fromIndex(MtnMinecraftError.values.length), MtnMinecraftError.unknown);
    expect(MtnMinecraftError.fromCode(-1), MtnMinecraftError.unknown);
    expect(MtnMinecraftError.fromCode(404), MtnMinecraftError.unknown);
  });

  test('cache errors and download errors are independently grouped', () {
    for (final value in MtnMinecraftError.values) {
      final cache = MtnMinecraftError.isCacheError(value);
      final download = MtnMinecraftError.isDownloadError(value);
      expect(cache, value.code >= 1000 && value.code < 2000);
      expect(download, value.code >= 2000 && value.code < 3000);
      expect(cache && download, isFalse);
    }
  });

  test('success and unknown do not belong to an error group', () {
    for (final value in [MtnMinecraftError.none, MtnMinecraftError.unknown]) {
      expect(MtnMinecraftError.isCacheError(value), isFalse);
      expect(MtnMinecraftError.isDownloadError(value), isFalse);
    }
  });
}
