import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/data/services/advisor/scripted_chat_transport.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/services/chat_transport.dart';

final _conversation = Conversation(
  id: 'c1',
  kind: ConversationKind.advisor,
  subject: const MatchSubject('person:alex|celeb:taylor-swift'),
  startedAt: DateTime(2026, 9, 5),
);

ChatMessage _asked(String body, {int index = 0}) => ChatMessage(
  id: 'm$index',
  conversationId: 'c1',
  author: MessageAuthor.you,
  body: body,
  at: DateTime(2026, 9, 5),
);

/// A transcript of [turns] questions, each already answered.
List<ChatMessage> _history(int turns) => [
  for (var i = 0; i < turns; i++) ...[
    _asked('question $i', index: i),
    ChatMessage(
      id: 'a$i',
      conversationId: 'c1',
      author: MessageAuthor.counterpart,
      body: 'answer $i',
      at: DateTime(2026, 9, 5),
    ),
  ],
];

Future<List<ChatChunk>> _collect(Stream<ChatChunk> stream) => stream.toList();

void main() {
  const transport = ScriptedChatTransport(delayPerChunk: Duration.zero);

  group('answering', () {
    test('streams the answer in pieces and then completes', () {
      // The shape the UI is built against, long before a proxy exists.
      // A transport that returned one lump would let the view model be
      // written in a way the real one cannot satisfy.
      return _collect(
        transport.send(
          conversation: _conversation,
          history: [_asked('why?')],
          context: null,
        ),
      ).then((chunks) {
        expect(chunks.whereType<ChatDelta>().length, greaterThan(1));
        expect(chunks.last, isA<ChatCompleted>());
      });
    });

    test('every delta is new text, never the answer so far', () {
      // The contract in ChatChunk. A transport that re-sent the whole
      // string each time would make the UI look right and the token
      // accounting wrong.
      return _collect(
        transport.send(
          conversation: _conversation,
          history: [_asked('why?')],
          context: null,
        ),
      ).then((chunks) {
        final deltas =
            chunks.whereType<ChatDelta>().map((d) => d.text).toList();
        expect(deltas.first, isNot(contains(deltas.last.trim())));
      });
    });

    test('is deterministic for the same turn', () async {
      // Why this transport exists: a widget test needs the same answer
      // on every run, and prose from a real model is not that.
      Future<String> answer() async {
        final chunks = await _collect(
          transport.send(
            conversation: _conversation,
            history: [_asked('why?')],
            context: null,
          ),
        );
        return chunks.whereType<ChatDelta>().map((d) => d.text).join();
      }

      expect(await answer(), await answer());
    });

    test('says something different on the second question', () async {
      final first = await _collect(
        transport.send(
          conversation: _conversation,
          history: _history(0)..add(_asked('one')),
          context: null,
        ),
      );
      final second = await _collect(
        transport.send(
          conversation: _conversation,
          history: _history(1)..add(_asked('two')),
          context: null,
        ),
      );
      String text(List<ChatChunk> chunks) =>
          chunks.whereType<ChatDelta>().map((d) => d.text).join();
      expect(text(first), isNot(text(second)));
    });

    test('keeps answering past the end of the script', () async {
      // The rotation clamps rather than crashing. A cap on questions is
      // the gate's job, not the transport's.
      final chunks = await _collect(
        transport.send(
          conversation: _conversation,
          history: _history(20)..add(_asked('still here')),
          context: null,
        ),
      );
      expect(chunks.last, isA<ChatCompleted>());
    });
  });

  group('the failure path', () {
    test('can be produced on demand, with no network to unplug', () async {
      const failing = ScriptedChatTransport(
        delayPerChunk: Duration.zero,
        failEveryNthTurn: 1,
      );
      final chunks = await _collect(
        failing.send(
          conversation: _conversation,
          history: [_asked('why?')],
          context: null,
        ),
      );
      expect(chunks.single, isA<ChatFailed>());
    });

    test('carries a failure the screen can tell apart from a real one',
        () async {
      const failing = ScriptedChatTransport(
        delayPerChunk: Duration.zero,
        failEveryNthTurn: 1,
      );
      final chunks = await _collect(
        failing.send(
          conversation: _conversation,
          history: [_asked('why?')],
          context: null,
        ),
      );
      final failure = (chunks.single as ChatFailed).failure;
      expect(failure, isA<AdvisorFailure>());
      expect(
        (failure as AdvisorFailure).kind,
        AdvisorFailureKind.scripted,
      );
    });

    test('does not complete, so no turn is spent', () async {
      // The rule in ChatChunk: a user who paid for ten answers and got
      // nine plus an error has been short-changed by one.
      const failing = ScriptedChatTransport(
        delayPerChunk: Duration.zero,
        failEveryNthTurn: 1,
      );
      final chunks = await _collect(
        failing.send(
          conversation: _conversation,
          history: [_asked('why?')],
          context: null,
        ),
      );
      expect(chunks.whereType<ChatCompleted>(), isEmpty);
    });
  });
}
