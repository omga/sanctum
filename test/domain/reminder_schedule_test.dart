import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/reminder_schedule.dart';

void main() {
  group('hours', () {
    test('map every answer the quiz can produce', () {
      // These ids come from onboarding_quiz.json. A rename there without
      // one here silently drops everyone back to the default.
      for (final id in ['morning', 'midday', 'evening']) {
        expect(ReminderSchedule.hours[id], isNotNull, reason: id);
      }
    });

    test('fall back rather than throwing on an unknown answer', () {
      expect(ReminderSchedule.hourFor(null), ReminderSchedule.defaultHour);
      expect(
        ReminderSchedule.hourFor('whenever'),
        ReminderSchedule.defaultHour,
      );
    });

    test('never land in the middle of the night', () {
      for (final hour in ReminderSchedule.hours.values) {
        expect(hour, inInclusiveRange(7, 21));
      }
    });
  });

  group('upcoming', () {
    test('starts today when the hour is still ahead', () {
      final slots = ReminderSchedule.upcoming(
        from: DateTime(2026, 8, 16, 6, 30),
        hour: 8,
      );
      expect(slots.first, DateTime(2026, 8, 16, 8));
    });

    test('skips to tomorrow when the hour has passed', () {
      // Otherwise finishing onboarding at 9am fires a notification
      // instantly, or the platform drops it — both wrong.
      final slots = ReminderSchedule.upcoming(
        from: DateTime(2026, 8, 16, 9),
        hour: 8,
      );
      expect(slots.first, DateTime(2026, 8, 17, 8));
    });

    test('skips to tomorrow when it is exactly the hour', () {
      final slots = ReminderSchedule.upcoming(
        from: DateTime(2026, 8, 16, 8),
        hour: 8,
      );
      expect(slots.first, DateTime(2026, 8, 17, 8));
    });

    test('returns consecutive days at the same hour', () {
      final slots = ReminderSchedule.upcoming(
        from: DateTime(2026, 8, 16, 6),
        hour: 13,
      );
      expect(slots, hasLength(ReminderSchedule.horizonDays));
      for (var i = 1; i < slots.length; i++) {
        expect(slots[i].difference(slots[i - 1]).inDays, 1);
        expect(slots[i].hour, 13);
      }
    });

    test('rolls over a month boundary', () {
      final slots = ReminderSchedule.upcoming(
        from: DateTime(2026, 1, 29, 6),
        hour: 8,
      );
      expect(slots.last, DateTime(2026, 2, 4, 8));
    });

    test('rolls over a leap day', () {
      final slots = ReminderSchedule.upcoming(
        from: DateTime(2028, 2, 27, 6),
        hour: 8,
        count: 4,
      );
      expect(slots[1], DateTime(2028, 2, 28, 8));
      expect(slots[2], DateTime(2028, 2, 29, 8));
      expect(slots[3], DateTime(2028, 3, 1, 8));
    });

    test('is always strictly in the future', () {
      final now = DateTime(2026, 8, 16, 12, 1);
      for (final hour in ReminderSchedule.hours.values) {
        for (final slot in ReminderSchedule.upcoming(
          from: now,
          hour: hour,
        )) {
          expect(slot.isAfter(now), isTrue, reason: '$hour -> $slot');
        }
      }
    });
  });
}
