import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/services/moon_phase_calculator.dart';

/// Reference phase events taken from the US Naval Observatory
/// (`aa.usno.navy.mil/api/moon/phases`), in UTC.
///
/// These are real astronomical data, not values produced by the code
/// under test — which is the whole point. A test asserting that the
/// algorithm returns what the algorithm returns proves nothing.
final _usnoEvents = <(String, DateTime, MoonPhase)>[
  ('2026 full', _d(2026, 1, 3, 10, 3), MoonPhase.fullMoon),
  ('2026 last quarter', _d(2026, 1, 10, 15, 48), MoonPhase.lastQuarter),
  ('2026 new', _d(2026, 1, 18, 19, 52), MoonPhase.newMoon),
  ('2026 first quarter', _d(2026, 1, 26, 4, 47), MoonPhase.firstQuarter),
  ('2026 feb full', _d(2026, 2, 1, 22, 9), MoonPhase.fullMoon),
  ('2026 feb new', _d(2026, 2, 17, 12, 1), MoonPhase.newMoon),
  ('2026 aug new', _d(2026, 8, 12, 17, 37), MoonPhase.newMoon),
  ('2026 aug first quarter', _d(2026, 8, 20, 2, 46), MoonPhase.firstQuarter),
  ('2026 aug full', _d(2026, 8, 28, 4, 18), MoonPhase.fullMoon),
  ('2026 aug last quarter', _d(2026, 8, 6, 2, 21), MoonPhase.lastQuarter),
];

/// Dates that are NOT phase events — they sit part-way between them,
/// near a band boundary.
///
/// This is the group that matters. The original mean-synodic
/// implementation passed every event-centred assertion above while being
/// ~0.6 days out, because a 0.6-day error is invisible in the middle of
/// a 3.7-day band. It only showed up on a date near an edge: on
/// 2026-08-15, two and a half days after the new moon, the app confidently
/// displayed "New Moon".
final _boundaryCases = <(String, DateTime, MoonPhase)>[
  // New moon was 2026-08-12 17:37, so these are ~2.3 and ~3.3 days after.
  ('2.3 days after new', _d(2026, 8, 15, 0, 0), MoonPhase.waxingCrescent),
  ('3.3 days after new', _d(2026, 8, 16, 0, 0), MoonPhase.waxingCrescent),
  // Full moon 2026-08-28 04:18; two days later must not still say full.
  ('2 days after full', _d(2026, 8, 30, 4, 0), MoonPhase.waningGibbous),
  // Two days before full must not say full either.
  ('2 days before full', _d(2026, 8, 26, 4, 0), MoonPhase.waxingGibbous),
];

DateTime _d(int y, int m, int d, int h, int min) =>
    DateTime.utc(y, m, d, h, min);

void main() {
  group('MoonPhaseCalculator', () {
    test('names every USNO reference event correctly', () {
      for (final (label, moment, expected) in _usnoEvents) {
        expect(
          MoonPhaseCalculator.phaseFor(moment),
          expected,
          reason: '$label at $moment',
        );
      }
    });

    test('names dates near band boundaries correctly', () {
      for (final (label, moment, expected) in _boundaryCases) {
        expect(
          MoonPhaseCalculator.phaseFor(moment),
          expected,
          reason: '$label ($moment)',
        );
      }
    });

    test('elongation model is accurate to well under an hour', () {
      // Each USNO event sits at an exact quarter of the cycle. Measure
      // how far the model puts it from that quarter.
      const quarters = [0.0, 0.25, 0.5, 0.75, 1.0];

      for (final (label, moment, _) in _usnoEvents) {
        final position = MoonPhaseCalculator.readingFor(moment).cyclePosition;
        final errorDays = quarters
            .map(
              (q) => (position - q).abs() * MoonPhaseCalculator.synodicMonth,
            )
            .reduce((a, b) => a < b ? a : b);

        expect(
          errorDays,
          lessThan(0.05),
          reason: '$label was $errorDays days out',
        );
      }
    });

    test('illumination is ~0 at new moon and ~1 at full moon', () {
      final newMoon = MoonPhaseCalculator.readingFor(_d(2026, 1, 18, 19, 52));
      final fullMoon = MoonPhaseCalculator.readingFor(_d(2026, 1, 3, 10, 3));

      expect(newMoon.illumination, lessThan(0.01));
      expect(fullMoon.illumination, greaterThan(0.99));
    });

    test('a full cycle returns to the same phase', () {
      final start = _d(2026, 1, 18, 19, 52);
      final later = start.add(
        const Duration(
          days: 29,
          hours: 12,
          minutes: 44,
        ),
      );

      expect(MoonPhaseCalculator.phaseFor(later), MoonPhase.newMoon);
    });

    test('cyclePosition is always in [0, 1) even before the epoch', () {
      // 1969 is well before the year-2000 reference new moon, so this
      // exercises the negative-modulo path.
      final reading = MoonPhaseCalculator.readingFor(_d(1969, 7, 20, 20, 17));

      expect(reading.cyclePosition, greaterThanOrEqualTo(0));
      expect(reading.cyclePosition, lessThan(1));
      expect(reading.illumination, inInclusiveRange(0, 1));
    });

    test('waxing flags match the first half of the cycle', () {
      expect(MoonPhase.waxingCrescent.isWaxing, isTrue);
      expect(MoonPhase.firstQuarter.isWaxing, isTrue);
      expect(MoonPhase.waningGibbous.isWaxing, isFalse);
      expect(MoonPhase.newMoon.isWaxing, isFalse);
    });

    test('only new and full are ritual moons', () {
      final ritual = MoonPhase.values.where((p) => p.isRitualMoon).toSet();
      expect(ritual, {MoonPhase.newMoon, MoonPhase.fullMoon});
    });

    test('nextOccurrence finds the coming full moon', () {
      final next = MoonPhaseCalculator.nextOccurrence(
        MoonPhase.fullMoon,
        _d(2026, 1, 20, 0, 0),
      );

      // USNO: the full moon after 2026-01-20 is 2026-02-01 22:09 UTC.
      expect(next.year, 2026);
      expect(next.month, 2);
      expect(next.day, inInclusiveRange(1, 2));
    });

    test('nextOccurrence returns today when today already matches', () {
      final onNewMoon = _d(2026, 1, 18, 19, 52);
      final next = MoonPhaseCalculator.nextOccurrence(
        MoonPhase.newMoon,
        onNewMoon,
      );

      expect(next.day, 18);
    });
  });
}
