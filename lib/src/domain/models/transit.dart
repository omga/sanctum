import 'package:dart_mappable/dart_mappable.dart';
import 'package:sanctum/src/domain/models/planet.dart';

part 'transit.mapper.dart';

/// The angle a transit makes.
@MappableEnum()
enum TransitAspect {
  /// Same degree. Fusion — the loudest of them.
  conjunction(0, 'meets', hard: true),

  /// 60°. Easy, and easily missed.
  sextile(60, 'supports', hard: false),

  /// 90°. Friction that forces a decision.
  square(90, 'presses on', hard: true),

  /// 120°. Flowing, sometimes to the point of laziness.
  trine(120, 'flows with', hard: false),

  /// 180°. Pulled in two directions at once.
  opposition(180, 'pulls against', hard: true);

  const TransitAspect(this.angle, this.verb, {required this.hard});

  /// Exact separation, in degrees.
  final int angle;

  /// Reads as `Mars <verb> your Venus`.
  final String verb;

  /// Whether this one is felt as pressure rather than as ease.
  final bool hard;

  /// Relative significance.
  double get weight => switch (this) {
    TransitAspect.conjunction => 1.2,
    TransitAspect.opposition => 1.1,
    TransitAspect.square => 1.05,
    TransitAspect.trine => 1.0,
    TransitAspect.sextile => 0.85,
  };
}

/// One planet in the sky today, touching one planet in a birth chart.
///
/// This is what a horoscope actually is, as opposed to the newspaper
/// version: not "Geminis will have a good day" but "Mars is at 14° Libra
/// today and your Venus is at 15° Capricorn, so those two are square".
/// It is different every day because the sky moved, and different for
/// every user because their chart is theirs.
@MappableClass()
class Transit with TransitMappable {
  /// Creates a transit.
  const Transit({
    required this.transiting,
    required this.natal,
    required this.aspect,
    required this.orb,
    required this.retrograde,
  });

  /// The body in the sky now.
  final Planet transiting;

  /// The body in the birth chart it is touching.
  final Planet natal;

  /// The angle between them.
  final TransitAspect aspect;

  /// Degrees away from exact. Smaller is stronger.
  final double orb;

  /// Whether the transiting body is retrograde.
  final bool retrograde;

  /// `1.0` at exact, falling to `0.0` at the edge of the orb.
  double get tightness => (1 - orb / transiting.orb).clamp(0.0, 1.0);

  /// Ranking score. Exactness first, then how much the body matters.
  double get significance =>
      tightness * transiting.weight * aspect.weight;

  /// Whether this is within half a degree of exact.
  bool get isExact => orb <= 0.5;

  /// "Mars presses on your Venus".
  String get headline =>
      '${transiting.displayName} ${aspect.verb} your '
      '${natal.displayName}';
}

/// Everything the home screen says about today.
///
/// Not persisted — it is recomputed from the birth date and the date, so
/// there is nothing to migrate and nothing that can go stale.
class DailyTransitReading {
  /// Creates a reading.
  const DailyTransitReading({
    required this.line,
    required this.retrogrades,
    this.transit,
    this.tomorrow,
    this.retrogradeNote,
  });

  /// The transit being described, or `null` on a quiet day.
  final Transit? transit;

  /// The reading itself.
  final String line;

  /// What arrives tomorrow, when it differs from today.
  ///
  /// The only honest open loop this app has. A daily card cannot promise
  /// anything about tomorrow because it is a hash; a transit can, because
  /// the sky is on rails.
  final String? tomorrow;

  /// Bodies currently retrograde.
  final List<Planet> retrogrades;

  /// The line about the most legible retrograde, if any.
  final String? retrogradeNote;

  /// Whether there is a real transit behind this reading.
  bool get isPersonal => transit != null;
}
