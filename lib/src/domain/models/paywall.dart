import 'package:dart_mappable/dart_mappable.dart';

part 'paywall.mapper.dart';

/// The thing that earned the user a look at the paywall.
///
/// Carried through to the UI because the paywall's headline changes to
/// match. "You've kept this up for three days" converts far better than a
/// generic pitch, for the obvious reason that it is about them.
@MappableEnum()
enum PaywallMoment {
  /// They tapped something locked. The highest-intent signal there is —
  /// they have told us exactly what they want.
  lockedContent,

  /// They reached a streak worth protecting.
  streakEarned,

  /// They just finished a moon ritual. An emotional peak.
  ritualCompleted,

  /// They have used both free sound sessions.
  sessionsSampled,

  /// Long-term engaged user who has somehow never seen the paywall.
  returningUser,
}

/// Everything the trigger needs to decide.
///
/// A plain value object, so the decision is a pure function of it. No
/// clock, no database, no `BuildContext` — which is what makes every
/// rule below testable in a line.
@MappableClass()
class PaywallSignals with PaywallSignalsMappable {
  /// Creates a signal set.
  const PaywallSignals({
    required this.isPremium,
    required this.daysSinceInstall,
    required this.sessionsCompleted,
    required this.currentStreak,
    required this.ritualsCompleted,
    required this.timesShown,
    required this.timesDismissed,
    this.daysSinceLastShown,
    this.explicitIntent = false,
  });

  /// Whether they already pay. Nothing else matters if so.
  final bool isPremium;

  /// Whole days since first launch. `0` is install day.
  final int daysSinceInstall;

  /// Sound sessions completed.
  final int sessionsCompleted;

  /// Current practice streak.
  final int currentStreak;

  /// Moon rituals completed.
  final int ritualsCompleted;

  /// How many times the paywall has been shown, ever.
  final int timesShown;

  /// How many times it has been dismissed without purchase.
  final int timesDismissed;

  /// Days since it was last shown, or `null` if never.
  final int? daysSinceLastShown;

  /// The user tapped locked content, i.e. asked to see this.
  final bool explicitIntent;
}

/// The outcome of a trigger evaluation.
sealed class PaywallDecision {
  const PaywallDecision();
}

/// Show the paywall, framed around [moment].
final class ShowPaywall extends PaywallDecision {
  /// Creates a show decision.
  const ShowPaywall(this.moment);

  /// Why it is being shown.
  final PaywallMoment moment;
}

/// Do not show, because of [reason].
///
/// The reason is carried rather than discarded so that "why am I not
/// seeing the paywall?" is answerable from a log line instead of a
/// debugging session.
final class HoldPaywall extends PaywallDecision {
  /// Creates a hold decision.
  const HoldPaywall(this.reason);

  /// Human-readable explanation.
  final String reason;
}
