import 'package:sanctum/src/domain/models/message_balance.dart';

/// How many advisor messages the user has, and what spending one does.
///
/// ## The shape of it
///
/// * A subscriber gets [weeklyFree] messages a week, shared across every
///   conversation.
/// * Anyone can buy [messagesPerPack] more, which do not expire.
/// * A non-subscriber gets no free messages and can still buy.
///
/// ## Why weekly, and why shared
///
/// Weekly rather than monthly because the advisor is a habit product and
/// a month is too long a gap to form one — and because five a week is a
/// number somebody can feel, where twenty a month is a number they have
/// to track. `roadmap.md` §2 wants an allowance "enough to form the
/// habit, not enough to satisfy it"; this is that, at a cadence the user
/// notices.
///
/// Shared because the alternative makes the cost of a subscriber a
/// function of how many pairings they have saved, and saving pairings is
/// what the rest of the app is for.
///
/// ## Why free messages are spent first
///
/// They are the perishable ones. Spending a bought message while a free
/// one expires unused on Sunday is taking money for nothing, and it is
/// the kind of quiet unfairness nobody notices until they do.
abstract final class MessageBudget {
  /// Free messages a subscriber gets each week.
  static const int weeklyFree = 5;

  /// Messages in one purchase.
  static const int messagesPerPack = 5;

  /// Where the "nearly out" warning starts.
  static const int warnAtRemaining = 1;

  /// The week [date] falls in, as a sortable key.
  ///
  /// ISO-8601 weeks: they start on Monday and belong to the year that
  /// holds their Thursday, which is why this is not just "day of year
  /// over seven". Getting it wrong would hand somebody a second free
  /// allowance in the last week of December, every year.
  static String weekFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    // Thursday of this week decides the year.
    final thursday = day.add(Duration(days: 4 - _isoWeekday(day)));
    final firstThursday = _firstThursdayOf(thursday.year);
    final week = 1 + thursday.difference(firstThursday).inDays ~/ 7;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// Free messages left this week.
  ///
  /// Zero for anybody without a subscription: the free allowance is what
  /// Premium buys, and somebody who is not paying for it has none rather
  /// than some.
  static int freeRemaining({
    required MessageBalance balance,
    required String week,
    required bool isPremium,
  }) {
    if (!isPremium) return 0;
    // A different week means the counter is stale, not that it is zero.
    final used = balance.freeWeek == week ? balance.freeUsed : 0;
    final left = weeklyFree - used;
    return left < 0 ? 0 : left;
  }

  /// Everything the user can spend right now.
  static int remaining({
    required MessageBalance balance,
    required String week,
    required bool isPremium,
  }) =>
      freeRemaining(balance: balance, week: week, isPremium: isPremium) +
      balance.purchased;

  /// Whether a message can be sent.
  static bool canAsk({
    required MessageBalance balance,
    required String week,
    required bool isPremium,
  }) =>
      remaining(balance: balance, week: week, isPremium: isPremium) > 0;

  /// Whether the user should be told how few are left.
  static bool isNearlySpent({
    required MessageBalance balance,
    required String week,
    required bool isPremium,
  }) {
    final left = remaining(
      balance: balance,
      week: week,
      isPremium: isPremium,
    );
    return left > 0 && left <= warnAtRemaining;
  }

  /// The balance after one message is answered.
  ///
  /// Called on a completed answer and never on a failed one: a message
  /// that produced nothing has not been delivered, and charging for it
  /// is the difference between a bug and a complaint.
  ///
  /// Returns [balance] unchanged when there is nothing to spend, so a
  /// caller that has not checked [canAsk] cannot drive the count
  /// negative.
  static MessageBalance spend({
    required MessageBalance balance,
    required String week,
    required bool isPremium,
  }) {
    final free = freeRemaining(
      balance: balance,
      week: week,
      isPremium: isPremium,
    );
    if (free > 0) {
      // Rolling into a new week resets the counter as it writes it, so
      // there is no separate "start of week" moment to get wrong.
      final used = balance.freeWeek == week ? balance.freeUsed : 0;
      return balance.copyWith(freeWeek: week, freeUsed: used + 1);
    }
    if (balance.purchased > 0) {
      return balance.copyWith(purchased: balance.purchased - 1);
    }
    return balance;
  }

  /// The balance after a pack is bought.
  static MessageBalance grantPack(MessageBalance balance) =>
      balance.copyWith(purchased: balance.purchased + messagesPerPack);

  static int _isoWeekday(DateTime date) => date.weekday;

  static DateTime _firstThursdayOf(int year) {
    final fourth = DateTime(year, 1, 4);
    return fourth.add(Duration(days: 4 - _isoWeekday(fourth)));
  }
}
