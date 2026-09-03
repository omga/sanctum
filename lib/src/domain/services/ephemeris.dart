import 'dart:math' as math;

import 'package:sanctum/src/domain/models/planet.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';

/// Where the planets actually were.
///
/// ## Why we compute this instead of using a library
///
/// The obvious dependency is Swiss Ephemeris. Its Dart binding is
/// **AGPL-3.0** unless you buy a professional licence from Astrodienst,
/// and AGPL in a closed-source app means publishing the app's source. It
/// also ships ~20 MB of data files.
///
/// We do not need any of that. Swiss Ephemeris resolves arcseconds; we
/// need to know which *sign* a planet is in, which is half a degree of
/// precision. Keplerian elements with linear rates — the standard JPL
/// approximation, good to roughly an arcminute for these bodies between
/// 1800 and 2050 — clear that bar by two orders of magnitude, in one
/// file, with no licence and no assets.
///
/// ## Why only these four bodies
///
/// A birth *date* with no time constrains a body only as tightly as that
/// body is slow. The Moon moves 13° a day and changes sign every 2.3
/// days, so its sign genuinely cannot be known without a birth time and
/// we do not pretend otherwise. Venus and Mars move under 1.25° a day,
/// Saturn takes two and a half years to cross a sign — all three are
/// safe from a date alone, and they are exactly the bodies the readings
/// need: Venus and Mars for attraction, Saturn for the power dynamic.
abstract final class Ephemeris {
  /// The ecliptic longitude of [planet], in tropical degrees `[0, 360)`.
  ///
  /// [timeOfDay] is the offset from local midnight when it is known. Left
  /// null, the instant is taken as noon — see [julianDay].
  static double longitudeOf(
    Planet planet,
    DateTime date, {
    Duration? timeOfDay,
  }) => switch (planet) {
    Planet.sun => sunLongitude(date, timeOfDay: timeOfDay),
    Planet.mercury => _geocentric(_mercury, date, timeOfDay),
    Planet.venus => _geocentric(_venus, date, timeOfDay),
    Planet.mars => _geocentric(_mars, date, timeOfDay),
    Planet.jupiter => _geocentric(_jupiter, date, timeOfDay),
    Planet.saturn => _geocentric(_saturn, date, timeOfDay),
  };

  /// Whether [planet] appears to be moving backwards on [date].
  ///
  /// Retrograde is an *apparent* motion — the planet does not reverse,
  /// Earth overtakes it — so the honest test is simply whether its
  /// geocentric longitude is decreasing. Comparing across two days
  /// rather than one keeps a station (the near-stationary turn) from
  /// flickering.
  ///
  /// The Sun is never retrograde, which falls out of this for free.
  static bool isRetrograde(Planet planet, DateTime date) {
    final before = longitudeOf(planet, date.subtract(const Duration(days: 1)));
    final after = longitudeOf(planet, date.add(const Duration(days: 1)));
    var motion = after - before;
    if (motion > 180) motion -= 360;
    if (motion < -180) motion += 360;
    return motion < 0;
  }

  /// The ecliptic longitude of the Sun, in tropical degrees `[0, 360)`.
  static double sunLongitude(DateTime date, {Duration? timeOfDay}) {
    final t = _centuries(date, timeOfDay);
    final earth = _heliocentric(_earth, t);
    // The Sun seen from Earth is Earth seen from the Sun, reversed.
    return _tropical(math.atan2(-earth.y, -earth.x), t);
  }

  /// The ecliptic longitude of Venus, in tropical degrees `[0, 360)`.
  static double venusLongitude(DateTime date, {Duration? timeOfDay}) =>
      _geocentric(_venus, date, timeOfDay);

  /// The ecliptic longitude of Mars, in tropical degrees `[0, 360)`.
  static double marsLongitude(DateTime date, {Duration? timeOfDay}) =>
      _geocentric(_mars, date, timeOfDay);

  /// The ecliptic longitude of Saturn, in tropical degrees `[0, 360)`.
  static double saturnLongitude(DateTime date, {Duration? timeOfDay}) =>
      _geocentric(_saturn, date, timeOfDay);

  /// The ecliptic longitude of Mercury, in tropical degrees `[0, 360)`.
  static double mercuryLongitude(DateTime date, {Duration? timeOfDay}) =>
      _geocentric(_mercury, date, timeOfDay);

  /// The ecliptic longitude of Jupiter, in tropical degrees `[0, 360)`.
  static double jupiterLongitude(DateTime date, {Duration? timeOfDay}) =>
      _geocentric(_jupiter, date, timeOfDay);

  /// The ecliptic longitude of the Moon, in tropical degrees `[0, 360)`.
  ///
  /// ## Why the Moon is the only body that needs [timeOfDay]
  ///
  /// Everything else here is deliberately slow: Venus and Mars move
  /// under 1.25° a day and Saturn takes two and a half years to cross a
  /// sign, so a bare birth date pins them well enough. The Moon moves
  /// **13° a day** and changes sign every 2.3 days. Without a birth time
  /// its sign is very nearly a coin toss, which is exactly why this file
  /// refused to compute it for so long — and why supplying a time is the
  /// one thing that makes it honest to start.
  ///
  /// Callers that have no time should not call this. It returns the
  /// noon position, which is a real position for a real instant, but it
  /// carries a ±6.5° uncertainty that nothing downstream can see.
  ///
  /// ## Where the series comes from
  ///
  /// These are the same leading periodic terms `MoonPhaseCalculator`
  /// already uses to find the phase — Meeus' truncated series — lifted
  /// here so both surfaces read one implementation. That code is pinned
  /// against US Naval Observatory phase timestamps to within 0.004 days,
  /// which is the strongest validation any body in this file has.
  ///
  /// Unlike the planets, no precession correction is applied: the lunar
  /// arguments below are already referred to the mean equinox *of date*,
  /// so the result is tropical as it stands. Running it through
  /// [_tropical] would double-count. Accuracy is a few tenths of a
  /// degree — ample for a sign, and ample for the harmonic aspect
  /// functions, which are smooth and have no edges to fall off.
  static double moonLongitude(DateTime date, {Duration? timeOfDay}) {
    final d = julianDay(date, timeOfDay: timeOfDay) - 2451545.0;

    final sunMeanAnomaly = 357.5291 + 0.98560028 * d;
    final meanLongitude = 218.3164477 + 13.17639648 * d;
    final meanAnomaly = 134.9633964 + 13.06499295 * d;
    final meanElongation = 297.8501921 + 12.19074912 * d;
    final argumentOfLatitude = 93.2720950 + 13.22935024 * d;

    // The first two terms dominate: 6.29° is the equation of the centre
    // and 1.27° is evection. The tail is worth about a further half
    // degree between them.
    final longitude =
        meanLongitude +
        6.289 * math.sin(_rad(meanAnomaly)) -
        1.274 * math.sin(_rad(meanAnomaly - 2 * meanElongation)) +
        0.658 * math.sin(_rad(2 * meanElongation)) +
        0.214 * math.sin(_rad(2 * meanAnomaly)) -
        0.186 * math.sin(_rad(sunMeanAnomaly)) -
        0.114 * math.sin(_rad(2 * argumentOfLatitude)) -
        0.059 * math.sin(_rad(2 * meanAnomaly - 2 * meanElongation)) -
        0.057 *
            math.sin(
              _rad(meanAnomaly - 2 * meanElongation + sunMeanAnomaly),
            ) +
        0.053 * math.sin(_rad(meanAnomaly + 2 * meanElongation)) +
        0.046 * math.sin(_rad(2 * meanElongation - sunMeanAnomaly)) +
        0.041 * math.sin(_rad(meanAnomaly - sunMeanAnomaly)) -
        0.035 * math.sin(_rad(meanElongation)) -
        0.031 * math.sin(_rad(meanAnomaly + sunMeanAnomaly));

    return _wrap(longitude);
  }

  /// The sign occupying [longitude].
  ///
  /// The tropical zodiac starts at 0° Aries by definition, and
  /// [ZodiacSign] is declared from Aries, so this is a division.
  static ZodiacSign signAt(double longitude) {
    final index = (_wrap(longitude) / 30).floor().clamp(0, 11);
    return ZodiacSign.values[index];
  }

  /// Julian Day for [date], taken at 12:00 unless [timeOfDay] says
  /// otherwise.
  ///
  /// Noon by default, not midnight: with no birth time the true instant
  /// is anywhere in the day, and noon halves the worst-case error rather
  /// than sitting at one end of it.
  ///
  /// **The time of day is opt-in, and that is load-bearing.** Only the
  /// calendar fields of [date] are read — its own hour and minute are
  /// ignored. Transits are computed from `Clock.today()`, but a caller
  /// passing a full `DateTime.now()` must not get a sky that drifts
  /// through the afternoon: the daily reading has to be the same reading
  /// all day. Making time an explicit argument means a birth chart can
  /// ask for precision without any date-driven screen silently
  /// acquiring it.
  ///
  /// [timeOfDay] is wall-clock offset from midnight at the place of
  /// birth, which this app never asks for — see `BirthTime` for why that
  /// is acceptable and what it costs.
  static double julianDay(DateTime date, {Duration? timeOfDay}) {
    var year = date.year;
    var month = date.month;
    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();

    // 0.5 is noon; a known time replaces it with the real fraction.
    final fraction = timeOfDay == null
        ? 0.5
        : timeOfDay.inMinutes / Duration.minutesPerDay;

    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        date.day +
        b -
        1524.5 +
        fraction;
  }

  static double _centuries(DateTime date, [Duration? timeOfDay]) =>
      (julianDay(date, timeOfDay: timeOfDay) - 2451545.0) / 36525.0;

  static double _geocentric(
    _Elements element,
    DateTime date, [
    Duration? timeOfDay,
  ]) {
    final t = _centuries(date, timeOfDay);
    final planet = _heliocentric(element, t);
    final earth = _heliocentric(_earth, t);
    return _tropical(
      math.atan2(planet.y - earth.y, planet.x - earth.x),
      t,
    );
  }

  /// Heliocentric rectangular coordinates on the J2000 ecliptic, in AU.
  static _Vector _heliocentric(_Elements element, double t) {
    final a = element.a + element.aRate * t;
    final e = element.e + element.eRate * t;
    final i = _rad(element.i + element.iRate * t);
    final l = element.l + element.lRate * t;
    final peri = element.peri + element.periRate * t;
    final node = element.node + element.nodeRate * t;

    final argument = _rad(peri - node);
    final meanAnomaly = _rad(_wrapSigned(l - peri));
    final eccentric = _solveKepler(meanAnomaly, e);

    // Position in the orbital plane.
    final xOrbit = a * (math.cos(eccentric) - e);
    final yOrbit = a * math.sqrt(1 - e * e) * math.sin(eccentric);

    final cosArgument = math.cos(argument);
    final sinArgument = math.sin(argument);
    final cosNode = math.cos(_rad(node));
    final sinNode = math.sin(_rad(node));
    // Longitude is an angle in the x-y plane, so the out-of-plane
    // component is never needed and the z row is not computed.
    final cosI = math.cos(i);

    return _Vector(
      (cosArgument * cosNode - sinArgument * sinNode * cosI) * xOrbit +
          (-sinArgument * cosNode - cosArgument * sinNode * cosI) * yOrbit,
      (cosArgument * sinNode + sinArgument * cosNode * cosI) * xOrbit +
          (-sinArgument * sinNode + cosArgument * cosNode * cosI) * yOrbit,
    );
  }

  /// Newton's method on Kepler's equation, `E - e·sin E = M`.
  ///
  /// Eccentricities here top out at Mars' 0.093, so this converges to
  /// well under an arcsecond in a handful of passes.
  static double _solveKepler(double meanAnomaly, double e) {
    var eccentric = meanAnomaly + e * math.sin(meanAnomaly);
    for (var pass = 0; pass < 12; pass++) {
      final delta =
          (eccentric - e * math.sin(eccentric) - meanAnomaly) /
          (1 - e * math.cos(eccentric));
      eccentric -= delta;
      if (delta.abs() < 1e-12) break;
    }
    return eccentric;
  }

  /// J2000 longitude in radians to tropical degrees at epoch [t].
  ///
  /// Astrology is tropical: longitudes are measured from the equinox of
  /// the date, not from the fixed J2000 frame the elements are given in.
  /// Skipping this is a silent half-degree error that only shows up on
  /// cusp birthdays — which is precisely where being wrong is noticed.
  static double _tropical(double radians, double t) =>
      _wrap(_deg(radians) + (5028.796195 * t + 1.1054348 * t * t) / 3600);

  static double _rad(double degrees) => degrees * math.pi / 180;

  static double _deg(double radians) => radians * 180 / math.pi;

  static double _wrap(double degrees) {
    final value = degrees % 360;
    return value < 0 ? value + 360 : value;
  }

  static double _wrapSigned(double degrees) {
    final value = _wrap(degrees);
    return value > 180 ? value - 360 : value;
  }

  // JPL's approximate orbital elements, J2000, with rates per century.
  // Keplerian Elements for Approximate Positions of the Major Planets,
  // valid 1800–2050.
  static const _earth = _Elements(
    a: 1.00000261,
    aRate: 0.00000562,
    e: 0.01671123,
    eRate: -0.00004392,
    i: -0.00001531,
    iRate: -0.01294668,
    l: 100.46457166,
    lRate: 35999.37244981,
    peri: 102.93768193,
    periRate: 0.32327364,
    node: 0,
    nodeRate: 0,
  );

  static const _venus = _Elements(
    a: 0.72333566,
    aRate: 0.00000390,
    e: 0.00677672,
    eRate: -0.00004107,
    i: 3.39467605,
    iRate: -0.00078890,
    l: 181.97909950,
    lRate: 58517.81538729,
    peri: 131.60246718,
    periRate: 0.00268329,
    node: 76.67984255,
    nodeRate: -0.27769418,
  );

  static const _mars = _Elements(
    a: 1.52371034,
    aRate: 0.00001847,
    e: 0.09339410,
    eRate: 0.00007882,
    i: 1.84969142,
    iRate: -0.00813131,
    l: -4.55343205,
    lRate: 19140.30268499,
    peri: -23.94362959,
    periRate: 0.44441088,
    node: 49.55953891,
    nodeRate: -0.29257343,
  );

  static const _mercury = _Elements(
    a: 0.38709927,
    aRate: 0.00000037,
    e: 0.20563593,
    eRate: 0.00001906,
    i: 7.00497902,
    iRate: -0.00594749,
    l: 252.25032350,
    lRate: 149472.67411175,
    peri: 77.45779628,
    periRate: 0.16047689,
    node: 48.33076593,
    nodeRate: -0.12534081,
  );

  static const _jupiter = _Elements(
    a: 5.20288700,
    aRate: -0.00011607,
    e: 0.04838624,
    eRate: -0.00013253,
    i: 1.30439695,
    iRate: -0.00183714,
    l: 34.39644051,
    lRate: 3034.74612775,
    peri: 14.72847983,
    periRate: 0.21252668,
    node: 100.47390909,
    nodeRate: 0.20469106,
  );

  static const _saturn = _Elements(
    a: 9.53667594,
    aRate: -0.00125060,
    e: 0.05386179,
    eRate: -0.00050991,
    i: 2.48599187,
    iRate: 0.00193609,
    l: 49.95424423,
    lRate: 1222.49362201,
    peri: 92.59887831,
    periRate: -0.41897216,
    node: 113.66242448,
    nodeRate: -0.28867794,
  );
}

/// Keplerian elements and their per-century rates.
class _Elements {
  const _Elements({
    required this.a,
    required this.aRate,
    required this.e,
    required this.eRate,
    required this.i,
    required this.iRate,
    required this.l,
    required this.lRate,
    required this.peri,
    required this.periRate,
    required this.node,
    required this.nodeRate,
  });

  /// Semi-major axis, AU.
  final double a;
  final double aRate;

  /// Eccentricity.
  final double e;
  final double eRate;

  /// Inclination, degrees.
  final double i;
  final double iRate;

  /// Mean longitude, degrees.
  final double l;
  final double lRate;

  /// Longitude of perihelion, degrees.
  final double peri;
  final double periRate;

  /// Longitude of the ascending node, degrees.
  final double node;
  final double nodeRate;
}

/// A point on the ecliptic plane. The z axis is not needed: every
/// consumer here wants a longitude, and longitude is an angle in x-y.
class _Vector {
  const _Vector(this.x, this.y);

  final double x;
  final double y;
}
