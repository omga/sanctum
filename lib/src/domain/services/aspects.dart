import 'dart:math' as math;

import 'package:sanctum/src/domain/models/compatibility.dart';

/// How two planetary positions relate.
///
/// ## Why harmonics rather than orbs
///
/// Traditional astrology counts an aspect only inside an orb — a square
/// is "in effect" within 8° of 90° and simply absent at 45°. Modelled
/// literally that produces a product where most planet pairs contribute
/// nothing at all, every score sits on its baseline, and the occasional
/// pair spikes. Flat with spikes is the worst possible distribution for
/// something people compare with their friends.
///
/// So this uses the harmonic form instead, which is a real school of
/// astrology and happens to be continuous: `cos(4θ)` peaks at 0°, 90°
/// and 180° — the hard, charged angles — and bottoms out at 45° and
/// 135°. `cos(6θ)` peaks at 0°, 60°, 120° and 180°, the flowing ones,
/// and bottoms out at 30°, 90° and 150°.
///
/// Every pair of positions therefore produces a defined, distinct number
/// that moves smoothly with the real geometry. Nothing is bucketed and
/// nothing is invented.
abstract final class Aspects {
  /// Angular separation between two ecliptic longitudes, `0–180`.
  static double separation(double a, double b) {
    final raw = (a - b).abs() % 360;
    return raw > 180 ? 360 - raw : raw;
  }

  /// Charge: conjunction, square and opposition, `0–1`.
  ///
  /// The friction aspects. High heat is attraction and volatility at
  /// once, which is why it drives Spark and Drama rather than Trust.
  static double heat(double a, double b) =>
      (1 + math.cos(4 * _radians(separation(a, b)))) / 2;

  /// Flow: conjunction, sextile, trine and opposition, `0–1`.
  ///
  /// The aspects that make something comfortable rather than exciting.
  static double ease(double a, double b) =>
      (1 + math.cos(6 * _radians(separation(a, b)))) / 2;

  /// The exact angle each aspect wants, and the orb it is allowed.
  ///
  /// Orbs are the conventional ones, widest for the major angles. They
  /// are asymmetric on purpose: a conjunction 7° from exact is still a
  /// conjunction to any astrologer, and a quincunx 7° from exact is
  /// nothing at all.
  static const Map<ZodiacAspect, ({double angle, double orb})> _orbs = {
    ZodiacAspect.conjunction: (angle: 0, orb: 8),
    ZodiacAspect.semiSextile: (angle: 30, orb: 2),
    ZodiacAspect.sextile: (angle: 60, orb: 5),
    ZodiacAspect.square: (angle: 90, orb: 7),
    ZodiacAspect.trine: (angle: 120, orb: 7),
    ZodiacAspect.quincunx: (angle: 150, orb: 3),
    ZodiacAspect.opposition: (angle: 180, orb: 8),
  };

  /// The named angle between [a] and [b], or `null` when there is none.
  ///
  /// Returns the closest aspect whose orb contains the separation. Null
  /// is a real and common answer — most planet pairs are not in contact
  /// — and callers are expected to say so rather than reach for the
  /// nearest angle regardless of distance.
  static AspectContact? contact(double a, double b) {
    final gap = separation(a, b);

    AspectContact? best;
    for (final entry in _orbs.entries) {
      final orb = (gap - entry.value.angle).abs();
      if (orb > entry.value.orb) continue;
      if (best != null && orb >= best.orb) continue;
      best = AspectContact(aspect: entry.key, separation: gap, orb: orb);
    }
    return best;
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}

/// How a named contact feels, which is what selects its copy.
enum ContactTone {
  /// Sextile and trine. The contact costs nothing.
  flowing,

  /// Square, quincunx, semi-sextile. The contact costs something.
  hard,

  /// Conjunction and opposition. Amplified rather than easy or hard.
  charged,
}

/// One named angle between two positions, with the orb it holds to.
///
/// This is the *descriptive* layer, and it is deliberately separate from
/// the harmonic scoring above. [Aspects.heat] and [Aspects.ease] answer
/// "how much does this pair contribute", continuously, for every pair —
/// which is the right model for a score and the wrong one for a
/// sentence. Nobody wants to read "your Venus is 0.41 heat to their
/// Mars". They want to read that it is square, and by how much.
///
/// Classifying by orb here does not reintroduce the flat-with-spikes
/// distribution the scoring model avoids, because nothing here feeds a
/// number. When no aspect is in orb the honest output is that these two
/// planets are not in contact — the same posture as the daily reading
/// admitting a quiet day rather than inventing news about a Tuesday.
class AspectContact {
  /// Creates a contact.
  const AspectContact({
    required this.aspect,
    required this.separation,
    required this.orb,
  });

  /// The named angle.
  final ZodiacAspect aspect;

  /// Angular separation between the two positions, `0–180`.
  final double separation;

  /// How far from exact the contact sits, in degrees.
  final double orb;

  /// Within a degree of exact, which is worth saying out loud.
  bool get isExact => orb <= 1;

  /// Which family of copy this contact selects.
  ContactTone get tone => switch (aspect) {
    ZodiacAspect.sextile || ZodiacAspect.trine => ContactTone.flowing,
    ZodiacAspect.square ||
    ZodiacAspect.quincunx ||
    ZodiacAspect.semiSextile => ContactTone.hard,
    ZodiacAspect.conjunction ||
    ZodiacAspect.opposition => ContactTone.charged,
  };
}
