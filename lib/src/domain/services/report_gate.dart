import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/services/compatibility_gate.dart';

/// What the user may do with a given report.
enum ReportAccess {
  /// They own it. Show the document.
  owned,

  /// They do not. Show the offer.
  forSale,
}

/// Who gets to read a relationship report.
///
/// ## Why this is not [CompatibilityGate]
///
/// The compatibility gate sells *access to a reading* and its currency is
/// an invite, once, as an acquisition mechanic. This sells a separate
/// product about one named person, for money, repeatedly. Folding the two
/// into one decision would mean every change to the acquisition loop
/// risked changing what a paying customer owns, which is the one thing in
/// this app that must not move by accident.
///
/// ## Why a purchase is per pairing and permanent
///
/// The unit sold is "You & X", so the thing owned is a match id — which
/// [CompatibilityMatch.id] was already built to be: deterministic from
/// both people's charts, and documented as existing so that re-opening a
/// reading the user paid for is not charged twice.
///
/// There is no expiry and no consumption. A consumable in store terms is
/// bought once and granted forever here, because the customer's mental
/// model is that they bought *a document*, and a document you can no
/// longer open is a refund request.
abstract final class ReportGate {
  /// Whether a Sanctum Premium subscription includes the one-off reports.
  ///
  /// **False, deliberately.** `roadmap.md` §1 exists to answer whether
  /// relationship intent monetises *beyond* the subscription. If Premium
  /// included reports then no subscriber would ever buy one, and the
  /// only conversion data would come from non-subscribers — which is the
  /// half of the audience least likely to pay for anything, and cannot
  /// answer the question the SKU was built to ask.
  ///
  /// It is a named constant rather than an inlined `false` because it is
  /// a pricing decision, not a fact about the code: flipping it is one
  /// line here plus copy on the offer card, and the tests below pin both
  /// behaviours so the flip cannot break quietly.
  static const bool premiumIncludesReports = false;

  /// Decides access to the report for [matchId].
  static ReportAccess decide({
    required String matchId,
    required Set<String> purchasedIds,
    required bool isPremium,
  }) {
    if (purchasedIds.contains(matchId)) return ReportAccess.owned;
    if (isPremium && premiumIncludesReports) return ReportAccess.owned;
    return ReportAccess.forSale;
  }

  /// Whether [matchId] has been bought.
  ///
  /// Distinct from [decide] on purpose: a subscriber who has not bought
  /// this report still has not bought it, and the day
  /// [premiumIncludesReports] flips, the receipt history must not start
  /// claiming purchases that never happened.
  static bool isPurchased({
    required String matchId,
    required Set<String> purchasedIds,
  }) => purchasedIds.contains(matchId);
}
