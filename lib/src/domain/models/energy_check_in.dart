import 'package:dart_mappable/dart_mappable.dart';

part 'energy_check_in.mapper.dart';

/// How a user reports feeling.
///
/// Five levels rather than a free-form slider: a small, named set is
/// faster to answer, and answers that can be compared are worth far more
/// than answers that are merely precise.
@MappableEnum()
enum EnergyLevel {
  /// Flat, drained.
  depleted('Depleted', 1),

  /// Low but functioning.
  low('Low', 2),

  /// Neither up nor down.
  steady('Steady', 3),

  /// Bright.
  open('Open', 4),

  /// Fully lit.
  radiant('Radiant', 5);

  const EnergyLevel(this.displayName, this.value);

  /// Human-readable name.
  final String displayName;

  /// Ordinal 1–5, used for charting and for storage.
  final int value;

  /// Rebuilds a level from its stored [value].
  static EnergyLevel fromValue(int value) => EnergyLevel.values.firstWhere(
    (level) => level.value == value,
    orElse: () => EnergyLevel.steady,
  );
}

/// A single daily check-in.
@MappableClass()
class EnergyCheckIn with EnergyCheckInMappable {
  /// Creates a check-in.
  const EnergyCheckIn({
    required this.id,
    required this.recordedAt,
    required this.level,
    this.note,
  });

  /// Local database id.
  final int id;

  /// When it was recorded.
  final DateTime recordedAt;

  /// The reported level.
  final EnergyLevel level;

  /// Optional free text.
  final String? note;
}
