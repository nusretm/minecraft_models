import '../../mtn_minecraft_game_loader_channel.dart';
import '../../mtn_minecraft_game_version_type.dart';

/// Interpret Minecraft version IDs; explicit provider metadata takes precedence.
MtnMinecraftGameVersionType minecraftTypeFromId(String id, {String? manifestType, bool? stable}) {
  final name = id.toLowerCase();
  if (name.contains('experimental')) return MtnMinecraftGameVersionType.experimental;
  if (RegExp(r'(?:-pre-?\d+|[ -]pre-release[ -]?\d+)$').hasMatch(name)) return MtnMinecraftGameVersionType.preRelease;
  if (RegExp(r'(?:-rc-?\d+|[ -]release candidate[ -]?\d+)$').hasMatch(name)) return MtnMinecraftGameVersionType.releaseCandidate;
  if (manifestType == 'old_alpha' || RegExp(r'^a\d').hasMatch(name)) return MtnMinecraftGameVersionType.alpha;
  if (manifestType == 'old_beta' || RegExp(r'^b\d').hasMatch(name)) return MtnMinecraftGameVersionType.beta;
  if (manifestType == 'snapshot' || RegExp(r'^\d{2}w\d{2}[a-z]$').hasMatch(name) || name.contains('-snapshot-')) return MtnMinecraftGameVersionType.snapshot;
  if (manifestType == 'release' || stable == true || RegExp(r'^\d+\.\d+(?:\.\d+)?$').hasMatch(name)) return MtnMinecraftGameVersionType.release;
  return MtnMinecraftGameVersionType.unknown;
}

/// Preserve exact preview build IDs separately from the Minecraft version family.
String minecraftVersionFamily(String id) {
  final preview = RegExp(r'^(\d+\.\d+(?:\.\d+)?)-(?:pre|rc)-?\d+$', caseSensitive: false).firstMatch(id);
  if (preview != null) return preview.group(1)!;
  final snapshot = RegExp(r'^(\d+\.\d+(?:\.\d+)?)-snapshot-\d+$').firstMatch(id);
  return snapshot?.group(1) ?? id;
}

/// A missing stable flag or unmarked version is not proof of stability.
MtnMinecraftGameLoaderChannel loaderChannel(String version, {bool? stable}) {
  if (stable == true) return MtnMinecraftGameLoaderChannel.stable;
  final id = version.toLowerCase();
  if (RegExp(r'(?:^|[.+_-])experimental\d*(?=$|[.+_-])').hasMatch(id)) return MtnMinecraftGameLoaderChannel.experimental;
  if (RegExp(r'(?:^|[.+_-])alpha\d*(?=$|[.+_-])').hasMatch(id)) return MtnMinecraftGameLoaderChannel.alpha;
  if (RegExp(r'(?:^|[.+_-])beta\d*(?=$|[.+_-])').hasMatch(id)) return MtnMinecraftGameLoaderChannel.beta;
  return MtnMinecraftGameLoaderChannel.unknown;
}

/// Extract exact Maven version strings; the caller owns provider-specific mapping.
List<String> mavenVersions(String xml) {
  final values = RegExp(r'<version>\s*([^<]+?)\s*</version>').allMatches(xml).map((match) => match.group(1)!.trim()).where((value) => value.isNotEmpty).toList();
  if (values.isEmpty) throw const FormatException('Maven metadata has no published versions.');
  return values;
}
