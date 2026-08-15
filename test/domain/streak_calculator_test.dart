import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/streak_calculator.dart';

void main() {
  final today = DateTime(2026, 8, 15);
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  group('StreakCalculator', () {
    test('an empty history is an empty streak', () {
      final summary = StreakCalculator.summarise(
        activeDates: const [],
        today: today,
      );

      expect(summary.current, 0);
      expect(summary.longest, 0);
      expect(summary.completedToday, isFalse);
      expect(summary.lastActiveDate, isNull);
    });

    test('counts a run ending today', () {
      final summary = StreakCalculator.summarise(
        activeDates: [daysAgo(2), daysAgo(1), today],
        today: today,
      );

      expect(summary.current, 3);
      expect(summary.completedToday, isTrue);
      expect(summary.isAtRisk, isFalse);
    });

    test('keeps the streak alive when only yesterday is done', () {
      final summary = StreakCalculator.summarise(
        activeDates: [daysAgo(3), daysAgo(2), daysAgo(1)],
        today: today,
      );

      // The whole point: not yet practising *today* must not read as a
      // broken streak at 9am.
      expect(summary.current, 3);
      expect(summary.completedToday, isFalse);
      expect(summary.isAtRisk, isTrue);
    });

    test('breaks when neither today nor yesterday is done', () {
      final summary = StreakCalculator.summarise(
        activeDates: [daysAgo(4), daysAgo(3), daysAgo(2)],
        today: today,
      );

      expect(summary.current, 0);
      expect(summary.isAtRisk, isFalse);
      // History is still remembered.
      expect(summary.longest, 3);
    });

    test('longest survives a broken current streak', () {
      final summary = StreakCalculator.summarise(
        activeDates: [
          daysAgo(20),
          daysAgo(19),
          daysAgo(18),
          daysAgo(17),
          daysAgo(16),
          daysAgo(1),
          today,
        ],
        today: today,
      );

      expect(summary.current, 2);
      expect(summary.longest, 5);
    });

    test('a current run longer than any past run becomes the longest', () {
      final summary = StreakCalculator.summarise(
        activeDates: [
          daysAgo(30),
          daysAgo(29),
          daysAgo(3),
          daysAgo(2),
          daysAgo(1),
          today,
        ],
        today: today,
      );

      expect(summary.current, 4);
      expect(summary.longest, 4);
    });

    test('ignores duplicates and times of day', () {
      final summary = StreakCalculator.summarise(
        activeDates: [
          DateTime(2026, 8, 15, 7, 15),
          DateTime(2026, 8, 15, 21, 40),
          DateTime(2026, 8, 14, 12),
          DateTime(2026, 8, 14, 12),
        ],
        today: today,
      );

      expect(summary.current, 2);
      expect(summary.longest, 2);
    });

    test('accepts unsorted input', () {
      final summary = StreakCalculator.summarise(
        activeDates: [today, daysAgo(2), daysAgo(1)],
        today: today,
      );

      expect(summary.current, 3);
    });

    test('a single day today is a streak of one', () {
      final summary = StreakCalculator.summarise(
        activeDates: [today],
        today: today,
      );

      expect(summary.current, 1);
      expect(summary.longest, 1);
      expect(summary.completedToday, isTrue);
    });

    test('survives a daylight-saving boundary', () {
      // US DST begins 2026-03-08. A naive Duration-based day count makes
      // this run look broken.
      final dstToday = DateTime(2026, 3, 9);
      final summary = StreakCalculator.summarise(
        activeDates: [
          DateTime(2026, 3, 7),
          DateTime(2026, 3, 8),
          dstToday,
        ],
        today: dstToday,
      );

      expect(summary.current, 3);
      expect(summary.longest, 3);
    });

    test('reports the most recent active day', () {
      final summary = StreakCalculator.summarise(
        activeDates: [daysAgo(9), daysAgo(1)],
        today: today,
      );

      expect(summary.lastActiveDate, daysAgo(1));
    });
  });
}
