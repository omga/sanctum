import 'package:sanctum/src/domain/models/conversation.dart';

/// How many questions one purchased conversation is worth.
///
/// ## Why a turn cap at all
///
/// Every answer costs real money in inference. `roadmap.md` §2 makes the
/// point about subscriptions — "a business that loses more the more
/// successful it is" — and the same arithmetic applies to a flat-priced
/// conversation with no ceiling. A cap makes the cost of a sale knowable
/// before the sale.
///
/// It is also the honest version of the product. "Ten questions about
/// you and Alex" is a thing somebody can decide whether they want. "Chat
/// for an hour" is a thing whose value depends on how fast they type.
///
/// ## Why a turn is an exchange, not a message
///
/// One question, one answer. Counting messages would charge twice for an
/// answer that arrives in two parts, and would let a user spend their
/// balance by saying "thanks". The user's mental model is questions
/// asked, so that is the unit.
///
/// ## Why the number lives here
///
/// It is the price of the product and the cost ceiling of a sale in one
/// integer, and it will be tuned with real data. Pure, so tuning it is
/// one constant and a test rather than an archaeology expedition through
/// the view models.
abstract final class ConversationBudget {
  /// Questions included in one purchased conversation.
  ///
  /// A starting guess, explicitly. `advisor.md` §10 lists it as open.
  static const int turnsPerConversation = 10;

  /// Whether [conversation] has a question left in it.
  static bool canAsk(Conversation conversation) =>
      turnsRemaining(conversation) > 0;

  /// Questions left.
  ///
  /// Clamped at zero rather than allowed to go negative: a conversation
  /// whose cap was lowered under it — which is what tuning this constant
  /// downward does to everybody mid-conversation — must read as spent,
  /// not as owing questions back.
  static int turnsRemaining(Conversation conversation) {
    final left = turnsPerConversation - conversation.turnsUsed;
    return left < 0 ? 0 : left;
  }

  /// Whether every question has been asked.
  static bool isSpent(Conversation conversation) =>
      turnsRemaining(conversation) == 0;

  /// The conversation after a completed exchange.
  ///
  /// Called on `ChatCompleted` and never on `ChatFailed`: an answer that
  /// did not arrive has not been sold. See `chat_transport.dart`.
  static Conversation spendTurn(Conversation conversation) =>
      conversation.copyWith(turnsUsed: conversation.turnsUsed + 1);

  /// Whether the user should be warned that they are nearly out.
  ///
  /// Warning matters more than it looks: somebody who discovers the cap
  /// by hitting it mid-thought experiences it as the app cutting them
  /// off, and somebody who was told at two remaining experiences it as a
  /// budget they managed. Same cap, different review.
  static bool isNearlySpent(Conversation conversation) {
    final left = turnsRemaining(conversation);
    return left > 0 && left <= warnAtRemaining;
  }

  /// Where the warning starts.
  static const int warnAtRemaining = 2;
}
