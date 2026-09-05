import 'package:meta/meta.dart';
import 'package:sanctum/src/domain/models/advisor_context.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/models/transit.dart';
import 'package:sanctum/src/domain/services/conversation_starters.dart';
import 'package:sanctum/src/domain/services/message_redaction.dart';

/// What one conversation is about, with everything it needs to run.
///
/// ## Why this exists rather than a second screen
///
/// The advisor screen used to be keyed on a `CompatibilityMatch`, which
/// made "ask about a pairing" the only conversation the app could have.
/// Adding "ask about yourself" that way would mean a second screen, a
/// second controller and a second set of the same tests — for a feature
/// whose entire difference from the first is *which facts get sent*.
///
/// So the four things that actually differ are gathered here: the
/// storage subject, the payload, the suggested questions, and the names
/// to strip on the way out. Everything downstream — the transcript, the
/// budget, the streaming, the failure handling, the delete — is written
/// once and does not know which kind it is looking at.
///
/// ## Why equality is the subject key
///
/// This is a Riverpod family argument, so two topics that mean the same
/// conversation must be equal or the screen gets a fresh empty
/// transcript every rebuild. [ConversationSubject.key] is already the
/// deterministic identity used for storage and ownership, so it is the
/// honest thing to compare — and it means a `SelfTopic` built this
/// morning and one built this afternoon are the same conversation,
/// which is the whole point of `SelfSubject` not being date-keyed.
@immutable
sealed class AdvisorTopic {
  /// Base constructor.
  const AdvisorTopic();

  /// Where the transcript is stored, and what it is about.
  ConversationSubject get subject;

  /// The row id for this conversation.
  String get conversationId => 'advisor:${subject.key}';

  /// The facts that may be sent, in [languageCode].
  AdvisorContext contextFor(String languageCode);

  /// Which questions to suggest before anything has been asked.
  List<ConversationStarter> get starters;

  /// Names to rewrite out of anything the user types, as name to
  /// replacement.
  ///
  /// Belt and braces over [AdvisorContext], which has no field a name
  /// could occupy. This covers the sentence beside it — see
  /// `MessageRedaction`.
  Map<String, String> get outboundNames;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvisorTopic &&
          other.runtimeType == runtimeType &&
          other.subject.key == subject.key;

  @override
  int get hashCode => Object.hash(runtimeType, subject.key);
}

/// A conversation about a compatibility reading.
final class MatchTopic extends AdvisorTopic {
  /// Creates a topic for [match].
  const MatchTopic(this.match);

  /// The pairing being discussed.
  final CompatibilityMatch match;

  @override
  ConversationSubject get subject => MatchSubject(match.id);

  @override
  AdvisorContext contextFor(String languageCode) =>
      AdvisorContext.forMatch(match, languageCode: languageCode);

  @override
  List<ConversationStarter> get starters =>
      ConversationStarters.forMatch(match);

  @override
  Map<String, String> get outboundNames => {
    match.them.name: MessageRedaction.placeholder,
    match.you.name: MessageRedaction.selfPlaceholder,
  };
}

/// A conversation about the user's own chart.
///
/// [today] is nullable on purpose: the transit needs a birth date, the
/// app can be reached without one, and the natal questions still work
/// without it. A missing sky is a smaller conversation, not a broken
/// one.
final class SelfTopic extends AdvisorTopic {
  /// Creates a topic for [you].
  const SelfTopic({required this.you, this.today});

  /// The user, as the app already computes them for a pairing.
  final MatchPerson you;

  /// Today's sky, when there is a birth date to read it against.
  final DailyTransitReading? today;

  @override
  ConversationSubject get subject => const SelfSubject();

  @override
  AdvisorContext contextFor(String languageCode) => AdvisorContext.forSelf(
    you: you,
    today: today,
    languageCode: languageCode,
  );

  @override
  List<ConversationStarter> get starters => ConversationStarters.forSelf(today);

  /// Only the user's own name, and it becomes "me".
  ///
  /// There is no second person in this conversation, so there is
  /// nothing for "them" to refer to — mapping a stray name to it would
  /// invent a person the chart does not contain.
  @override
  Map<String, String> get outboundNames => {
    you.name: MessageRedaction.selfPlaceholder,
  };
}
