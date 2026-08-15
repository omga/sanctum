import 'package:sanctum/src/domain/models/zodiac_sign.dart';

/// Sun sign from a birth date.
///
/// ## Why compute rather than fake
///
/// The payoff screen after the quiz is where a user decides whether this
/// app knows anything about them. Showing something derived from what
/// they actually typed — their sign, its element — costs nothing and is
/// true. A spinner that says "analysing your chart" for three seconds
/// and then shows generic copy is the same screen with the trust removed.
///
/// These are the conventional tropical date ranges, which is what every
/// consumer astrology product uses. They drift slightly against the real
/// solar position over centuries; that is a property of the convention,
/// not a bug here.
abstract final class Zodiac {
  /// Inclusive start of each sign, as (month, day).
  static const _boundaries = <(int, int, ZodiacSign)>[
    (1, 20, ZodiacSign.aquarius),
    (2, 19, ZodiacSign.pisces),
    (3, 21, ZodiacSign.aries),
    (4, 20, ZodiacSign.taurus),
    (5, 21, ZodiacSign.gemini),
    (6, 21, ZodiacSign.cancer),
    (7, 23, ZodiacSign.leo),
    (8, 23, ZodiacSign.virgo),
    (9, 23, ZodiacSign.libra),
    (10, 23, ZodiacSign.scorpio),
    (11, 22, ZodiacSign.sagittarius),
    (12, 22, ZodiacSign.capricorn),
  ];

  /// The sun sign for [date].
  static ZodiacSign signFor(DateTime date) {
    // Walk backwards to the first boundary at or before this date. Dates
    // before 20 January fall through to Capricorn, which begins in the
    // previous December — the wrap-around case that off-by-one bugs love.
    for (final (month, day, sign) in _boundaries.reversed) {
      if (date.month > month || (date.month == month && date.day >= day)) {
        return sign;
      }
    }
    return ZodiacSign.capricorn;
  }
}
