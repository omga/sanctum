/// What the user may do with a given match.
enum CompatibilityAccess {
  /// Show the reading.
  unlocked,

  /// Blur it until they have invited someone.
  needsInvite,

  /// Blur it and send them to the paywall.
  needsPremium,
}

/// Who gets to see a compatibility reading.
///
/// ## The shape of the offer
///
/// The first reading is bought with an invite, the second with money.
/// That ordering is deliberate: the invite is the acquisition channel
/// this whole product strategy rests on, and asking for it *before* the
/// reveal — while curiosity is at its peak and the user has not yet had
/// the thing they came for — is the only moment it will ever convert.
/// Asking afterwards is asking someone to pay for something they already
/// have.
///
/// ## Why a revealed match stays revealed
///
/// The revealed ids are a set, not a count, and rule one is that
/// anything
/// already revealed stays revealed forever. Without that, re-opening the
/// one free reading a week later would consume the free slot a second
/// time and then demand money for a screen the user has already seen —
/// which reads, correctly, as a bait and switch.
abstract final class CompatibilityGate {
  /// How many readings a non-premium user gets for inviting someone.
  static const int freeRevealAllowance = 1;

  /// Decides access to [matchId].
  static CompatibilityAccess decide({
    required String matchId,
    required Set<String> revealedIds,
    required bool hasSharedInvite,
    required bool isPremium,
  }) {
    if (revealedIds.contains(matchId)) return CompatibilityAccess.unlocked;
    if (isPremium) return CompatibilityAccess.unlocked;

    if (revealedIds.length >= freeRevealAllowance) {
      return CompatibilityAccess.needsPremium;
    }

    return hasSharedInvite
        ? CompatibilityAccess.unlocked
        : CompatibilityAccess.needsInvite;
  }

  /// Free reveals still available, for the "1 left" copy on the tab.
  static int revealsRemaining({
    required Set<String> revealedIds,
    required bool isPremium,
  }) {
    if (isPremium) return freeRevealAllowance;
    final used = revealedIds.length;
    return used >= freeRevealAllowance ? 0 : freeRevealAllowance - used;
  }
}
