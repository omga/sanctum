import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/palm_gate.dart';

const _scan = 'palm:2026-09-08T10:12:00Z:right';
const _other = 'palm:2026-09-08T18:40:00Z:left';

PalmReadingAccess _decide({
  Set<String> unlocked = const {},
  bool hasSharedScan = false,
  bool isPremium = false,
}) => PalmGate.decide(
  scanId: _scan,
  unlockedIds: unlocked,
  hasSharedScan: hasSharedScan,
  isPremium: isPremium,
);

void main() {
  group('the first reading', () {
    test('is locked until something has been shared', () {
      expect(_decide(), PalmReadingAccess.needsShare);
    });

    test('opens on a completed share', () {
      expect(
        _decide(hasSharedScan: true),
        PalmReadingAccess.unlocked,
      );
    });

    test('opens for a subscriber without asking for a share', () {
      expect(_decide(isPremium: true), PalmReadingAccess.unlocked);
    });
  });

  group('the second reading', () {
    test('costs money once the free one is spent', () {
      expect(
        _decide(unlocked: {_other}, hasSharedScan: true),
        PalmReadingAccess.needsPremium,
      );
    });

    test('does not reopen by sharing again', () {
      // The allowance is one, not one per share. Otherwise the price is
      // "tap the share sheet twice", which is not a price.
      expect(
        _decide(unlocked: {_other}, hasSharedScan: true),
        PalmReadingAccess.needsPremium,
      );
    });

    test('is free for a subscriber', () {
      expect(
        _decide(unlocked: {_other}, isPremium: true),
        PalmReadingAccess.unlocked,
      );
    });
  });

  group('a reading that is already unlocked', () {
    test('stays unlocked', () {
      expect(_decide(unlocked: {_scan}), PalmReadingAccess.unlocked);
    });

    test('stays unlocked when the subscription lapses', () {
      // A scan is a particular hand on a particular day. Closing one
      // because a subscription ended is taking back a thing somebody
      // earned, and it is the same rule CompatibilityGate holds.
      expect(
        _decide(unlocked: {_scan}, isPremium: false),
        PalmReadingAccess.unlocked,
      );
    });

    test('does not unlock a different scan', () {
      expect(
        PalmGate.decide(
          scanId: _other,
          unlockedIds: const {_scan},
          hasSharedScan: false,
          isPremium: false,
        ),
        PalmReadingAccess.needsPremium,
      );
    });
  });

  group('readingsRemaining', () {
    test('counts down from the allowance', () {
      expect(
        PalmGate.readingsRemaining(unlockedIds: const {}, isPremium: false),
        PalmGate.freeReadingAllowance,
      );
      expect(
        PalmGate.readingsRemaining(
          unlockedIds: const {_scan},
          isPremium: false,
        ),
        0,
      );
    });

    test('never goes negative', () {
      expect(
        PalmGate.readingsRemaining(
          unlockedIds: const {_scan, _other, 'palm:third'},
          isPremium: false,
        ),
        0,
      );
    });

    test('reads full for a subscriber, who never spends it', () {
      expect(
        PalmGate.readingsRemaining(
          unlockedIds: const {_scan, _other},
          isPremium: true,
        ),
        PalmGate.freeReadingAllowance,
      );
    });
  });
}
