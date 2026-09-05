import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/data/repositories/conversation_repository.dart';
import 'package:sanctum/src/domain/models/conversation.dart';

Conversation _conversation({
  String id = 'advisor:pair-1',
  ConversationSubject subject = const MatchSubject('pair-1'),
  int turnsUsed = 0,
}) => Conversation(
  id: id,
  kind: ConversationKind.advisor,
  subject: subject,
  startedAt: DateTime(2026, 9, 5, 12),
  turnsUsed: turnsUsed,
);

ChatMessage _message(
  String id, {
  String conversationId = 'advisor:pair-1',
  MessageAuthor author = MessageAuthor.you,
  String body = 'Why?',
  int minute = 0,
  MessageStatus status = MessageStatus.sent,
}) => ChatMessage(
  id: id,
  conversationId: conversationId,
  author: author,
  body: body,
  at: DateTime(2026, 9, 5, 12, minute),
  status: status,
);

void main() {
  late SanctumDatabase db;
  late DriftConversationRepository repository;

  setUp(() {
    db = SanctumDatabase.memory();
    repository = DriftConversationRepository(db);
  });
  tearDown(() => db.close());

  group('opening', () {
    test('a conversation that has never been opened is absent', () async {
      final found = await repository.find(const MatchSubject('pair-1'));
      expect(found.valueOrNull, isNull);
    });

    test('is found again by its subject', () async {
      await repository.open(_conversation());
      final found = await repository.find(const MatchSubject('pair-1'));
      expect(found.valueOrNull?.id, 'advisor:pair-1');
    });

    test('does not reset the turns already spent', () async {
      // Re-opening happens on every visit to the screen. If that wrote
      // over the row, a conversation would silently refill itself and
      // the cap would mean nothing.
      await repository.open(_conversation());
      await repository.setTurnsUsed('advisor:pair-1', 4);
      await repository.open(_conversation());

      final found = await repository.find(const MatchSubject('pair-1'));
      expect(found.valueOrNull?.turnsUsed, 4);
    });

    test('a match and its report are different conversations', () async {
      // Two products about the same pairing. Owning questions about one
      // must not open the other.
      await repository.open(_conversation());
      final report = await repository.find(const ReportSubject('pair-1'));
      expect(report.valueOrNull, isNull);
    });
  });

  group('the transcript', () {
    setUp(() => repository.open(_conversation()));

    test('comes back oldest first', () async {
      await repository.save(_message('b', minute: 2, body: 'second'));
      await repository.save(_message('a', minute: 1, body: 'first'));

      final messages = await repository.messages('advisor:pair-1');
      expect(
        messages.valueOrNull?.map((m) => m.body),
        ['first', 'second'],
      );
    });

    test('survives a reopen', () async {
      await repository.save(_message('a', body: 'kept'));
      final reopened = DriftConversationRepository(db);
      final messages = await reopened.messages('advisor:pair-1');
      expect(messages.valueOrNull?.single.body, 'kept');
    });

    test('keeps the names the user typed', () async {
      // Redaction happens on the way *out* to a transport, not on the
      // way into storage: this is the local transcript and it must read
      // back the way it was written.
      await repository.save(_message('a', body: 'Why does Alex do that?'));
      final messages = await repository.messages('advisor:pair-1');
      expect(messages.valueOrNull?.single.body, contains('Alex'));
    });

    test('saving the same id twice updates rather than duplicates', () async {
      // How a streamed answer lands: written once when it completes,
      // and rewritten if it is ever revised.
      await repository.save(_message('a', body: 'partial'));
      await repository.save(_message('a', body: 'complete'));

      final messages = await repository.messages('advisor:pair-1');
      expect(messages.valueOrNull, hasLength(1));
      expect(messages.valueOrNull?.single.body, 'complete');
    });

    test('does not leak between conversations', () async {
      await repository.open(
        _conversation(id: 'advisor:pair-2', subject: const MatchSubject('p2')),
      );
      await repository.save(_message('a', body: 'one'));
      await repository.save(
        _message('b', conversationId: 'advisor:pair-2', body: 'two'),
      );

      final first = await repository.messages('advisor:pair-1');
      expect(first.valueOrNull?.single.body, 'one');
    });
  });

  group('deleting', () {
    test('takes the messages with it', () async {
      // By foreign key, not by a second statement somebody has to
      // remember — which only works because `beforeOpen` turns foreign
      // keys on.
      await repository.open(_conversation());
      await repository.save(_message('a'));
      await repository.save(_message('b', minute: 1));

      await repository.delete('advisor:pair-1');

      final rows = await db.select(db.chatMessages).get();
      expect(rows, isEmpty);
    });

    test('leaves other conversations alone', () async {
      await repository.open(_conversation());
      await repository.open(
        _conversation(id: 'advisor:pair-2', subject: const MatchSubject('p2')),
      );
      await repository.save(_message('a', conversationId: 'advisor:pair-2'));

      await repository.delete('advisor:pair-1');

      final survivors = await repository.messages('advisor:pair-2');
      expect(survivors.valueOrNull, hasLength(1));
      expect((await repository.all()).valueOrNull, hasLength(1));
    });
  });

  group('subjects', () {
    test('round-trip through storage', () async {
      // The row stores a kind and a reference rather than one opaque
      // key, and every kind has to come back as the type it went in as.
      final subjects = <ConversationSubject>[
        const MatchSubject('pair-1'),
        const ReportSubject('pair-1'),
        DaySubject(DateTime(2026, 9, 5)),
        const OpenSubject(),
      ];

      for (var i = 0; i < subjects.length; i++) {
        await repository.open(
          _conversation(id: 'c$i', subject: subjects[i]),
        );
      }
      for (final subject in subjects) {
        final found = await repository.find(subject);
        expect(
          found.valueOrNull?.subject.key,
          subject.key,
          reason: subject.key,
        );
      }
    });
  });

  group('listing', () {
    test('is newest first', () async {
      await repository.open(_conversation(id: 'old'));
      await repository.open(
        Conversation(
          id: 'new',
          kind: ConversationKind.advisor,
          subject: const MatchSubject('pair-2'),
          startedAt: DateTime(2026, 9, 6),
        ),
      );
      final all = await repository.all();
      expect(all.valueOrNull?.map((c) => c.id), ['new', 'old']);
    });
  });
}
