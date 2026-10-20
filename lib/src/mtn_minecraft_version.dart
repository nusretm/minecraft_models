import 'mtn_minecraft_game_version_type.dart';

/// An exact Minecraft game-version identity with conservative release ordering.
///
/// The parser preserves upstream version text. Only unqualified numeric
/// [MtnMinecraftGameVersionType.release] versions support [compareTo].
/// Snapshot and preview versions are intentionally not assigned inferred order.
final class MtnMinecraftVersion implements Comparable<MtnMinecraftVersion> {
  MtnMinecraftVersion._({
    required this.raw,
    required this.major,
    required this.minor,
    required this.build,
    required this.qualifier,
    required this.componentCount,
    required this.type,
  });

  static final RegExp _numericPattern = RegExp(
    r'^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-(.+))?$',
  );

  /// Exact input, including any qualifier. Never normalized for display.
  final String raw;

  /// Numeric components are null for non-numeric (opaque) upstream IDs.
  final int? major;
  final int? minor;
  final int? build;

  /// Qualifier on a numeric ID, e.g. `snapshot-10`.
  final String? qualifier;

  /// Number of recognized numeric components: 0 for an opaque identifier.
  final int componentCount;

  /// Minecraft release classification, not a loader-build channel.
  final MtnMinecraftGameVersionType type;

  /// Parses an upstream version without inferring its release classification.
  ///
  /// The required [type] is supplied by an authoritative caller/source.
  /// Other non-empty identifiers are preserved as opaque raw versions.
  factory MtnMinecraftVersion.parse(
    String raw, {
    required MtnMinecraftGameVersionType type,
  }) {
    if (raw.isEmpty || raw.trim() != raw) {
      throw ArgumentError.value(
        raw,
        'raw',
        'Version cannot be empty or contain leading/trailing whitespace.',
      );
    }

    final RegExpMatch? match = _numericPattern.firstMatch(raw);
    if (match == null) {
      return MtnMinecraftVersion._(
        raw: raw,
        major: null,
        minor: null,
        build: null,
        qualifier: null,
        componentCount: 0,
        type: type,
      );
    }

    final String? minor = match.group(2);
    final String? build = match.group(3);
    return MtnMinecraftVersion._(
      raw: raw,
      major: int.parse(match.group(1)!),
      minor: minor == null ? null : int.parse(minor),
      build: build == null ? null : int.parse(build),
      qualifier: match.group(4),
      componentCount: build != null ? 3 : minor != null ? 2 : 1,
      type: type,
    );
  }

  /// Whether this version belongs to at least one of the supplied types.
  bool contains(List<MtnMinecraftGameVersionType> types) => types.contains(type);

  /// Orders only unqualified, numeric, release versions.
  ///
  /// Missing trailing components are treated as zero. Non-release,
  /// qualified, and opaque versions throw [StateError] instead of guessing
  /// historical or snapshot ordering.
  @override
  int compareTo(MtnMinecraftVersion other) {
    if (!_supportsOrdering || !other._supportsOrdering) {
      throw StateError(
        'Ordering is not supported for "$raw" and "${other.raw}".',
      );
    }

    final int majorComparison = major!.compareTo(other.major!);
    if (majorComparison != 0) return majorComparison;

    final int minorComparison = _normalizedMinor.compareTo(other._normalizedMinor);
    if (minorComparison != 0) return minorComparison;

    return _normalizedBuild.compareTo(other._normalizedBuild);
  }

  bool operator <(MtnMinecraftVersion other) => compareTo(other) < 0;

  bool operator <=(MtnMinecraftVersion other) => compareTo(other) <= 0;

  bool operator >(MtnMinecraftVersion other) => compareTo(other) > 0;

  bool operator >=(MtnMinecraftVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MtnMinecraftVersion || type != other.type) return false;

    if (_hasNumericBase && other._hasNumericBase) {
      return major == other.major &&
          _normalizedMinor == other._normalizedMinor &&
          _normalizedBuild == other._normalizedBuild &&
          qualifier == other.qualifier;
    }

    return !_hasNumericBase &&
        !other._hasNumericBase &&
        raw == other.raw;
  }

  @override
  int get hashCode {
    if (_hasNumericBase) {
      return Object.hash(
        type,
        major,
        _normalizedMinor,
        _normalizedBuild,
        qualifier,
      );
    }
    return Object.hash(type, raw);
  }

  @override
  String toString() => raw;

  bool get _hasNumericBase => componentCount > 0;

  bool get _supportsOrdering =>
      type == MtnMinecraftGameVersionType.release &&
      _hasNumericBase &&
      qualifier == null;

  int get _normalizedMinor => minor ?? 0;

  int get _normalizedBuild => build ?? 0;
}
