/// When to send the daily reading.
///
/// ## Why this is a pure function
///
/// Onboarding asks "when do you want your reading?" and — until now —
/// threw the answer away: the `rhythm` question was stored and read by
/// no code in the app. Asking someone to commit to a time and then
/// silently ignoring it is the worst version of a retention feature,
/// because it costs a question in the funnel and returns nothing.
///
/// Deciding *when* is separated from *sending* so the decision can be
/// tested without a platform channel, a permission dialog, or a clock
/// that moves on its own.
abstract final class ReminderSchedule {
  /// Hour of the day for each answer to the `rhythm` question.
  ///
  /// Evening is 20:00 rather than later: the reading is meant to close
  /// the day, and a notification at 22:00 competes with sleep, which is
  /// the one thing this app should not be doing.
  static const hours = <String, int>{
    'morning': 8,
    'midday': 13,
    'evening': 20,
  };

  /// Default when the question was skipped or the answer is unknown.
  static const int defaultHour = 8;

  /// How many days are scheduled ahead.
  ///
  /// Notification bodies carry real transit copy, which has to be
  /// computed now rather than when the notification fires — nothing runs
  /// at fire time. A week is the balance: long enough to survive a user
  /// who does not open the app for days, short enough that the queue is
  /// rewritten often and never drifts far from what the app would say.
  static const int horizonDays = 7;

  /// The hour for [rhythmId].
  static int hourFor(String? rhythmId) =>
      hours[rhythmId] ?? defaultHour;

  /// The next [count] reminder instants strictly after [from].
  ///
  /// Strictly after matters: scheduling one for a time that has already
  /// passed today either fires immediately — a notification the moment
  /// someone finishes onboarding — or is silently dropped, depending on
  /// the platform. Neither is what was asked for.
  static List<DateTime> upcoming({
    required DateTime from,
    required int hour,
    int count = horizonDays,
  }) {
    var next = DateTime(from.year, from.month, from.day, hour);
    if (!next.isAfter(from)) {
      next = next.add(const Duration(days: 1));
    }

    return [
      for (var day = 0; day < count; day++)
        DateTime(next.year, next.month, next.day + day, hour),
    ];
  }
}
