import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/domain/services/paywall_trigger.dart';

PaywallSignals signals({
  bool isPremium = false,
  int daysSinceInstall = 5,
  int sessionsCompleted = 0,
  int currentStreak = 0,
  int ritualsCompleted = 0,
  int timesShown = 0,
  int timesDismissed = 0,
  int? daysSinceLastShown,
  bool explicitIntent = false,
}) => PaywallSignals(
  isPremium: isPremium,
  daysSinceInstall: daysSinceInstall,
  sessionsCompleted: sessionsCompleted,
  currentStreak: currentStreak,
  ritualsCompleted: ritualsCompleted,
  timesShown: timesShown,
  timesDismissed: timesDismissed,
  daysSinceLastShown: daysSinceLastShown,
  explicitIntent: explicitIntent,
);

PaywallMoment? momentOf(PaywallDecision decision) => switch (decision) {
  ShowPaywall(:final moment) => moment,
  HoldPaywall() => null,
};

void main() {
  group('never shows when it should not', () {
    test('subscribers are never asked', () {
      final decision = PaywallTrigger.decide(
        signals(isPremium: true, currentStreak: 30, explicitIntent: true),
      );
      expect(decision, isA<HoldPaywall>());
    });

    test('never on install day, even with a strong signal', () {
      // The explicit product rule: nothing right after onboarding.
      final decision = PaywallTrigger.decide(
        signals(daysSinceInstall: 0, ritualsCompleted: 1),
      );
      expect(decision, isA<HoldPaywall>());
    });

    test('holds when the user has done nothing yet', () {
      expect(PaywallTrigger.decide(signals()), isA<HoldPaywall>());
    });

    test('a hold always explains itself', () {
      final decision = PaywallTrigger.decide(signals()) as HoldPaywall;
      expect(decision.reason, isNotEmpty);
    });
  });

  group('earned moments', () {
    test('a completed ritual is the strongest moment', () {
      expect(
        momentOf(PaywallTrigger.decide(signals(ritualsCompleted: 1))),
        PaywallMoment.ritualCompleted,
      );
    });

    test('a 3-day streak earns a prompt', () {
      expect(
        momentOf(PaywallTrigger.decide(signals(currentStreak: 3))),
        PaywallMoment.streakEarned,
      );
      expect(
        PaywallTrigger.decide(signals(currentStreak: 2)),
        isA<HoldPaywall>(),
      );
    });

    test('using both free sessions earns a prompt', () {
      expect(
        momentOf(PaywallTrigger.decide(signals(sessionsCompleted: 2))),
        PaywallMoment.sessionsSampled,
      );
      expect(
        PaywallTrigger.decide(signals(sessionsCompleted: 1)),
        isA<HoldPaywall>(),
      );
    });

    test('a quietly engaged week-old user is eventually asked once', () {
      expect(
        momentOf(PaywallTrigger.decide(signals(daysSinceInstall: 7))),
        PaywallMoment.returningUser,
      );
    });

    test('the returning-user moment only fires if never shown before', () {
      expect(
        PaywallTrigger.decide(
          signals(daysSinceInstall: 30, timesShown: 1, daysSinceLastShown: 60),
        ),
        isA<HoldPaywall>(),
      );
    });
  });

  group('explicit intent', () {
    test('tapping locked content always shows, ignoring cooldown', () {
      final decision = PaywallTrigger.decide(
        signals(
          explicitIntent: true,
          timesDismissed: 2,
          daysSinceLastShown: 0,
        ),
      );
      expect(momentOf(decision), PaywallMoment.lockedContent);
    });

    test('locked content still works after the automatic limit', () {
      // The user stopped it nagging, but can still choose to look.
      final decision = PaywallTrigger.decide(
        signals(explicitIntent: true, timesDismissed: 99),
      );
      expect(momentOf(decision), PaywallMoment.lockedContent);
    });

    test('but not for someone who already pays', () {
      expect(
        PaywallTrigger.decide(
          signals(isPremium: true, explicitIntent: true),
        ),
        isA<HoldPaywall>(),
      );
    });
  });

  group('backoff on refusal', () {
    test('cooldown grows with each dismissal', () {
      // 1 dismissal -> 3 days, 2 -> 7, 3 -> 14.
      for (final (dismissals, cooldown) in [(1, 3), (2, 7), (3, 14)]) {
        expect(
          PaywallTrigger.decide(
            signals(
              ritualsCompleted: 1,
              timesDismissed: dismissals,
              daysSinceLastShown: cooldown - 1,
            ),
          ),
          isA<HoldPaywall>(),
          reason: '$dismissals dismissals should still be cooling down',
        );

        expect(
          PaywallTrigger.decide(
            signals(
              ritualsCompleted: 1,
              timesDismissed: dismissals,
              daysSinceLastShown: cooldown,
            ),
          ),
          isA<ShowPaywall>(),
          reason: '$dismissals dismissals should be clear after $cooldown days',
        );
      }
    });

    test('stops asking automatically after the limit, permanently', () {
      final decision = PaywallTrigger.decide(
        signals(
          ritualsCompleted: 5,
          currentStreak: 100,
          timesDismissed: PaywallTrigger.maxAutomaticShows,
          daysSinceLastShown: 3650,
        ),
      );

      // Ten years later, a maximally engaged user who said no four times
      // is still not nagged. This is the rule that protects the reviews.
      expect(decision, isA<HoldPaywall>());
    });

    test('the first prompt has no cooldown', () {
      expect(
        PaywallTrigger.decide(signals(ritualsCompleted: 1)),
        isA<ShowPaywall>(),
      );
    });
  });

  test('a full user journey never shows more than the limit', () {
    // Simulate a user who refuses every time, over two years.
    var dismissed = 0;
    var shown = 0;
    int? sinceShown;

    for (var day = 1; day <= 730; day++) {
      final decision = PaywallTrigger.decide(
        signals(
          daysSinceInstall: day,
          currentStreak: 10,
          ritualsCompleted: 2,
          timesShown: shown,
          timesDismissed: dismissed,
          daysSinceLastShown: sinceShown,
        ),
      );

      if (decision is ShowPaywall) {
        shown++;
        dismissed++;
        sinceShown = 0;
      } else if (sinceShown != null) {
        sinceShown++;
      }
    }

    expect(
      shown,
      PaywallTrigger.maxAutomaticShows,
      reason: 'over two years of refusing, asked exactly 4 times',
    );
  });
}
