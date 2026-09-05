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
/// ## Why it is bounded
///
/// There is no per-conversation cap any more — the allowance is a shared
/// balance (`MessageBudget`), so one long conversation is a thing a
/// paying user can absolutely have. Twenty messages is the point where
/// re-sending the whole transcript every turn starts costing more than
/// the answer is worth, and the failure this prevents is a bill rather
/// than a crash.
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
