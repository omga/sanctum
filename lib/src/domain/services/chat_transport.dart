import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/domain/models/advisor_context.dart';
import 'package:sanctum/src/domain/models/conversation.dart';

/// One piece of an answer arriving.
///
/// ## Why a stream and not a `Future<String>`
///
/// Token-by-token rendering is most of whether chat feels alive, and it
/// is not a decoration that can be added later: retrofitting it onto a
/// future means rewriting the view model, the message model and every
/// widget test that asserts on a finished string. The interface streams
/// from the first day, and the scripted transport streams too, so the UI
/// is built against the real shape long before a proxy exists.
///
/// ## Why failure is a chunk and not a thrown exception
///
/// Same reason repositories return `Result`: a caller that forgets to
/// handle failure should be a compile error, not a crash in front of
/// somebody who has paid for the conversation. A stream that completes
/// with [ChatFailed] can be switched over exhaustively.
sealed class ChatChunk {
  /// Base constructor.
  const ChatChunk();
}

/// More text for the answer being written.
final class ChatDelta extends ChatChunk {
  /// Creates a delta.
  const ChatDelta(this.text);

  /// The text to append. Never the whole answer so far.
  final String text;
}

/// The answer is finished, and the turn is spent.
final class ChatCompleted extends ChatChunk {
  /// Creates a completion.
  const ChatCompleted();
}

/// The answer did not arrive.
///
/// The turn is **not** spent. A user who paid for ten questions and got
/// nine answers plus one network error has been short-changed by one,
/// and will say so in a review.
final class ChatFailed extends ChatChunk {
  /// Creates a failure.
  const ChatFailed(this.failure);

  /// Why.
  final AppFailure failure;
}

/// Whatever is answering.
///
/// Today: an AI astrologer behind a proxy. Later, possibly: another
/// person. The domain does not know which, which is the entire reason
/// this interface exists rather than a concrete `AdvisorService` —
/// `advisor.md` §2.
abstract interface class ChatTransport {
  /// Sends [history] and asks for the next answer.
  ///
  /// [history] is the whole conversation, oldest first, ending with the
  /// user's new question. The transport is stateless by contract: it
  /// keeps nothing between calls, which is how "no conversation history
  /// on a server the app cannot delete from" is true by construction
  /// rather than by policy.
  ///
  /// [context] is the computed chart material, or null for a
  /// conversation with no subject. It is the only place personal-looking
  /// data could enter, and [AdvisorContext] is built so that it cannot —
  /// see that class.
  Stream<ChatChunk> send({
    required Conversation conversation,
    required List<ChatMessage> history,
    required AdvisorContext? context,
  });
}
