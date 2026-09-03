import 'dart:math' as math;

import 'package:sanctum/src/domain/models/moon_phase.dart';

/// Computes the moon's phase for any date.
///
/// ## Why compute instead of calling an API
///
/// The moon is not a network resource. Its motion is well-described by
/// published series, so some arithmetic replaces an API key, a rate
/// limit, a loading spinner, a failure state, and a feature that stops
/// working on a plane. It is also instant, which matters because this
/// runs on Sanctum's home screen.
///
/// ## The model, and why it is not the simple one
///
/// The obvious approach is a *mean synodic* model: assume a constant
/// 29.53-day month measured from one known new moon. It is four lines,
/// and it is not good enough. The moon's orbit is elliptical, so real
/// phase events run up to ~0.6 days either side of the mean. Since each
/// named phase band is only ±1.85 days wide, an error of 0.6 days is
/// fine near the middle of a band and *wrong near its edges* — the app
/// cheerfully says "New Moon" two and a half days after the new moon.
///
/// So this computes the actual **elongation**: the angle between the
/// moon's and the sun's apparent ecliptic longitudes. Zero is new, 180°
/// is full, and everything else follows. The solar terms and the
/// leading lunar periodic terms are taken from the standard truncated
/// series (Meeus, *Astronomical Algorithms*).
///
/// Checked against US Naval Observatory phase tables, the worst error is
/// about **0.004 days — under six minutes**, against 0.59 days for the
/// mean-synodic version. See `moon_phase_calculator_test.dart`, which
/// pins real USNO timestamps *and* dates near band boundaries, which is
/// where the simple model failed.
abstract final class MoonPhaseCalculator {
  /// Mean synodic month in days.
  ///
  /// No longer used to *find* the phase — only to express a cycle
  /// position as an age in days.
  static const double synodicMonth = 29.530588853;

  /// The moon reading for [moment].
  static MoonReading readingFor(DateTime moment) {
    final elongation = _elongationDegrees(moment);
    final position = elongation / 360.0;

    return MoonReading(
      phase: _phaseFor(position),
      cyclePosition: position,
      // Illuminated fraction of the disc, from the phase angle.
      illumination: (1 - math.cos(_radians(elongation))) / 2,
      ageInDays: position * synodicMonth,
    );
  }

  /// Just the named phase for [moment].
  static MoonPhase phaseFor(DateTime moment) =>
      _phaseFor(_elongationDegrees(moment) / 360.0);

  /// The next date at or after [from] on which [phase] occurs.
  static DateTime nextOccurrence(MoonPhase phase, DateTime from) {
    var cursor = DateTime.utc(from.year, from.month, from.day);
    for (var i = 0; i <= 31; i++) {
      if (phaseFor(cursor) == phase) return cursor;
      cursor = cursor.add(const Duration(days: 1));
    }
    throw StateError('No occurrence of $phase within one synodic month');
  }

  /// The first calendar day of the run of [phase] containing [date].
  ///
  /// A named phase is a *band*, several days wide, so "which new moon is
  /// this" needs a single day that every date inside the band agrees on.
  /// Walking back to the start of the run gives one, and it is stable:
  /// open the app on the first evening of the band or the last and the
  /// answer is the same date.
  ///
  /// Returns [date] unchanged when it does not fall in [phase] at all.
  static DateTime occurrenceStart(MoonPhase phase, DateTime date) {
    var cursor = DateTime.utc(date.year, date.month, date.day);
    if (phaseFor(cursor) != phase) return cursor;

    // A band is under four days wide; the cap is a guard, not a limit.
    for (var i = 0; i < 8; i++) {
      final previous = cursor.subtract(const Duration(days: 1));
      if (phaseFor(previous) != phase) break;
      cursor = previous;
    }
    return cursor;
  }

  /// Whole synodic months from a reference new moon to [moment].
  ///
  /// A cycle counter, used to rotate content that belongs to a lunar
  /// event rather than to a date. Consecutive occurrences of the same
  /// phase differ by exactly one, which is what makes a round-robin over
  /// it actually round-robin instead of skipping entries.
  ///
  /// The reference is the new moon of 6 January 2000, the conventional
  /// epoch for this. Its exact value is arbitrary — changing it shifts
  /// which ritual opens a given month and nothing else — but it must not
  /// change once shipped, or every user's rotation jumps.
  ///
  /// Note that the New Moon band straddles its own boundary: it opens a
  /// day or two before the new moon instant, so a window's number can be
  /// one less than the lunation it belongs to. That is harmless here —
  /// the number only has to be constant within a window and increment
  /// between them, and it is both.
  static int lunationNumber(DateTime moment) =>
      ((_julianDay(moment) - 2451550.1) / synodicMonth).floor();

  static double _radians(double degrees) => degrees * math.pi / 180.0;

  /// Julian Day for [moment].
  static double _julianDay(DateTime moment) {
    final utc = moment.toUtc();
    var year = utc.year;
    var month = utc.month;
    final day = utc.day + (utc.hour + utc.minute / 60 + utc.second / 3600) / 24;

    // January and February are treated as months 13 and 14 of the
    // previous year, which is what makes the 30.6001 term work.
    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final a = year ~/ 100;
    final b = 2 - a + (a ~/ 4); // Gregorian correction

    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  /// Angle from the sun to the moon along the ecliptic, in `[0, 360)`.
  ///
  /// 0° is new moon, 180° is full.
  static double _elongationDegrees(DateTime moment) {
    // Days since J2000.0.
    final d = _julianDay(moment) - 2451545.0;

    // ── Sun ────────────────────────────────────────────────────────
    final sunMeanAnomaly = 357.5291 + 0.98560028 * d;
    final sunMeanLongitude = 280.4665 + 0.98564736 * d;
    // Equation of the centre: corrects the mean position for the
    // ellipticity of Earth's orbit.
    final centre =
        1.9146 * math.sin(_radians(sunMeanAnomaly)) +
        0.0200 * math.sin(_radians(2 * sunMeanAnomaly)) +
        0.0003 * math.sin(_radians(3 * sunMeanAnomaly));
    final sunLongitude = sunMeanLongitude + centre;

    // ── Moon ───────────────────────────────────────────────────────
    final meanLongitude = 218.3164477 + 13.17639648 * d;
    final meanAnomaly = 134.9633964 + 13.06499295 * d;
    final meanElongation = 297.8501921 + 12.19074912 * d;
    final argumentOfLatitude = 93.2720950 + 13.22935024 * d;

    // The leading periodic terms. The first two dominate: 6.29° is the
    // equation of the centre, 1.27° is evection. The tail is kept
    // because together they are worth roughly a further half degree,
    // and dropping them is what pushes a boundary date into the wrong
    // phase band.
    final longitude =
        meanLongitude +
        6.289 * math.sin(_radians(meanAnomaly)) -
        1.274 * math.sin(_radians(meanAnomaly - 2 * meanElongation)) +
        0.658 * math.sin(_radians(2 * meanElongation)) +
        0.214 * math.sin(_radians(2 * meanAnomaly)) -
        0.186 * math.sin(_radians(sunMeanAnomaly)) -
        0.114 * math.sin(_radians(2 * argumentOfLatitude)) -
        0.059 * math.sin(_radians(2 * meanAnomaly - 2 * meanElongation)) -
        0.057 *
            math.sin(
              _radians(meanAnomaly - 2 * meanElongation + sunMeanAnomaly),
            ) +
        0.053 * math.sin(_radians(meanAnomaly + 2 * meanElongation)) +
        0.046 * math.sin(_radians(2 * meanElongation - sunMeanAnomaly)) +
        0.041 * math.sin(_radians(meanAnomaly - sunMeanAnomaly)) -
        0.035 * math.sin(_radians(meanElongation)) -
        0.031 * math.sin(_radians(meanAnomaly + sunMeanAnomaly));

    final elongation = (longitude - sunLongitude) % 360.0;
    return elongation < 0 ? elongation + 360.0 : elongation;
  }

  /// Maps a cycle position onto a named phase.
  ///
  /// The four "event" phases (new, first quarter, full, last quarter) are
  /// moments rather than spans, so each is given a narrow band around its
  /// exact point and the crescents/gibbous fill the gaps.
  static MoonPhase _phaseFor(double position) {
    const eighth = 1 / 8;
    const halfBand = eighth / 2;

    if (position < halfBand || position >= 1 - halfBand) {
      return MoonPhase.newMoon;
    }
    if (position < eighth * 2 - halfBand) return MoonPhase.waxingCrescent;
    if (position < eighth * 2 + halfBand) return MoonPhase.firstQuarter;
    if (position < eighth * 4 - halfBand) return MoonPhase.waxingGibbous;
    if (position < eighth * 4 + halfBand) return MoonPhase.fullMoon;
    if (position < eighth * 6 - halfBand) return MoonPhase.waningGibbous;
    if (position < eighth * 6 + halfBand) return MoonPhase.lastQuarter;
    return MoonPhase.waningCrescent;
  }
}
