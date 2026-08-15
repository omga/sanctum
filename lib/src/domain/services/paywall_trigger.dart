import 'package:sanctum/src/domain/models/paywall.dart';

/// Decides whether now is the moment to ask for money.
///
/// ## The strategy
///
/// A paywall shown immediately after onboarding asks someone to pay for
/// something they have not experienced. It converts badly and it is the
/// single most common complaint in wellness-app reviews. So Sanctum never
/// does that. Instead it waits for a moment when the value is already
/// proven, and frames the offer around that moment.
///
/// Three ideas do the work:
///
/// 1. **Earned moments.** The paywall appears after the user has done
///    something — kept a streak, finished a ritual, used both free
///    sessions. They have felt the product work before being asked.
///
/// 2. **Explicit intent wins.** Tapping a locked session bypasses every
///    cooldown below. They just told us what they want; making them wait
///    would be perverse.
///
/// 3. **Exponential backoff on refusal.** Each dismissal pushes the next
///    prompt further out — 3 days, then 7, then 14, then 30 — and after
///    [maxAutomaticShows] refusals Sanctum stops asking on its own
///    entirely, forever. Locked content still opens it, because that is
///    the user's choice.
///
/// That last rule is the one people leave out, and it is the one that
/// matters most. Nagging produces a small conversion bump, then
/// uninstalls and one-star reviews that cost far more than the bump. An
/// app that visibly stops asking is one people keep — and a user who
/// keeps the app can still convert in month six.
abstract final class PaywallTrigger {
  /// After this many dismissals, stop showing it automatically.
  static const int maxAutomaticShows = 4;

  /// Minimum days on the app before any automatic prompt.
  ///
  /// One full day, so install day is always clean.
  static const int minimumDaysSinceInstall = 1;

  /// Streak length that counts as "worth protecting".
  static const int streakThreshold = 3;

  /// Free sound sessions before the library locks.
  static const int freeSessionAllowance = 2;

  /// Cooldown in days after each successive dismissal.
  ///
  /// The last value repeats for any further dismissals, though
  /// [maxAutomaticShows] means it is never reached in practice.
  static const List<int> dismissalBackoffDays = [3, 7, 14, 30];

  /// Evaluates [signals].
  static PaywallDecision decide(PaywallSignals signals) {
    if (signals.isPremium) {
      return const HoldPaywall('already subscribed');
    }

    // Explicit intent short-circuits everything. The user tapped a lock.
    if (signals.explicitIntent) {
      return const ShowPaywall(PaywallMoment.lockedContent);
    }

    if (signals.daysSinceInstall < minimumDaysSinceInstall) {
      return const HoldPaywall('install day — let them arrive first');
    }

    if (signals.timesDismissed >= maxAutomaticShows) {
      return const HoldPaywall(
        'dismissed $maxAutomaticShows times — never ask automatically again',
      );
    }

    final cooldown = _cooldownDays(signals.timesDismissed);
    final since = signals.daysSinceLastShown;
    if (since != null && since < cooldown) {
      return HoldPaywall('cooling down: $since of $cooldown days');
    }

    final moment = _earnedMoment(signals);
    if (moment == null) {
      return const HoldPaywall('nothing earned yet');
    }

    return ShowPaywall(moment);
  }

  /// Days that must pass after [dismissals] refusals.
  static int _cooldownDays(int dismissals) {
    if (dismissals <= 0) return 0;
    final index = dismissals - 1;
    return index < dismissalBackoffDays.length
        ? dismissalBackoffDays[index]
        : dismissalBackoffDays.last;
  }

  /// The strongest moment the user has reached, or `null`.
  ///
  /// Ordered by how much the framing is worth: a just-completed ritual is
  /// a better moment than a generic "you've been here a week".
  static PaywallMoment? _earnedMoment(PaywallSignals signals) {
    if (signals.ritualsCompleted > 0) return PaywallMoment.ritualCompleted;
    if (signals.currentStreak >= streakThreshold) {
      return PaywallMoment.streakEarned;
    }
    if (signals.sessionsCompleted >= freeSessionAllowance) {
      return PaywallMoment.sessionsSampled;
    }
    // A quietly engaged user who tripped none of the above.
    if (signals.daysSinceInstall >= 7 && signals.timesShown == 0) {
      return PaywallMoment.returningUser;
    }
    return null;
  }
}
