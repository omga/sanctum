import 'package:dart_mappable/dart_mappable.dart';

part 'planet.mapper.dart';

/// The bodies Sanctum computes.
///
/// ## Why the Moon is missing
///
/// A birth *date* with no time pins a body only as tightly as that body
/// is slow. The Moon moves 13° a day and changes sign every 2.3 days, so
/// its natal sign genuinely cannot be known from a date — and quietly
/// guessing it would put a wrong claim in front of the user on roughly
/// four days in ten. Everything here is slow enough to be safe: Mercury
/// is the fastest at about 1.5° a day.
///
/// Declared slowest-last, which is also the order of astrological
/// weight and is used for ranking.
@MappableEnum()
enum Planet {
  /// Identity, the day itself.
  sun('Sun', 'who you are when nobody is performing'),

  /// Thought, speech, arrangements.
  mercury('Mercury', 'how you think and what you say out loud'),

  /// Wanting, taste, affection.
  venus('Venus', 'what you are drawn to'),

  /// Drive, temper, pursuit.
  mars('Mars', 'your drive, and your temper'),

  /// Expansion, luck, excess.
  jupiter('Jupiter', 'the part of you that wants more'),

  /// Limit, duty, time.
  saturn('Saturn', 'what you take seriously, and what you fear');

  const Planet(this.displayName, this.blurb);

  /// Human-readable name.
  final String displayName;

  /// What it governs, written to be read by a non-astrologer.
  final String blurb;

  /// Bodies that can be used as *natal* points.
  ///
  /// Jupiter and Mercury are computable but excluded: Mercury is never
  /// more than 28° from the Sun so its transits duplicate solar ones,
  /// and Jupiter's natal placement is a year-long generational marker
  /// rather than something personal.
  static const List<Planet> natal = [sun, venus, mars, saturn];

  /// How much a transit from this body matters.
  ///
  /// Slower bodies rank higher because they arrive rarely and stay:
  /// Saturn crossing your Sun is a season of your life, Mercury doing
  /// the same is an afternoon.
  double get weight => switch (this) {
    Planet.sun => 1.0,
    Planet.mercury => 0.85,
    Planet.venus => 1.0,
    Planet.mars => 1.1,
    Planet.jupiter => 1.2,
    Planet.saturn => 1.35,
  };

  /// How far from exact still counts, in degrees.
  ///
  /// Tighter for slow bodies. Saturn moves so slowly that a generous orb
  /// would leave the same transit "active" for months and the daily
  /// reading would stop changing.
  double get orb => switch (this) {
    Planet.jupiter => 2.5,
    Planet.saturn => 2.0,
    _ => 4.0,
  };

  /// Whether this body can turn retrograde.
  bool get canRetrograde => this != Planet.sun;
}
