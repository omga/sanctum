/// A source of "now".
///
/// ## Why not just call `DateTime.now()`?
///
/// Because Sanctum's core logic is *about* time. The daily attunement card
/// changes at local midnight, streaks break after a missed day, and moon
/// phase is a function of the date. If those read the system clock
/// directly, their tests can only ever assert what is true at the moment
/// CI happens to run — which means a suite that passes all week and fails
/// on the 1st of the month, or a "does the streak break?" test that is
/// physically impossible to write.
///
/// Injecting the clock turns every one of those into an ordinary, boring
/// unit test: hand the logic a [FixedClock], assert the answer. This is
/// the single highest-leverage testability decision in this codebase.
abstract interface class Clock {
  /// The current instant, in local time.
  DateTime now();
}

/// The real clock. Used everywhere outside tests.
final class SystemClock implements Clock {
  /// Creates a system clock.
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A clock frozen at a chosen instant, for tests.
///
/// ```dart
/// final clock = FixedClock(DateTime(2026, 3, 14, 9));
/// expect(selector.cardFor(clock.today()), sameCardAllDay);
/// ```
final class FixedClock implements Clock {
  /// Creates a clock permanently reporting [instant].
  FixedClock(this.instant);

  /// The instant this clock reports.
  DateTime instant;

  /// Moves the clock forward by [duration]. Useful for streak tests.
  void advance(Duration duration) => instant = instant.add(duration);

  @override
  DateTime now() => instant;
}

/// Date helpers shared by the domain layer.
extension ClockX on Clock {
  /// Today's date in local time, with the time component stripped.
  ///
  /// This is the key the daily attunement and streak logic are indexed
  /// by, so it must be *local* — a user in Auckland and a user in Los
  /// Angeles turn over to a new card at their own midnight, not UTC's.
  DateTime today() => now().dateOnly;
}

/// Date-only helpers.
extension DateOnlyX on DateTime {
  /// This instant with hours, minutes, seconds and milliseconds removed.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Whether this falls on the same calendar day as [other].
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Whole calendar days from this date to [other], ignoring time.
  ///
  /// Uses UTC internally so daylight-saving transitions cannot make a
  /// day count off by one — a real bug in streak logic that only shows
  /// up twice a year.
  int calendarDaysUntil(DateTime other) {
    final a = DateTime.utc(year, month, day);
    final b = DateTime.utc(other.year, other.month, other.day);
    return b.difference(a).inDays;
  }
}
