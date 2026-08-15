import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/premium_gate.dart';

void main() {
  group('PremiumGate', () {
    test('the first two sessions are free, the rest are not', () {
      expect(PremiumGate.isSessionFree(0), isTrue);
      expect(PremiumGate.isSessionFree(1), isTrue);
      expect(PremiumGate.isSessionFree(2), isFalse);
      expect(PremiumGate.isSessionFree(8), isFalse);
    });

    test('premium unlocks every gated feature', () {
      for (final feature in PremiumFeature.values) {
        expect(
          PremiumGate.isUnlocked(feature: feature, isPremium: true),
          isTrue,
          reason: '$feature should be unlocked for subscribers',
        );
        expect(
          PremiumGate.isUnlocked(feature: feature, isPremium: false),
          isFalse,
          reason: '$feature should be gated for free users',
        );
      }
    });

    test('the free allowance matches what the trigger assumes', () {
      // These two constants must agree: the paywall fires on
      // "sessionsSampled" only if the number of free sessions is the
      // number the gate actually hands out.
      expect(PremiumGate.freeSessionAllowance, 2);
    });
  });
}
