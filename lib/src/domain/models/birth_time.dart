import 'package:dart_mappable/dart_mappable.dart';

part 'birth_time.mapper.dart';

/// The time of day someone was born, which they may not know.
///
/// ## Why this is a type and not an `int?`
///
/// There are three states, not two, and a nullable integer only carries
/// two of them. "Never asked", "asked and told", and "asked and they do
/// not know" are genuinely different: the first should still prompt, and
/// the last must never be quietly treated as midnight. Storing this in a
/// map keyed by question id gives all three — absent, present-and-known,
/// present-and-unknown — without a sentinel value anybody has to
/// remember.
///
/// ## What a birth time actually buys, and what it does not
///
/// A birth *date* pins a body only as tightly as that body is slow. Sun,
/// Venus, Mars and Saturn are all safe from a date alone, which is why
/// they are the four the readings were built on. The Moon is not: it
/// moves 13° a day and changes sign every 2.3 days, so its placement is
/// a coin toss without a time. That is the one thing a birth time
/// unlocks here, and `Ephemeris.moonLongitude` is where it is spent.
///
/// It follows that adding a time barely moves the other four. Do not
/// promise the user a transformed reading — the honest claim is that the
/// Moon becomes readable, which is what the copy says.
///
/// ## The zone caveat, stated plainly
///
/// This is wall-clock time at the place of birth, and the app never asks
/// where that was. The whole app already treats a birth *date* as a bare
/// calendar date with no zone attached, and this is the same assumption
/// one level finer. Someone born at 09:00 in Kyiv and someone born at
/// 09:00 in Los Angeles are therefore given the same sky.
///
/// The error that introduces is bounded by the zone offset — a few hours
/// for most people, and under 1° of lunar motion per two hours. Against
/// the status quo of assuming noon and being wrong by up to twelve
/// hours, a supplied time is better for essentially every user and worse
/// for none. Asking for a birth *place* is what would close the gap
/// properly, and it is a bigger question than it looks: it needs a
/// geocoder, a historical timezone database, and a screen.
@MappableClass()
class BirthTime with BirthTimeMappable {
  /// Creates a birth time. A null [minuteOfDay] means "does not know".
  const BirthTime({this.minuteOfDay});

  /// A known time.
  const BirthTime.at(int hour, int minute)
    : minuteOfDay = hour * 60 + minute;

  /// The answer of someone who does not know when they were born.
  static const BirthTime unknown = BirthTime();

  /// Minutes since local midnight, `0`–`1439`, or null if unknown.
  final int? minuteOfDay;

  /// Whether an actual time was given.
  bool get isKnown => minuteOfDay != null;

  /// Hour on a 24-hour clock, or null.
  int? get hour => minuteOfDay == null ? null : minuteOfDay! ~/ 60;

  /// Minute past the hour, or null.
  int? get minute => minuteOfDay == null ? null : minuteOfDay! % 60;

  /// Offset from midnight, or null. What the ephemeris takes.
  Duration? get sinceMidnight =>
      minuteOfDay == null ? null : Duration(minutes: minuteOfDay!);

  /// `07:45`, or `Unknown`.
  String get label {
    final minutes = minuteOfDay;
    if (minutes == null) return 'Unknown';
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
