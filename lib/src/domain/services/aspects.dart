import 'dart:math' as math;

/// How two planetary positions relate.
///
/// ## Why harmonics rather than orbs
///
/// Traditional astrology counts an aspect only inside an orb — a square
/// is "in effect" within 8° of 90° and simply absent at 45°. Modelled
/// literally that produces a product where most planet pairs contribute
/// nothing at all, every score sits on its baseline, and the occasional
/// pair spikes. Flat with spikes is the worst possible distribution for
/// something people compare with their friends.
///
/// So this uses the harmonic form instead, which is a real school of
/// astrology and happens to be continuous: `cos(4θ)` peaks at 0°, 90°
/// and 180° — the hard, charged angles — and bottoms out at 45° and
/// 135°. `cos(6θ)` peaks at 0°, 60°, 120° and 180°, the flowing ones,
/// and bottoms out at 30°, 90° and 150°.
///
/// Every pair of positions therefore produces a defined, distinct number
/// that moves smoothly with the real geometry. Nothing is bucketed and
/// nothing is invented.
abstract final class Aspects {
  /// Angular separation between two ecliptic longitudes, `0–180`.
  static double separation(double a, double b) {
    final raw = (a - b).abs() % 360;
    return raw > 180 ? 360 - raw : raw;
  }

  /// Charge: conjunction, square and opposition, `0–1`.
  ///
  /// The friction aspects. High heat is attraction and volatility at
  /// once, which is why it drives Spark and Drama rather than Trust.
  static double heat(double a, double b) =>
      (1 + math.cos(4 * _radians(separation(a, b)))) / 2;

  /// Flow: conjunction, sextile, trine and opposition, `0–1`.
  ///
  /// The aspects that make something comfortable rather than exciting.
  static double ease(double a, double b) =>
      (1 + math.cos(6 * _radians(separation(a, b)))) / 2;

  static double _radians(double degrees) => degrees * math.pi / 180;
}
