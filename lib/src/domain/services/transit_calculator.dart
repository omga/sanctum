import 'package:sanctum/src/domain/models/planet.dart';
import 'package:sanctum/src/domain/models/transit.dart';
import 'package:sanctum/src/domain/services/ephemeris.dart';

/// Finds where today's sky touches a birth chart.
///
/// ## Why this exists
///
/// Before this, "today" on the home screen was an affirmation drawn from
/// a bag of twenty-two and an oracle card picked by hashing the date.
/// Both are stable and neither is *connected* to yesterday or tomorrow,
/// so there was never a reason to come back on any particular day.
///
/// A transit is the opposite: it is a real angle between a real planet's
/// position today and a real position in the user's chart. It changes
/// because the sky moved, it differs between two users born a week
/// apart, and — the part that matters most — it is knowable in advance,
/// so the app can honestly say what tomorrow holds.
abstract final class TransitCalculator {
  /// Every transit in orb on [day] for someone born on [birthDate].
  ///
  /// Ordered strongest first.
  static List<Transit> forDay({
    required DateTime birthDate,
    required DateTime day,
  }) {
    final natal = <Planet, double>{
      for (final planet in Planet.natal)
        planet: Ephemeris.longitudeOf(planet, birthDate),
    };

    final hits = <Transit>[];
    for (final transiting in Planet.values) {
      final sky = Ephemeris.longitudeOf(transiting, day);

      for (final entry in natal.entries) {
        // A body aspecting its own natal position is a real thing —
        // a Saturn return is exactly that — but a *conjunction* of the
        // Sun to the natal Sun is just a birthday, and the rest are the
        // slow background of a life rather than news about a Tuesday.
        if (transiting == entry.key) continue;

        final aspect = _aspectBetween(sky, entry.value, transiting.orb);
        if (aspect == null) continue;

        hits.add(
          Transit(
            transiting: transiting,
            natal: entry.key,
            aspect: aspect.$1,
            orb: aspect.$2,
            retrograde: Ephemeris.isRetrograde(transiting, day),
          ),
        );
      }
    }

    return hits
      ..sort((a, b) => b.significance.compareTo(a.significance));
  }

  /// The one transit worth leading with, or `null` on a quiet day.
  static Transit? headline({
    required DateTime birthDate,
    required DateTime day,
  }) => forDay(birthDate: birthDate, day: day).firstOrNull;

  /// Bodies that are retrograde on [day].
  ///
  /// Mercury retrograde is the most culturally legible thing in
  /// astrology — people who believe none of the rest of it still plan
  /// around it — and it costs nothing here, because retrograde is just
  /// apparent longitude decreasing.
  static List<Planet> retrogrades(DateTime day) => [
    for (final planet in Planet.values)
      if (planet.canRetrograde && Ephemeris.isRetrograde(planet, day))
        planet,
  ];

  /// The closest aspect between two longitudes, with its orb.
  static (TransitAspect, double)? _aspectBetween(
    double a,
    double b,
    double orb,
  ) {
    final raw = (a - b).abs() % 360;
    final separation = raw > 180 ? 360 - raw : raw;

    (TransitAspect, double)? best;
    for (final aspect in TransitAspect.values) {
      final distance = (separation - aspect.angle).abs();
      if (distance > orb) continue;
      if (best == null || distance < best.$2) best = (aspect, distance);
    }
    return best;
  }
}
