import 'package:sanctum/src/domain/services/compatibility_gate.dart';

/// What the user may do with a given palm reading.
enum PalmReadingAccess {
  /// Show the reading.
  unlocked,

  /// Blur it until they have shared a scan.
  needsShare,

  /// Blur it and send them to the paywall.
  needsPremium,
}

/// Who gets to read a palm.
///
/// ## What is deliberately not gated
///
/// **The scan, the drawn lines and the exported video are free, always,
/// and there is no method here that can refuse one.** That absence is
/// the design. The video is the only acquisition channel this feature
/// has, and `handoff.md` already settled the general case when the
/// compatibility carousel was built: the export *is* the growth, so
/// charging friction for it taxes the one thing that produces users.
///
/// This matters more here than it did there, because the obvious
/// mechanic — post to TikTok, unlock the reading — is worse than it
/// looks in three separate ways. The platform reports only that an app
/// was picked, never that anything was posted, so the gate is
/// unenforceable (see `ShareController.shareInvite`, which says so at
/// length). Requiring a *public post* to unlock functionality is the
/// shape of thing App Review rejects. And App Store guideline 3.1.1
/// forbids unlocking paid content through a developer's own mechanism —
/// which is exactly what a share-for-a-report trade is, once the report
/// also has a price.
///
/// ## So what a share buys
///
/// The same thing an invite buys in [CompatibilityGate], for the same
/// reason and with the same honesty about what the signal proves: the
/// **first** reading. Any share target counts — a friend, a message, a
/// post — because the point is the reach, and because "share with
/// anybody" is a request App Review has no quarrel with while "post
/// publicly or pay" is one it might.
///
/// The second reading onwards costs money, and a subscriber never meets
/// either ask.
///
/// ## Why a reading stays unlocked
///
/// The set of unlocked ids is a set, and rule one is that anything already
/// unlocked stays unlocked. A scan is a moment — a particular hand, in
/// particular light, on a particular day — and taking one back because
/// a subscription lapsed would be closing a document somebody earned.
abstract final class PalmGate {
  /// How many readings a non-subscriber gets for sharing.
  static const int freeReadingAllowance = 1;

  /// Decides access to the reading for [scanId].
  static PalmReadingAccess decide({
    required String scanId,
    required Set<String> unlockedIds,
    required bool hasSharedScan,
    required bool isPremium,
  }) {
    if (unlockedIds.contains(scanId)) return PalmReadingAccess.unlocked;
    if (isPremium) return PalmReadingAccess.unlocked;

    if (unlockedIds.length >= freeReadingAllowance) {
      return PalmReadingAccess.needsPremium;
    }

    return hasSharedScan
        ? PalmReadingAccess.unlocked
        : PalmReadingAccess.needsShare;
  }

  /// Free readings still available, for the "1 left" copy.
  static int readingsRemaining({
    required Set<String> unlockedIds,
    required bool isPremium,
  }) {
    if (isPremium) return freeReadingAllowance;
    final used = unlockedIds.length;
    return used >= freeReadingAllowance ? 0 : freeReadingAllowance - used;
  }
}
