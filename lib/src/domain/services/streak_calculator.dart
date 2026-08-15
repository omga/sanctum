import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/domain/models/streak_summary.dart';

/// Turns a set of active days into a [StreakSummary].
///
/// ## The rule that matters
///
/// A streak survives until a day is *missed*, not until a day is
/// *skipped so far*. If a user practised yesterday and it is now 9am,
/// their streak is 5 — not 0 — even though today is not done. Resetting
/// at midnight would be technically defensible and would feel like a
/// punishment for waking up.
///
/// So: a streak counts back from today if today is done, otherwise from
/// yesterday. Only when neither is present is it broken.
abstract final class StreakCalculator {
  /// Summarises [activeDates] relative to [today].
  ///
  /// [activeDates] may contain duplicates, times of day, and any order —
  /// all of which are normalised away. That tolerance is deliberate: the
  /// caller is a database query, and forcing it to pre-clean the data
  /// would push domain rules into the data layer.
  static StreakSummary summarise({
    required Iterable<DateTime> activeDates,
    required DateTime today,
  }) {
    final days = activeDates.map((d) => d.dateOnly).toSet();
    if (days.isEmpty) return StreakSummary.empty;

    final normalisedToday = today.dateOnly;
    final yesterday = normalisedToday.subtract(const Duration(days: 1));

    final completedToday = days.contains(normalisedToday);

    // Anchor the current run at today if done, else yesterday. If neither
    // is present the streak is broken and current is zero.
    DateTime? anchor;
    if (completedToday) {
      anchor = normalisedToday;
    } else if (days.contains(yesterday)) {
      anchor = yesterday;
    }

    var current = 0;
    if (anchor != null) {
      var cursor = anchor;
      while (days.contains(cursor)) {
        current++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    final sorted = days.toList()..sort();
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i - 1].calendarDaysUntil(sorted[i]);
      run = gap == 1 ? run + 1 : 1;
      if (run > longest) longest = run;
    }

    return StreakSummary(
      current: current,
      // A run in progress can exceed any historical run.
      longest: longest > current ? longest : current,
      completedToday: completedToday,
      lastActiveDate: sorted.last,
    );
  }
}
