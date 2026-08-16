import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/compatibility_gate.dart';

CompatibilityAccess decide({
  String matchId = 'celeb:zendaya',
  Set<String> revealed = const {},
  bool invited = false,
  bool premium = false,
}) => CompatibilityGate.decide(
  matchId: matchId,
  revealedIds: revealed,
  hasSharedInvite: invited,
  isPremium: premium,
);

void main() {
  group('the first reading', () {
    test('is locked behind an invite', () {
      expect(decide(), CompatibilityAccess.needsInvite);
    });

    test('opens once an invite has been sent', () {
      expect(decide(invited: true), CompatibilityAccess.unlocked);
    });
  });

  group('the second reading', () {
    test('needs a subscription, invite or not', () {
      expect(
        decide(
          matchId: 'celeb:drake',
          revealed: {'celeb:zendaya'},
          invited: true,
        ),
        CompatibilityAccess.needsPremium,
      );
    });

    test('does not fall back to asking for another invite', () {
      // Asking for a second invite instead of money is the tempting
      // version and it is worse: it trains people that the paywall can
      // always be shared away.
      expect(
        decide(matchId: 'celeb:drake', revealed: {'celeb:zendaya'}),
        CompatibilityAccess.needsPremium,
      );
    });
  });

  group('a reading already revealed', () {
    test('stays open forever', () {
      expect(
        decide(revealed: {'celeb:zendaya'}, invited: true),
        CompatibilityAccess.unlocked,
      );
    });

    test('stays open even without the invite flag', () {
      expect(
        decide(revealed: {'celeb:zendaya'}),
        CompatibilityAccess.unlocked,
      );
    });

    test('does not consume the allowance twice', () {
      // Reopening the free reading must not be what locks the user out
      // of the free reading.
      const id = 'celeb:zendaya';
      expect(decide(matchId: id, revealed: {id}), CompatibilityAccess.unlocked);
      expect(
        CompatibilityGate.revealsRemaining(
          revealedIds: {id},
          isPremium: false,
        ),
        0,
      );
    });
  });

  group('premium', () {
    test('opens everything, with no invite and nothing revealed', () {
      expect(decide(premium: true), CompatibilityAccess.unlocked);
    });

    test('opens the tenth reading', () {
      expect(
        decide(
          matchId: 'person:sam:1990-1-1',
          revealed: {for (var i = 0; i < 10; i++) 'celeb:$i'},
          premium: true,
        ),
        CompatibilityAccess.unlocked,
      );
    });
  });

  group('remaining', () {
    test('starts at the allowance', () {
      expect(
        CompatibilityGate.revealsRemaining(
          revealedIds: const {},
          isPremium: false,
        ),
        CompatibilityGate.freeRevealAllowance,
      );
    });

    test('never goes negative', () {
      expect(
        CompatibilityGate.revealsRemaining(
          revealedIds: const {'a', 'b', 'c'},
          isPremium: false,
        ),
        0,
      );
    });
  });
}
