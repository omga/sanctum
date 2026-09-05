import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/conversation_repository.dart';
import 'package:sanctum/src/data/services/advisor/proxy_chat_transport.dart';
import 'package:sanctum/src/data/services/advisor/scripted_chat_transport.dart';
import 'package:sanctum/src/domain/models/advisor_context.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/services/chat_transport.dart';
import 'package:sanctum/src/domain/services/conversation_budget.dart';
import 'package:sanctum/src/domain/services/conversation_history.dart';
import 'package:sanctum/src/domain/services/message_redaction.dart';

part 'advisor_view_model.g.dart';

/// Where the advisor proxy lives.
///
/// Empty by default, and that is what ships today: with no URL there is
/// no proxy, [chatTransport] hands back the scripted one, and the app
/// makes no network call at all.
///
/// **Do not compile a URL into a release build until the consent screen
/// exists** — `advisor.md` §8 step 5. This provider is the switch that
/// turns a local feature into one that sends a chart to a third party,
/// and the screen that tells the user so has not been built yet.
const advisorProxyUrl = String.fromEnvironment('ADVISOR_PROXY_URL');

/// Supabase's anon key for the function, when it is deployed behind one.
///
/// Not a secret in any meaningful sense — it is extractable from any
/// shipped binary, and the same reasoning `PostHogAnalyticsService`
/// already records applies. What protects the endpoint is the rate
/// limiter and, from step 6, an entitlement.
const advisorProxyKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// One HTTP client for the app, closed when the app is.
@Riverpod(keepAlive: true)
http.Client httpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

/// Whatever is answering questions right now.
///
/// Overriding this one provider is the whole swap — no widget, view
/// model or test below it knows which implementation it is talking to,
/// which is what the [ChatTransport] interface was for.
///
/// The scripted transport is not scaffolding to be deleted once the
/// proxy works: it is what keeps widget tests fast, deterministic and
/// free, and it is how this screen stays developable on a plane.
@riverpod
Future<ChatTransport> chatTransport(Ref ref) async {
  if (advisorProxyUrl.isEmpty) return const ScriptedChatTransport();

  final id = await ref.watch(advisorInstallIdProvider.future);
  return ProxyChatTransport(
    endpoint: Uri.parse(advisorProxyUrl),
    installId: id,
    anonKey: advisorProxyKey,
    client: ref.watch(httpClientProvider),
  );
}

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
/// In Drift, from the moment a first question is asked. The conversation
/// row is written lazily rather than on open, so a screen somebody
/// looked at and left does not become an empty entry in the Ask tab.
///
/// A question is stored when it is sent and an answer when it has
/// finished arriving — never per chunk. A write per token would cost a
/// transaction each, and a process that died mid-answer would leave a
/// half-sentence in the transcript, which is a worse artefact than the
/// missing answer it replaces.
@riverpod
class AdvisorController extends _$AdvisorController {
  ConversationRepository get _store => ref.read(conversationRepositoryProvider);

  @override
  Future<AdvisorUiState> build(CompatibilityMatch match) async {
    final subject = MatchSubject(match.id);
    final stored = (await _store.find(subject)).getOrElse(null);

    // A conversation nobody has asked anything in is not written yet —
    // see [_ensureOpen]. So "not found" is the ordinary first visit,
    // and the state starts from an unsaved conversation rather than an
    // error.
    final conversation =
        stored ??
        Conversation(
          id: 'advisor:${match.id}',
          kind: ConversationKind.advisor,
          subject: subject,
          startedAt: DateTime.now(),
        );

    final messages = stored == null
        ? const <ChatMessage>[]
        : (await _store.messages(conversation.id)).getOrElse(
            const <ChatMessage>[],
          );

    return AdvisorUiState(conversation: conversation, messages: messages);
  }

  /// Writes the conversation row the first time it is needed.
  ///
  /// Lazily, so opening the screen and leaving without asking anything
  /// does not litter the Ask tab with empty conversations.
  Future<void> _ensureOpen(Conversation conversation) =>
      _store.open(conversation);

  /// Asks [question], which is what the user typed or tapped.
  ///
  /// [question] is the *display* form and may contain names. What
  /// reaches the transport does not — see [_outbound].
  Future<void> ask(String question, {required String languageCode}) async {
    final current = state.value;
    if (current == null) return;

    final trimmed = question.trim();
    if (trimmed.isEmpty || !current.canAsk) return;

    await _ensureOpen(current.conversation);

    final now = DateTime.now();
    final asked = ChatMessage(
      id: 'q${now.microsecondsSinceEpoch}',
      conversationId: current.conversation.id,
      author: MessageAuthor.you,
      body: trimmed,
      at: now,
    );
    final answerId = 'a${now.microsecondsSinceEpoch}';
    final answer = ChatMessage(
      id: answerId,
      conversationId: current.conversation.id,
      author: MessageAuthor.counterpart,
      body: '',
      at: now,
      status: MessageStatus.sending,
    );

    // The question is stored as soon as it is asked; the answer only
    // once it is finished. Nothing is written per chunk.
    await _store.save(asked);

    state = AsyncData(
      current.copyWith(
        messages: [...current.messages, asked, answer],
        streamingId: answerId,
        lastQuestion: trimmed,
      ),
    );

    // The history handed over is the redacted one, all the way back:
    // scrubbing only the newest message would send every earlier name
    // again on the next turn.
    final history = [
      for (final message in ConversationHistory.forSend(_messages))
        if (message.id != answerId)
          message.copyWith(body: _outbound(message.body)),
    ];

    final transport = await ref.read(chatTransportProvider.future);
    final stream = transport.send(
      conversation: _conversation,
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
          final spent = ConversationBudget.spendTurn(_conversation);
          state = AsyncData(
            _value.copyWith(conversation: spent, messages: _messages),
          );
          final answered = _messages.firstWhere((m) => m.id == answerId);
          await _store.save(answered);
          await _store.setTurnsUsed(spent.id, spent.turnsUsed);
        case ChatFailed(:final failure):
          // The half-written answer is dropped rather than stored. A
          // fragment in the transcript is a worse artefact than the
          // missing answer it replaces, and the question is kept so a
          // retry needs no retyping.
          state = AsyncData(
            _value.copyWith(
              messages: [
                for (final message in _messages)
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
            ),
          );
          return;
      }
    }
  }

  /// Deletes this conversation and everything in it.
  ///
  /// A first-class action, not a settings afterthought. The journal
  /// already learned that a record you cannot delete from is a worse
  /// product than one that never offered it, and a chat about a named
  /// person is more sensitive than a journal entry, not less.
  Future<void> deleteConversation() async {
    await _store.delete(_conversation.id);
    ref.invalidateSelf();
  }

  AdvisorUiState get _value => state.requireValue;
  Conversation get _conversation => _value.conversation;
  List<ChatMessage> get _messages => _value.messages;

  /// Re-sends the question that failed.
  Future<void> retry({required String languageCode}) async {
    final question = state.value?.lastQuestion;
    if (question == null) return;

    // Drop the failed exchange first, so a retry does not stack a second
    // copy of the question under the first. The stored question goes
    // with it — `ask` writes a fresh one.
    final failedIndex = _messages.lastIndexWhere(
      (m) => m.status == MessageStatus.failed,
    );
    if (failedIndex > 0) {
      final dropped = _messages.sublist(failedIndex - 1);
      state = AsyncData(
        _value.copyWith(messages: _messages.sublist(0, failedIndex - 1)),
      );
      for (final message in dropped) {
        await _store.save(
          message.copyWith(status: MessageStatus.failed),
        );
      }
    }
    await ask(question, languageCode: languageCode);
  }

  /// Clears the error without retrying.
  void dismissFailure() =>
      state = AsyncData(_value.copyWith(messages: _messages));

  void _replace(String id, ChatMessage Function(ChatMessage) update) {
    state = AsyncData(
      _value.copyWith(
        messages: [
          for (final message in _messages)
            if (message.id == id) update(message) else message,
        ],
        streamingId: _value.streamingId,
        failure: _value.failure,
        lastQuestion: _value.lastQuestion,
      ),
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
