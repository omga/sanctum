import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/services/conversation_budget.dart';

/// What the user may do with a conversation about one subject.
enum ConversationAccess {
  /// They own it and it has questions left. Open it.
  open,

  /// They own it and every question is spent. The transcript still
  /// opens; asking again needs another purchase.
  spent,

  /// A subscriber who has not claimed this period's conversation. Offer
  /// it at no charge, behind one deliberate tap.
  includedWithPremium,

  /// Show the offer.
  forSale,
}

/// Who gets to open a conversation, and about what.
///
/// ## Why this is not `ReportGate`
///
/// `ReportGate` sells a *document*: bought once, owned forever,
/// nothing is consumed by reading it. This sells *questions*, which cost
/// money every time one is answered. Folding them together would mean
/// every change to the chat economy risked changing what a paying
/// customer owns of a document they already read — the one thing in this
/// app that must not move by accident.
///
/// The two agree on rule one, though, and it is the same rule: **owned
/// stays owned**.
///
/// ## What is bought, and what is kept
///
/// The unit sold is a conversation about one subject — this pairing,
/// this report, this day — keyed by [ConversationSubject.key], which is
/// deterministic for the same reason `CompatibilityMatch.id` is: coming
/// back to something already paid for must be recognised, not charged
/// for twice.
///
/// **The turns are spent; the transcript is permanent.** A conversation
/// whose questions are used up still opens, still scrolls, and still
/// reads. Anything else means somebody pays for ten answers and can
/// later read none of them, which is a refund request with extra steps.
/// [ConversationAccess.spent] is that state, and it is deliberately not
/// the same as [ConversationAccess.forSale].
///
/// ## Why a subscriber's allowance renews and the report's does not
///
/// `ReportGate` includes one report *ever*, because a renewing document
/// allowance is a credit ledger and `roadmap.md` §1 rejects one. A
/// conversation allowance renews monthly because chat is consumable by
/// nature and a once-ever question would form no habit at all — which is
/// the entire mechanic that makes the subscription drive credit sales
/// rather than substitute for them (`roadmap.md` §2).
///
/// It is still not a ledger: the storage is one nullable period string,
/// there is no balance, nothing accrues, and an unclaimed month is gone
/// rather than banked. That is the difference between an allowance and
/// an economy, and `advisor.md` §6 says to build the economy last.
abstract final class ConversationGate {
  /// Decides access to a conversation about [subjectKey].
  ///
  /// [includedPeriod] is the period a subscriber last claimed their
  /// included conversation in, or null if they never have. [period] is
  /// now, in the same form — see [periodFor].
  static ConversationAccess decide({
    required String subjectKey,
    required Set<String> ownedKeys,
    required String period,
    required String? includedPeriod,
    required bool isPremium,
    required int turnsUsed,
  }) {
    if (ownedKeys.contains(subjectKey)) {
      // Ownership is checked before the budget, so a spent conversation
      // never falls back to forSale and never hides its own transcript.
      return turnsUsed >= ConversationBudget.turnsPerConversation
          ? ConversationAccess.spent
          : ConversationAccess.open;
    }

    if (hasIncludedConversation(
      isPremium: isPremium,
      period: period,
      includedPeriod: includedPeriod,
    )) {
      return ConversationAccess.includedWithPremium;
    }

    return ConversationAccess.forSale;
  }

  /// Whether the subject is the user's, however they got it.
  ///
  /// **A claimed conversation is not taken back when a subscription
  /// lapses**, for the same reason a claimed report is not: clawing back
  /// something somebody has already read is what produces refunds and
  /// one-star reviews.
  static bool isOwned({
    required String subjectKey,
    required Set<String> ownedKeys,
  }) => ownedKeys.contains(subjectKey);

  /// Whether the transcript may be read.
  ///
  /// Owning it is the whole condition. Spent is still owned.
  static bool canRead({
    required String subjectKey,
    required Set<String> ownedKeys,
  }) => isOwned(subjectKey: subjectKey, ownedKeys: ownedKeys);

  /// Whether a subscriber still has this period's conversation to spend.
  static bool hasIncludedConversation({
    required bool isPremium,
    required String period,
    required String? includedPeriod,
  }) => isPremium && includedPeriod != period;

  /// The period key for [date] — the unit a subscriber's allowance
  /// renews on.
  ///
  /// A calendar month rather than 30 days from the claim, because "one a
  /// month" is a promise somebody can hold in their head, and a rolling
  /// window is a support question about why it is not available yet.
  static String periodFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
