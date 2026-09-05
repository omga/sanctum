import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/data/services/advisor/scripted_chat_transport.dart';
import 'package:sanctum/src/domain/models/advisor_context.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/services/chat_transport.dart';
import 'package:sanctum/src/domain/services/conversation_budget.dart';
import 'package:sanctum/src/domain/services/message_redaction.dart';

part 'advisor_view_model.g.dart';

/// Whatever is answering questions right now.
///
/// Scripted until the proxy exists (`advisor.md` §8 step 4). Overriding
/// this one provider is the whole swap — no widget, view model or test
/// below it knows which implementation it is talking to, which is what
/// the [ChatTransport] interface was for.
@riverpod
ChatTransport chatTransport(Ref ref) => const ScriptedChatTransport();

/// One conversation, as the screen needs it.
class AdvisorUiState {
  /// Creates the state.
  const AdvisorUiState({
    required this.conversation,
    required this.messages,
    this.streamingId,
    this.failure,
    this.lastQuestion,
  });

  /// The conversation itself, carrying the turns spent.
  final Conversation conversation;

  /// Every message, oldest first.
  final List<ChatMessage> messages;

  /// The id of the answer currently being written, if one is.
  final String? streamingId;

  /// Why the last send failed, when it did.
  final AdvisorFailure? failure;

  /// The question that failed, kept so a retry needs no retyping.
  ///
  /// Losing somebody's sentence to a dropped connection and asking them
  /// to write it again is the single most irritating thing a chat screen
  /// can do, and it is entirely avoidable.
  final String? lastQuestion;

  /// Whether an answer is arriving.
  bool get isStreaming => streamingId != null;

  /// Questions left in this conversation.
  int get turnsRemaining => ConversationBudget.turnsRemaining(conversation);

  /// Whether every question has been asked.
  bool get isSpent => ConversationBudget.isSpent(conversation);

  /// Whether to show the remaining count.
  bool get showsTurnCount =>
      ConversationBudget.isNearlySpent(conversation);

  /// Whether the composer accepts input.
  bool get canAsk => !isStreaming && !isSpent;

  /// A copy with the given fields replaced.
  ///
  /// [failure] and [streamingId] clear rather than persist when omitted:
  /// both describe one send, and carrying either into the next state is
  /// how an error banner outlives the thing it was about.
  AdvisorUiState copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    String? streamingId,
    AdvisorFailure? failure,
    String? lastQuestion,
  }) => AdvisorUiState(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    streamingId: streamingId,
    failure: failure,
    lastQuestion: lastQuestion,
  );
}

/// Drives one conversation.
///
/// ## Why the family key is the match and not an id
///
/// Same reason `ReportController`'s is: `CompatibilityMatch.id` is built
/// from both people's names and birth dates, so passing it around as a
/// routing key puts exactly that into places — URLs, breadcrumbs, logs —
/// that this feature exists to keep it out of.
///
/// ## Where the transcript lives
///
/// In this notifier, and nowhere else, until `advisor.md` §8 step 3 adds
/// the Drift tables. Leaving the screen loses the conversation. That is
/// a deliberate gap rather than an oversight: storage is a schema
/// migration and a delete flow, and doing it before the screen exists
/// would be guessing at what needs storing.
@riverpod
class AdvisorController extends _$AdvisorController {
  @override
  AdvisorUiState build(CompatibilityMatch match) => AdvisorUiState(
    conversation: Conversation(
      id: 'advisor:${match.id}',
      kind: ConversationKind.advisor,
      subject: MatchSubject(match.id),
      startedAt: DateTime.now(),
    ),
    messages: const [],
  );

  /// Asks [question], which is what the user typed or tapped.
  ///
  /// [question] is the *display* form and may contain names. What
  /// reaches the transport does not — see [_outbound].
  Future<void> ask(String question, {required String languageCode}) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || !state.canAsk) return;

    final now = DateTime.now();
    final asked = ChatMessage(
      id: 'q${now.microsecondsSinceEpoch}',
      conversationId: state.conversation.id,
      author: MessageAuthor.you,
      body: trimmed,
      at: now,
    );
    final answerId = 'a${now.microsecondsSinceEpoch}';
    final answer = ChatMessage(
      id: answerId,
      conversationId: state.conversation.id,
      author: MessageAuthor.counterpart,
      body: '',
      at: now,
      status: MessageStatus.sending,
    );

    state = state.copyWith(
      messages: [...state.messages, asked, answer],
      streamingId: answerId,
      lastQuestion: trimmed,
    );

    // The history handed over is the redacted one, all the way back:
    // scrubbing only the newest message would send every earlier name
    // again on the next turn.
    final history = [
      for (final message in state.messages)
        if (message.id != answerId)
          message.copyWith(body: _outbound(message.body)),
    ];

    final stream = ref.read(chatTransportProvider).send(
      conversation: state.conversation,
      history: history,
      context: AdvisorContext.forMatch(match, languageCode: languageCode),
    );

    await for (final chunk in stream) {
      switch (chunk) {
        case ChatDelta(:final text):
          _replace(answerId, (m) => m.appending(text));
        case ChatCompleted():
          _replace(answerId, (m) => m.copyWith(status: MessageStatus.sent));
          // The turn is spent here and only here. A failed send has cost
          // the user nothing, so it must cost them nothing.
          state = state.copyWith(
            conversation: ConversationBudget.spendTurn(state.conversation),
            messages: state.messages,
          );
        case ChatFailed(:final failure):
          state = state.copyWith(
            messages: [
              for (final message in state.messages)
                if (message.id != answerId)
                  message
                else
                  message.copyWith(status: MessageStatus.failed),
            ],
            failure: failure is AdvisorFailure
                ? failure
                : const AdvisorFailure(
                    'Send failed.',
                    kind: AdvisorFailureKind.server,
                  ),
            lastQuestion: trimmed,
          );
          return;
      }
    }
  }

  /// Re-sends the question that failed.
  Future<void> retry({required String languageCode}) async {
    final question = state.lastQuestion;
    if (question == null) return;

    // Drop the failed exchange first, so a retry does not stack a second
    // copy of the question under the first.
    final failedIndex = state.messages.lastIndexWhere(
      (m) => m.status == MessageStatus.failed,
    );
    if (failedIndex > 0) {
      state = state.copyWith(
        messages: state.messages.sublist(0, failedIndex - 1),
      );
    }
    await ask(question, languageCode: languageCode);
  }

  /// Clears the error without retrying.
  void dismissFailure() => state = state.copyWith(messages: state.messages);

  void _replace(String id, ChatMessage Function(ChatMessage) update) {
    state = state.copyWith(
      messages: [
        for (final message in state.messages)
          if (message.id == id) update(message) else message,
      ],
      streamingId: state.streamingId,
      failure: state.failure,
      lastQuestion: state.lastQuestion,
    );
  }

  /// The form of [text] that may leave the device.
  ///
  /// Belt and braces over [AdvisorContext]: the context type cannot
  /// carry a name, and this makes sure the sentence beside it cannot
  /// either. See `message_redaction.dart`.
  String _outbound(String text) => MessageRedaction.redact(
    text,
    names: {
      match.them.name: MessageRedaction.placeholder,
      match.you.name: MessageRedaction.selfPlaceholder,
    },
  );
}
