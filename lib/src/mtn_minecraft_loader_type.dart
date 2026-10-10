/// The canonical Minecraft loader identity shared by the models and launcher.
enum MtnMinecraftLoaderType {
  vanilla,
  fabric,
  forge,
  neoforge,
  quilt;

  /// Case-insensitive lookup. Unsupported or missing names are not Vanilla.
  static MtnMinecraftLoaderType? fromName(String? name) {
    final normalized = name?.trim().toLowerCase();
    for (final loaderType in values) {
      if (loaderType.name == normalized) return loaderType;
    }
    return null;
  }
}
