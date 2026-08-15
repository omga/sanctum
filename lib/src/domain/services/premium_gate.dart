import 'package:sanctum/src/domain/services/paywall_trigger.dart';

/// The features premium unlocks.
enum PremiumFeature {
  /// The sound library beyond the free allowance.
  soundLibrary,

  /// The moon rituals.
  rituals,

  /// Every card previously drawn.
  oracleHistory,

  /// Energy and streak trends over time.
  insights,
}

/// Where the free/premium line sits.
///
/// ## The one rule
///
/// The daily loop is never gated. The card, the affirmation, the moon
/// phase and the journal stay free forever, because that loop is what
/// brings someone back tomorrow — and someone who comes back is the only
/// person who ever subscribes. Gating the habit to sell the habit is the
/// mistake that kills apps in this category.
///
/// What premium sells is *depth*: more sound, the rituals, and the
/// record of what you have already done.
abstract final class PremiumGate {
  /// Sound sessions playable without paying.
  static const int freeSessionAllowance = PaywallTrigger.freeSessionAllowance;

  /// Whether [feature] requires premium at all.
  ///
  /// Everything in [PremiumFeature] does, by definition — this exists so
  /// call sites read as a question about the gate rather than a bare
  /// `!isPremium`, and so a future "free for a week" experiment has one
  /// place to live.
  static bool requiresPremium(PremiumFeature feature) => true;

  /// Whether the session at [index] in the catalogue is free.
  ///
  /// Index-based rather than a flag in the JSON so that the free set is a
  /// product decision in code, not content anyone has to re-author.
  static bool isSessionFree(int index) => index < freeSessionAllowance;

  /// Whether [feature] is available to a user with this entitlement.
  static bool isUnlocked({
    required PremiumFeature feature,
    required bool isPremium,
  }) => isPremium || !requiresPremium(feature);
}
