import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/energy_check_in.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/services/energy_pattern.dart';
import 'package:sanctum/src/domain/services/moon_phase_calculator.dart';
import '../support/copy.dart';

EnergyCheckIn checkIn(DateTime day, EnergyLevel level) => EnergyCheckIn(
  id: day.millisecondsSinceEpoch,
  recordedAt: day,
  level: level,
);

/// Dates that genuinely fall in [phase], so the fixtures cannot drift
/// away from the real lunar calendar.
List<DateTime> daysIn(MoonPhase phase, {required int count}) {
  final found = <DateTime>[];
  var cursor = DateTime(2026);
  while (found.length < count) {
    if (MoonPhaseCalculator.phaseFor(cursor) == phase) found.add(cursor);
    cursor = cursor.add(const Duration(days: 1));
  }
  return found;
}

final CopyBook _copy = loadEnglishCopy();

void main() {
  final today = DateTime(2026, 12, 31);

  group('the strip', () {
    test('is a fixed window, oldest first', () {
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: const [],
        today: today,
      );
      expect(
        pattern.days,
        hasLength(EnergyPatternCalculator.windowDays),
      );
      expect(pattern.days.every((day) => day == null), isTrue);
    });

    test('leaves gaps as gaps', () {
      // Missing days must read as missing. Closing the gap would imply
      // the user checked in when they did not.
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: [checkIn(today, EnergyLevel.radiant)],
        today: today,
      );
      expect(pattern.days.last, EnergyLevel.radiant);
      expect(pattern.days.where((day) => day == null), hasLength(29));
    });

    test('ignores anything older than the window', () {
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: [
          checkIn(today.subtract(const Duration(days: 400)), EnergyLevel.low),
        ],
        today: today,
      );
      expect(pattern.days.every((day) => day == null), isTrue);
      expect(
        pattern.total,
        1,
        reason: 'the strip is windowed, the totals are not',
      );
    });
  });

  group('findings', () {
    test('say nothing with no history', () {
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: const [],
        today: today,
      );
      expect(pattern.hasFinding, isFalse);
    });

    test('say nothing until a phase has enough check-ins', () {
      // Two data points is not a pattern, and claiming otherwise is how
      // an app that says it knows you gets caught not knowing you.
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: [
          for (final day in daysIn(MoonPhase.fullMoon, count: 2))
            checkIn(day, EnergyLevel.depleted),
          for (final day in daysIn(MoonPhase.newMoon, count: 2))
            checkIn(day, EnergyLevel.radiant),
        ],
        today: today,
      );
      expect(pattern.hasFinding, isFalse);
    });

    test('say nothing when the difference is small', () {
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: [
          for (final day in daysIn(MoonPhase.fullMoon, count: 4))
            checkIn(day, EnergyLevel.steady),
          for (final day in daysIn(MoonPhase.newMoon, count: 4))
            checkIn(day, EnergyLevel.steady),
        ],
        today: today,
      );
      expect(pattern.hasFinding, isFalse);
    });

    test('name the phases once the pattern is real', () {
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: [
          for (final day in daysIn(MoonPhase.fullMoon, count: 5))
            checkIn(day, EnergyLevel.depleted),
          for (final day in daysIn(MoonPhase.newMoon, count: 5))
            checkIn(day, EnergyLevel.radiant),
        ],
        today: today,
      );

      expect(pattern.hasFinding, isTrue);
      expect(pattern.finding, contains('full moon'));
      expect(pattern.finding, contains('new moon'));
    });

    test('report the lower phase first', () {
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: [
          for (final day in daysIn(MoonPhase.newMoon, count: 5))
            checkIn(day, EnergyLevel.depleted),
          for (final day in daysIn(MoonPhase.fullMoon, count: 5))
            checkIn(day, EnergyLevel.radiant),
        ],
        today: today,
      );
      expect(pattern.finding, startsWith('Your energy runs lowest'));
      expect(
        pattern.finding!.indexOf('new moon'),
        lessThan(pattern.finding!.indexOf('full moon')),
      );
    });
  });

  group('averages', () {
    test('are means of the levels logged in each phase', () {
      final full = daysIn(MoonPhase.fullMoon, count: 2);
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: [
          checkIn(full[0], EnergyLevel.depleted),
          checkIn(full[1], EnergyLevel.radiant),
        ],
        today: today,
      );
      expect(pattern.averageByPhase[MoonPhase.fullMoon], closeTo(3, 1e-9));
    });

    test('only include phases that were actually logged', () {
      final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
        checkIns: [
          for (final day in daysIn(MoonPhase.fullMoon, count: 3))
            checkIn(day, EnergyLevel.low),
        ],
        today: today,
      );
      expect(pattern.averageByPhase.keys, [MoonPhase.fullMoon]);
    });
  });

  test('one check-in per day wins, not the first of the day', () {
    final pattern = EnergyPatternCalculator.analyse(
    copy: _copy,
      checkIns: [
        checkIn(DateTime(2026, 12, 31, 9), EnergyLevel.low),
        checkIn(DateTime(2026, 12, 31, 21), EnergyLevel.radiant),
      ],
      today: today,
    );
    expect(pattern.days.last, EnergyLevel.radiant);
  });
}
