import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/ephemeris.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';

/// Whether [date] sits within [days] of a sun-sign boundary.
///
/// Cusp dates are the one place the two methods are allowed to disagree:
/// the tabulated ranges are fixed calendar dates, the real ingress drifts
/// by up to a day and a half across the leap-year cycle, and a birth
/// date carries no time of day.
bool nearCusp(DateTime date, {int days = 2}) {
  final sign = Zodiac.signFor(date);
  for (var offset = -days; offset <= days; offset++) {
    if (Zodiac.signFor(date.add(Duration(days: offset))) != sign) {
      return true;
    }
  }
  return false;
}

void main() {
  group('julian day', () {
    test('matches the standard epoch', () {
      // J2000.0 is 2000-01-01 12:00 TT = JD 2451545.0, and this is the
      // anchor every other number in the file is measured from.
      expect(
        Ephemeris.julianDay(DateTime(2000, 1, 1)),
        closeTo(2451545.0, 0.001),
      );
    });

    test('advances by one per day, across a month boundary', () {
      expect(
        Ephemeris.julianDay(DateTime(2024, 3, 1)) -
            Ephemeris.julianDay(DateTime(2024, 2, 29)),
        closeTo(1, 1e-9),
      );
    });

    test('handles the Gregorian leap-century rule', () {
      expect(
        Ephemeris.julianDay(DateTime(1900, 3, 1)) -
            Ephemeris.julianDay(DateTime(1900, 2, 28)),
        closeTo(1, 1e-9),
      );
    });
  });

  group('the sun, checked against the tabulated ranges', () {
    // The strongest test in this file. Zodiac.signFor is a hand-written
    // table of calendar dates; Ephemeris computes the Sun from orbital
    // elements, a Kepler solve, a heliocentric-to-geocentric transform
    // and a precession correction. They share no code. Agreeing across
    // decades means the whole chain is right — and precession in
    // particular, which is invisible until it is a degree out.
    test('agrees on every non-cusp day of a sample year', () {
      var checked = 0;
      for (var day = 0; day < 365; day++) {
        final date = DateTime(1996, 1, 1).add(Duration(days: day));
        if (nearCusp(date)) continue;
        checked++;
        expect(
          Ephemeris.signAt(Ephemeris.sunLongitude(date)),
          Zodiac.signFor(date),
          reason: 'disagreement on $date',
        );
      }
      expect(checked, greaterThan(300));
    });

    test('agrees across seven decades', () {
      for (final year in [1955, 1968, 1974, 1989, 2001, 2013, 2024]) {
        for (var month = 1; month <= 12; month++) {
          final date = DateTime(year, month, 10);
          if (nearCusp(date)) continue;
          expect(
            Ephemeris.signAt(Ephemeris.sunLongitude(date)),
            Zodiac.signFor(date),
            reason: 'disagreement on $date',
          );
        }
      }
    });
  });

  group('longitudes', () {
    test('are always in range', () {
      for (var year = 1950; year <= 2030; year += 3) {
        final date = DateTime(year, 6, 15);
        for (final longitude in [
          Ephemeris.sunLongitude(date),
          Ephemeris.venusLongitude(date),
          Ephemeris.marsLongitude(date),
          Ephemeris.saturnLongitude(date),
        ]) {
          expect(longitude, inInclusiveRange(0, 360));
        }
      }
    });

    test('Venus never strays far from the Sun', () {
      // Venus is an inner planet: its greatest elongation is about 47°.
      // A geocentric transform that has gone wrong shows up here
      // immediately, because a heliocentric longitude would not be
      // bounded like this.
      for (var day = 0; day < 800; day += 7) {
        final date = DateTime(1990, 1, 1).add(Duration(days: day));
        var separation =
            (Ephemeris.venusLongitude(date) - Ephemeris.sunLongitude(date))
                .abs();
        if (separation > 180) separation = 360 - separation;
        expect(separation, lessThan(48), reason: 'on $date');
      }
    });

    test('places Saturn at the 2020 great conjunction', () {
      // Jupiter and Saturn met at 0°29' Aquarius on 2020-12-21 — one of
      // the most precisely documented positions in modern astronomy, and
      // an outer planet, so it exercises the parts of the transform that
      // the Sun check cannot reach.
      expect(
        Ephemeris.saturnLongitude(DateTime(2020, 12, 21)),
        closeTo(300.48, 0.5),
      );
    });

    test('puts Mars opposite the Sun at its 2020 opposition', () {
      // Mars reached opposition on 2020-10-13. Self-checking: whatever
      // the absolute longitudes are, they must be 180° apart.
      final date = DateTime(2020, 10, 13);
      var separation =
          (Ephemeris.marsLongitude(date) - Ephemeris.sunLongitude(date))
              .abs();
      if (separation > 180) separation = 360 - separation;
      expect(separation, closeTo(180, 1));
    });

    test('puts the Sun at 0° Capricorn on the December solstice', () {
      // The solstice is the definition of 270° tropical, so this pins
      // the precession correction directly.
      expect(
        Ephemeris.sunLongitude(DateTime(2020, 12, 21)),
        closeTo(270, 0.5),
      );
    });

    test('matches Venus at its 2020 greatest elongation', () {
      // Venus reached greatest eastern elongation of 46.1° on
      // 2020-03-24.
      final date = DateTime(2020, 3, 24);
      final elongation =
          Ephemeris.venusLongitude(date) - Ephemeris.sunLongitude(date);
      expect(elongation, closeTo(46.1, 0.5));
    });

    test('are deterministic', () {
      final date = DateTime(1996, 6, 15);
      expect(
        Ephemeris.venusLongitude(date),
        Ephemeris.venusLongitude(date),
      );
    });
  });

  group('time of day', () {
    test('is ignored unless asked for', () {
      // Load-bearing, and the reason time is an argument rather than
      // being read off the DateTime. Transits are computed from a date,
      // but nothing stops a caller passing a full `DateTime.now()` — and
      // if that silently moved the sky, the daily reading would drift
      // through the afternoon and a user who opened the app twice would
      // see two different readings for one day.
      expect(
        Ephemeris.julianDay(DateTime(2026, 1, 1, 23, 59)),
        Ephemeris.julianDay(DateTime(2026, 1, 1)),
      );
      expect(
        Ephemeris.sunLongitude(DateTime(2026, 1, 1, 23, 59)),
        Ephemeris.sunLongitude(DateTime(2026, 1, 1)),
      );
    });

    test('offsets the instant from noon when supplied', () {
      final noon = Ephemeris.julianDay(DateTime(2026, 1, 1));

      expect(
        Ephemeris.julianDay(DateTime(2026, 1, 1), timeOfDay: Duration.zero),
        closeTo(noon - 0.5, 1e-9),
      );
      expect(
        Ephemeris.julianDay(
          DateTime(2026, 1, 1),
          timeOfDay: const Duration(hours: 18),
        ),
        closeTo(noon + 0.25, 1e-9),
      );
      expect(
        Ephemeris.julianDay(
          DateTime(2026, 1, 1),
          timeOfDay: const Duration(hours: 12),
        ),
        closeTo(noon, 1e-9),
      );
    });

    test('barely moves the slow bodies, which is the honest claim', () {
      // Worth pinning because it is the opposite of what a user expects
      // when they supply a birth time. Saturn does not care what hour
      // you were born, and the app should not imply that it does — the
      // Moon is the whole reason the question is asked.
      final date = DateTime(1994, 7, 3);
      final midnight = Ephemeris.saturnLongitude(
        date,
        timeOfDay: Duration.zero,
      );
      final evening = Ephemeris.saturnLongitude(
        date,
        timeOfDay: const Duration(hours: 23),
      );

      expect((evening - midnight).abs(), lessThan(0.15));
    });
  });

  group('moon', () {
    // The Moon is validated differently from every other body here, and
    // more strongly. Its longitude comes from Meeus' truncated series,
    // while the Sun's comes from Keplerian elements plus a precession
    // correction — two entirely separate code paths. At a real new moon
    // the two must agree, and at a real full moon they must be 180°
    // apart. That is a cross-check of both, and it is what proves the
    // lunar series is already referred to the equinox of date and must
    // not be run through the precession correction a second time.
    double elongationAt(DateTime date, Duration time) {
      final moon = Ephemeris.moonLongitude(date, timeOfDay: time);
      final sun = Ephemeris.sunLongitude(date, timeOfDay: time);
      var separation = (moon - sun) % 360;
      if (separation > 180) separation -= 360;
      return separation;
    }

    test('meets the sun at documented new moons', () {
      // USNO new moon instants, UTC.
      expect(
        elongationAt(
          DateTime(1990, 1, 26),
          const Duration(hours: 19, minutes: 20),
        ),
        closeTo(0, 0.1),
      );
      expect(
        elongationAt(
          DateTime(2000, 1, 6),
          const Duration(hours: 18, minutes: 14),
        ),
        closeTo(0, 0.1),
      );
      expect(
        elongationAt(
          DateTime(2024, 1, 11),
          const Duration(hours: 11, minutes: 57),
        ),
        closeTo(0, 0.1),
      );
      expect(
        elongationAt(
          DateTime(2026, 8, 12),
          const Duration(hours: 17, minutes: 37),
        ),
        closeTo(0, 0.1),
      );
    });

    test('opposes the sun at documented full moons', () {
      expect(
        elongationAt(
          DateTime(2024, 1, 25),
          const Duration(hours: 17, minutes: 54),
        ),
        closeTo(180, 0.1),
      );
      expect(
        elongationAt(
          DateTime(2026, 8, 28),
          const Duration(hours: 4, minutes: 18),
        ),
        closeTo(180, 0.1),
      );
    });

    test('moves far enough in a day that a birth time matters', () {
      // The entire justification for asking the question. Half a day of
      // uncertainty is a quarter of a sign, so a noon guess would be a
      // fabricated Moon sign a good fraction of the time.
      final date = DateTime(2026, 3, 10);
      final midnight = Ephemeris.moonLongitude(date, timeOfDay: Duration.zero);
      final noon = Ephemeris.moonLongitude(
        date,
        timeOfDay: const Duration(hours: 12),
      );

      expect((noon - midnight).abs(), greaterThan(5));
    });

    test('stays inside the circle', () {
      var date = DateTime(2020, 1, 1);
      for (var i = 0; i < 400; i++) {
        final longitude = Ephemeris.moonLongitude(date);
        expect(longitude, greaterThanOrEqualTo(0), reason: '$date');
        expect(longitude, lessThan(360), reason: '$date');
        date = date.add(const Duration(days: 1));
      }
    });
  });

  group('signAt', () {
    test('divides the tropical circle from Aries', () {
      expect(Ephemeris.signAt(0), ZodiacSign.aries);
      expect(Ephemeris.signAt(29.99), ZodiacSign.aries);
      expect(Ephemeris.signAt(30), ZodiacSign.taurus);
      expect(Ephemeris.signAt(359.9), ZodiacSign.pisces);
    });

    test('wraps rather than throwing', () {
      expect(Ephemeris.signAt(360), ZodiacSign.aries);
      expect(Ephemeris.signAt(-1), ZodiacSign.pisces);
    });
  });
}
