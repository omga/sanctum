/// A conversation, and the messages in it.
///
/// ## Why nothing here says "advisor"
///
/// `roadmap.md` §2 ships an AI astrologer. The intention is that the
/// same screens later carry person-to-person chat, and the difference
/// between those two products is *who answers* — which is a transport
/// concern, not a modelling one.
///
/// So the author of a message is [MessageAuthor.counterpart], never
/// `.advisor`. Swapping in a peer transport changes the implementation
/// behind `ChatTransport` and the [Conversation.kind] flag; every widget,
/// view model, table and test that touches these types keeps working
/// unchanged. Naming the counterpart after the first implementation is
/// the kind of decision that is free today and a rename across forty
/// files later.
library;

/// Who is on the other side of a conversation.
///
/// The domain does not branch on this. Exactly two things do, both
/// outside it: an advisor conversation must carry the AI disclosure
/// (EU AI Act Art. 50 — see `advisor.md` §1), and it is gated on a
/// purchase. A conversation with a person is neither.
enum ConversationKind {
  /// An AI astrologer answering from computed positions.
  advisor,

  /// Another human being. Not built; the reason the seam exists.
  person,
}

/// Who wrote a message.
enum MessageAuthor {
  /// The user.
  you,

  /// Whoever is answering — the advisor today, a person later.
  counterpart,
}

/// Where a message is in its journey.
///
/// A message the user has typed exists before it has been answered, and
/// it must be on screen while it is in flight. Sending is therefore a
/// state of a real message rather than the absence of one.
enum MessageStatus {
  /// Written, not yet answered.
  sending,

  /// Delivered, and answered.
  sent,

  /// It did not get through. Re-sendable.
  failed,
}

/// What a conversation is about.
///
/// ## Why the subject is a type and not a string
///
/// The subject is doing three jobs at once: it selects which facts get
/// sent to the model, it is the unit of ownership when a conversation is
/// bought, and it decides which screen offers to open one. A sealed
/// class makes the complete list of those jobs checkable by the
/// compiler, exactly as `AppFailure` does for failure.
///
/// [key] is the storage and ownership form. It follows the same rule as
/// `CompatibilityMatch.id` and the owned-report ids: deterministic, so
/// re-opening something the user has already paid for is recognised
/// rather than charged for twice.
sealed class ConversationSubject {
  /// Base constructor.
  const ConversationSubject();

  /// Stable identity, used for ownership and storage.
  String get key;
}

/// A conversation about a compatibility reading.
final class MatchSubject extends ConversationSubject {
  /// Creates a subject for [matchId].
  const MatchSubject(this.matchId);

  /// The pairing, as `CompatibilityMatch.id`.
  final String matchId;

  @override
  String get key => 'match:$matchId';
}

/// A conversation about a relationship report the user owns.
///
/// Distinct from [MatchSubject] even though both name a pairing, because
/// the report contains materially more computed detail and the person
/// asking has already paid for depth once. What reaches the model
/// differs; the ownership unit differs; therefore the type differs.
final class ReportSubject extends ConversationSubject {
  /// Creates a subject for the report on [matchId].
  const ReportSubject(this.matchId);

  /// The pairing, as `CompatibilityMatch.id`.
  final String matchId;

  @override
  String get key => 'report:$matchId';
}

/// A conversation about one day's transit.
final class DaySubject extends ConversationSubject {
  /// Creates a subject for [date].
  const DaySubject(this.date);

  /// The local calendar day.
  final DateTime date;

  @override
  String get key =>
      'day:${date.year}-${date.month}-${date.day}';
}

/// A conversation about nothing in particular.
///
/// Deliberately last, and deliberately not the entry point anybody is
/// steered towards: `roadmap.md` §2 is explicit that a question the user
/// already has beats a blank box, which is why there is no generic chat
/// tab. It exists because a user who has finished asking about a pairing
/// will type something unrelated eventually, and refusing that is worse
/// than answering it.
final class OpenSubject extends ConversationSubject {
  /// Creates the open subject.
  const OpenSubject();

  @override
  String get key => 'open';
}

/// One message.
class ChatMessage {
  /// Creates a message.
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.author,
    required this.body,
    required this.at,
    this.status = MessageStatus.sent,
  });

  /// Stable id, assigned when the message is created.
  final String id;

  /// The conversation it belongs to.
  final String conversationId;

  /// Who wrote it.
  final MessageAuthor author;

  /// The text.
  ///
  /// For a counterpart message being streamed, this grows as chunks
  /// arrive — the view model replaces the message rather than mutating
  /// it, so the UI state stays immutable all the way down.
  final String body;

  /// When it was written.
  final DateTime at;

  /// Where it is in its journey.
  final MessageStatus status;

  /// A copy with [body] and [status] replaced.
  ChatMessage copyWith({String? body, MessageStatus? status}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    author: author,
    body: body ?? this.body,
    at: at,
    status: status ?? this.status,
  );

  /// A copy with [text] appended, for streaming.
  ChatMessage appending(String text) => copyWith(body: body + text);
}

/// A conversation.
///
/// Holds no messages: they are a separate table with their own lifetime,
/// and a list of them on this object would mean loading an entire
/// transcript to render a row in a list of conversations.
class Conversation {
  /// Creates a conversation.
  const Conversation({
    required this.id,
    required this.kind,
    required this.subject,
    required this.startedAt,
    this.turnsUsed = 0,
  });

  /// Stable id.
  final String id;

  /// Who is answering.
  final ConversationKind kind;

  /// What it is about.
  final ConversationSubject subject;

  /// When it was opened.
  final DateTime startedAt;

  /// How many times the user has asked something and been answered.
  ///
  /// A *turn* is one exchange, not one message: the unit the user buys
  /// and the unit that costs money in inference are the same thing, and
  /// counting messages would mean an answer that arrives in two parts
  /// costs twice. See `ConversationBudget`.
  final int turnsUsed;

  /// A copy with [turnsUsed] replaced.
  Conversation copyWith({int? turnsUsed}) => Conversation(
    id: id,
    kind: kind,
    subject: subject,
    startedAt: startedAt,
    turnsUsed: turnsUsed ?? this.turnsUsed,
  );
}
