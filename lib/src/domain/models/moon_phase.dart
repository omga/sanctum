import 'package:dart_mappable/dart_mappable.dart';

part 'moon_phase.mapper.dart';

/// The eight named phases of the lunar cycle.
///
/// Pure domain: no Flutter, no assets, no icons. How a phase is *drawn*
/// is a design-system concern; what a phase *is* lives here.
@MappableEnum()
enum MoonPhase {
  /// Dark moon. Traditionally a time for setting intentions.
  newMoon('New Moon'),

  /// Growing, just past new.
  waxingCrescent('Waxing Crescent'),

  /// Half lit and growing.
  firstQuarter('First Quarter'),

  /// Mostly lit and growing.
  waxingGibbous('Waxing Gibbous'),

  /// Fully lit. Traditionally a time for release.
  fullMoon('Full Moon'),

  /// Mostly lit and shrinking.
  waningGibbous('Waning Gibbous'),

  /// Half lit and shrinking.
  lastQuarter('Last Quarter'),

  /// Thin and shrinking, just before new.
  waningCrescent('Waning Crescent');

  const MoonPhase(this.displayName);

  /// Human-readable name.
  final String displayName;

  /// Whether the illuminated fraction is growing.
  bool get isWaxing => switch (this) {
    MoonPhase.waxingCrescent ||
    MoonPhase.firstQuarter ||
    MoonPhase.waxingGibbous => true,
    _ => false,
  };

  /// Whether this is one of the two phases Sanctum builds rituals around.
  bool get isRitualMoon =>
      this == MoonPhase.newMoon || this == MoonPhase.fullMoon;
}

/// A full description of the moon at a given moment.
///
/// `with MoonReadingMappable` is where dart_mappable earns its place: it
/// supplies `==`, `hashCode`, `toString` and `copyWith` from the
/// constructor alone. Writing those by hand is not hard, but it is very
/// easy to add a field and forget to add it to `==` — producing a class
/// that compares equal when it is not, and a UI that refuses to rebuild.
@MappableClass()
class MoonReading with MoonReadingMappable {
  /// Creates a moon reading.
  const MoonReading({
    required this.phase,
    required this.cyclePosition,
    required this.illumination,
    required this.ageInDays,
  });

  /// The named phase.
  final MoonPhase phase;

  /// Position through the cycle, `0.0` at new moon, `0.5` at full,
  /// approaching `1.0` back at new.
  final double cyclePosition;

  /// Fraction of the disc lit, `0.0`–`1.0`.
  final double illumination;

  /// Days elapsed since the last new moon.
  final double ageInDays;
}
