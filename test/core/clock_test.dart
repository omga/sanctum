import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/time/clock.dart';

void main() {
  group('FixedClock', () {
    test('reports the instant it was given', () {
      final clock = FixedClock(DateTime(2026, 3, 14, 9, 30));

      expect(clock.now(), DateTime(2026, 3, 14, 9, 30));
      expect(clock.today(), DateTime(2026, 3, 14));
    });

    test('advance moves time forward', () {
      final clock = FixedClock(DateTime(2026, 3, 14, 23))
        ..advance(const Duration(hours: 2));

      expect(clock.today(), DateTime(2026, 3, 15));
    });
  });

  group('date helpers', () {
    test('dateOnly strips the time component', () {
      expect(
        DateTime(2026, 8, 15, 17, 45, 12, 300).dateOnly,
        DateTime(2026, 8, 15),
      );
    });

    test('isSameDayAs ignores time of day', () {
      expect(
        DateTime(2026, 8, 15, 1).isSameDayAs(DateTime(2026, 8, 15, 23)),
        isTrue,
      );
      expect(
        DateTime(2026, 8, 15).isSameDayAs(DateTime(2026, 8, 16)),
        isFalse,
      );
    });

    test('calendarDaysUntil counts whole days', () {
      expect(
        DateTime(2026, 8, 15).calendarDaysUntil(DateTime(2026, 8, 18)),
        3,
      );
      expect(
        DateTime(2026, 8, 18).calendarDaysUntil(DateTime(2026, 8, 15)),
        -3,
      );
    });

    test('calendarDaysUntil survives a daylight-saving transition', () {
      // US DST starts 2026-03-08. A naive difference().inDays across this
      // boundary returns 0 for a real 1-day gap, which silently breaks
      // streak logic twice a year.
      expect(
        DateTime(2026, 3, 7).calendarDaysUntil(DateTime(2026, 3, 8)),
        1,
      );
      expect(
        DateTime(2026, 3, 7).calendarDaysUntil(DateTime(2026, 3, 9)),
        2,
      );
    });
  });
}
