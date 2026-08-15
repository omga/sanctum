import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';

void main() {
  group('Zodiac', () {
    test('maps the middle of each sign', () {
      final checks = <DateTime, ZodiacSign>{
        DateTime(1990, 4, 1): ZodiacSign.aries,
        DateTime(1990, 5, 1): ZodiacSign.taurus,
        DateTime(1990, 6, 1): ZodiacSign.gemini,
        DateTime(1990, 7, 1): ZodiacSign.cancer,
        DateTime(1990, 8, 1): ZodiacSign.leo,
        DateTime(1990, 9, 1): ZodiacSign.virgo,
        DateTime(1990, 10, 1): ZodiacSign.libra,
        DateTime(1990, 11, 1): ZodiacSign.scorpio,
        DateTime(1990, 12, 1): ZodiacSign.sagittarius,
        DateTime(1990, 1, 5): ZodiacSign.capricorn,
        DateTime(1990, 2, 1): ZodiacSign.aquarius,
        DateTime(1990, 3, 1): ZodiacSign.pisces,
      };

      for (final entry in checks.entries) {
        expect(Zodiac.signFor(entry.key), entry.value, reason: '${entry.key}');
      }
    });

    test('handles the first and last day of every sign', () {
      // Boundaries are where these implementations break.
      final edges = <DateTime, ZodiacSign>{
        DateTime(1990, 3, 21): ZodiacSign.aries,
        DateTime(1990, 4, 19): ZodiacSign.aries,
        DateTime(1990, 4, 20): ZodiacSign.taurus,
        DateTime(1990, 5, 20): ZodiacSign.taurus,
        DateTime(1990, 7, 22): ZodiacSign.cancer,
        DateTime(1990, 7, 23): ZodiacSign.leo,
        DateTime(1990, 11, 21): ZodiacSign.scorpio,
        DateTime(1990, 11, 22): ZodiacSign.sagittarius,
      };

      for (final entry in edges.entries) {
        expect(Zodiac.signFor(entry.key), entry.value, reason: '${entry.key}');
      }
    });

    test('wraps Capricorn across the new year', () {
      // The classic off-by-one: Capricorn starts in December and ends in
      // January, so it is the only sign spanning a year boundary.
      expect(Zodiac.signFor(DateTime(1990, 12, 22)), ZodiacSign.capricorn);
      expect(Zodiac.signFor(DateTime(1990, 12, 31)), ZodiacSign.capricorn);
      expect(Zodiac.signFor(DateTime(1991, 1, 1)), ZodiacSign.capricorn);
      expect(Zodiac.signFor(DateTime(1991, 1, 19)), ZodiacSign.capricorn);
      expect(Zodiac.signFor(DateTime(1991, 1, 20)), ZodiacSign.aquarius);
      expect(Zodiac.signFor(DateTime(1990, 12, 21)), ZodiacSign.sagittarius);
    });

    test('every day of a year resolves to a sign', () {
      var date = DateTime(2024);
      while (date.year == 2024) {
        expect(() => Zodiac.signFor(date), returnsNormally, reason: '$date');
        date = date.add(const Duration(days: 1));
      }
    });

    test('elements are distributed three per element', () {
      for (final element in ZodiacElement.values) {
        final count = ZodiacSign.values
            .where((s) => s.element == element)
            .length;
        expect(count, 3, reason: element.displayName);
      }
    });
  });
}
