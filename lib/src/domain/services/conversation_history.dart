import 'package:sanctum/src/domain/models/conversation.dart';

/// How much of a transcript travels with the next question.
///
/// ## Why the whole thing is not simply sent
///
/// The proxy is stateless by contract — it keeps nothing between calls,
/// which is how "no conversation history on a server the app cannot
/// delete from" is true by construction rather than by policy
/// (`advisor.md` §5). The cost of that design is that the client re-sends
/// the context every turn, and an unbounded transcript means a request
/// that grows quadratically over a conversation.
///
/// ## Why it is bounded even though nothing is long enough to need it
///
/// `ConversationBudget.turnsPerConversation` is 10, so today every
/// transcript already fits inside [maxMessages] and this function is a
/// no-op. It exists anyway because the cap is explicitly a number to be
/// tuned, and because person-to-person chat has no cap at all — and the
/// failure it prevents is not a crash but a bill.
abstract final class ConversationHistory {
  /// The most messages that travel with one question.
  ///
  /// Twenty is ten exchanges, which is the whole of a conversation at
  /// the current cap.
  static const int maxMessages = 20;

  /// The tail of [messages], oldest first, at most [maxMessages] long.
  ///
  /// The *tail* rather than a summary: an advisor that has quietly
  /// forgotten the start of a conversation is a bad experience, but one
  /// that answers from a lossy summary of it is a worse one, because the
  /// user cannot tell which parts it kept.
  static List<ChatMessage> forSend(List<ChatMessage> messages) {
    if (messages.length <= maxMessages) return messages;
    return messages.sublist(messages.length - maxMessages);
  }

  /// Whether anything would be dropped.
  static bool isTrimmed(List<ChatMessage> messages) =>
      messages.length > maxMessages;
}
