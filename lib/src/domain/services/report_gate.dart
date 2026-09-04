import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/services/compatibility_gate.dart';

/// What the user may do with a given report.
enum ReportAccess {
  /// They own it. Show the document.
  owned,

  /// A subscriber who has not spent their included report yet. Show the
  /// document behind one deliberate tap, at no charge.
  includedWithPremium,

  /// They do not own it and have nothing to spend. Show the offer.
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
/// ## A subscriber's first report is included
///
/// Not because the report is a subscription feature — it is not, and
/// `roadmap.md` §1 exists to find out whether it sells on its own — but
/// because of where the second ask landed without it. The compatibility
/// lock card promises that Premium "reads you against anyone, as often
/// as you like"; a user who buys on that promise reaches the reading
/// they just paid for and finds a second price at the bottom of it,
/// seconds later, on the same screen. That reads as a bait and switch
/// whatever the SKU's merits, and freshly-converted subscribers are both
/// the most alert to it and the most likely to refund.
///
/// One included report removes that moment and keeps the revenue line:
/// the *second* report a subscriber wants is still sold, and by then the
/// ask reads as "you have had one" rather than "you just paid".
///
/// **Once ever, not once per period.** A renewing allowance is a credit
/// ledger — balances, expiry, refunds, what happens on a second device —
/// which §1 rejects explicitly. The storage is a single nullable id
/// rather than a count precisely because there is exactly one, and the
/// copy says "your first report is included" rather than naming a rate,
/// so becoming more generous later never means taking something away.
///
/// The experiment survives this. The offer appears on any *revealed*
/// reading, including the one a non-subscriber unlocks with an invite,
/// so the price-elasticity question is answered where nearly all the
/// traffic is — and subscribers still meet the price on their second
/// report.
abstract final class ReportGate {
  /// Decides access to the report for [matchId].
  ///
  /// [includedReportId] is the pairing a subscriber spent their included
  /// report on, or null if they have not spent it. An id rather than a
  /// flag so that "what do they own" stays one question, and so a
  /// claimed report can be told from a bought one in the data.
  static ReportAccess decide({
    required String matchId,
    required Set<String> purchasedIds,
    required String? includedReportId,
    required bool isPremium,
  }) {
    if (isOwned(
      matchId: matchId,
      purchasedIds: purchasedIds,
      includedReportId: includedReportId,
    )) {
      return ReportAccess.owned;
    }

    // Only offered while it is unspent. A subscriber who has already
    // claimed theirs sees the price, which is the whole point of
    // including one rather than all of them.
    if (isPremium && includedReportId == null) {
      return ReportAccess.includedWithPremium;
    }

    return ReportAccess.forSale;
  }

  /// Whether [matchId] is already the user's, however they got it.
  ///
  /// **A claimed report is not given back when a subscription lapses.**
  /// Rule one of this gate is that owned stays owned: clawing back a
  /// document somebody has read is what produces refunds and one-star
  /// reviews. It does mean a month's subscription can be turned into a
  /// permanent report, which is the same small, deliberate leak the free
  /// reveal allowance already accepts.
  static bool isOwned({
    required String matchId,
    required Set<String> purchasedIds,
    required String? includedReportId,
  }) => purchasedIds.contains(matchId) || includedReportId == matchId;

  /// Whether [matchId] was paid for in money.
  ///
  /// Distinct from [isOwned] on purpose: a report claimed with a
  /// subscription's included slot is owned but was never bought, and the
  /// receipt history must not claim a purchase that never happened.
  static bool isPurchased({
    required String matchId,
    required Set<String> purchasedIds,
  }) => purchasedIds.contains(matchId);

  /// Whether a subscriber still has their included report to spend.
  static bool hasIncludedReport({
    required bool isPremium,
    required String? includedReportId,
  }) => isPremium && includedReportId == null;
}
