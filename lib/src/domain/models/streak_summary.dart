import 'package:dart_mappable/dart_mappable.dart';

part 'streak_summary.mapper.dart';

/// The state of a user's practice streak.
@MappableClass()
class StreakSummary with StreakSummaryMappable {
  /// Creates a streak summary.
  const StreakSummary({
    required this.current,
    required this.longest,
    required this.completedToday,
    this.lastActiveDate,
  });

  /// An empty streak, for a user who has never practised.
  static const StreakSummary empty = StreakSummary(
    current: 0,
    longest: 0,
    completedToday: false,
  );

  /// Length of the run of consecutive days ending today or yesterday.
  final int current;

  /// The longest run ever achieved.
  final int longest;

  /// Whether today has already been counted.
  final bool completedToday;

  /// The most recent active day, if any.
  final DateTime? lastActiveDate;

  /// Whether the streak is alive but today is still outstanding.
  ///
  /// This is the state worth nudging a user about — they have something
  /// to lose today, which is a far better prompt than a generic reminder.
  bool get isAtRisk => current > 0 && !completedToday;
}
