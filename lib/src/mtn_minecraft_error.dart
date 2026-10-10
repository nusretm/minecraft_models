/// Typed status for generic Minecraft loader catalog and cache operations.
/// The enum code is not an HTTP status code; the HTTP status can be included in the error message.
enum MtnMinecraftError {
  none                  (0),
  unknown               (1),

  cacheMetadataFailed   (1001),
  cacheReadFailed       (1002),
  cacheWriteFailed      (1003),
  cacheDeleteFailed     (1004),

  downloadInvalidUrl    (2001),
  downloadHttpFailed    (2002),
  downloadTimeout       (2003),
  downloadNetworkFailed (2004),
  downloadClientFailed  (2005),
  downloadFailed        (2006),

  ;

  final int code;
  const MtnMinecraftError(this.code);

  factory MtnMinecraftError.fromIndex(int index) {
    if (index < 0 || index >= values.length) return MtnMinecraftError.unknown;
    return values[index];
  }

  factory MtnMinecraftError.fromCode(int code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return MtnMinecraftError.unknown;
  }

  static bool isCacheError(MtnMinecraftError value) {
    return value.code >= 1000 && value.code < 2000;
  }

  static bool isDownloadError(MtnMinecraftError value) {
    return value.code >= 2000 && value.code < 3000;
  }
}
