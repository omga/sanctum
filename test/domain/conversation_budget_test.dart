import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/services/conversation_budget.dart';

Conversation _conversation({int turnsUsed = 0}) => Conversation(
  id: 'c1',
  kind: ConversationKind.advisor,
  subject: const MatchSubject('person:alex|celeb:taylor-swift'),
  startedAt: DateTime(2026, 9, 5),
  turnsUsed: turnsUsed,
);

void main() {
  group('a fresh conversation', () {
    test('has every question available', () {
      expect(
        ConversationBudget.turnsRemaining(_conversation()),
        ConversationBudget.turnsPerConversation,
      );
      expect(ConversationBudget.canAsk(_conversation()), isTrue);
      expect(ConversationBudget.isSpent(_conversation()), isFalse);
    });
  });

  group('spending', () {
    test('one exchange costs one turn', () {
      // A turn is a question and its answer. Counting messages would
      // charge twice for an answer that arrives in two parts.
      final after = ConversationBudget.spendTurn(_conversation());
      expect(after.turnsUsed, 1);
      expect(
        ConversationBudget.turnsRemaining(after),
        ConversationBudget.turnsPerConversation - 1,
      );
    });

    test('leaves everything else about the conversation alone', () {
      final before = _conversation();
      final after = ConversationBudget.spendTurn(before);
      expect(after.id, before.id);
      expect(after.subject.key, before.subject.key);
      expect(after.startedAt, before.startedAt);
    });

    test('the last turn is askable', () {
      final last = _conversation(
        turnsUsed: ConversationBudget.turnsPerConversation - 1,
      );
      expect(ConversationBudget.canAsk(last), isTrue);
      expect(ConversationBudget.turnsRemaining(last), 1);
    });

    test('the one after it is not', () {
      final spent = _conversation(
        turnsUsed: ConversationBudget.turnsPerConversation,
      );
      expect(ConversationBudget.canAsk(spent), isFalse);
      expect(ConversationBudget.isSpent(spent), isTrue);
    });
  });

  group('a cap lowered underneath a conversation', () {
    test('never reports negative questions', () {
      // What tuning turnsPerConversation downward does to everybody
      // mid-conversation. It must read as spent, not as owing.
      final over = _conversation(
        turnsUsed: ConversationBudget.turnsPerConversation + 3,
      );
      expect(ConversationBudget.turnsRemaining(over), 0);
      expect(ConversationBudget.isSpent(over), isTrue);
      expect(ConversationBudget.canAsk(over), isFalse);
    });
  });

  group('the nearly-spent warning', () {
    test('fires before the last questions, not on them', () {
      final warn = _conversation(
        turnsUsed:
            ConversationBudget.turnsPerConversation -
            ConversationBudget.warnAtRemaining,
      );
      expect(ConversationBudget.isNearlySpent(warn), isTrue);
    });

    test('does not fire on a fresh conversation', () {
      expect(ConversationBudget.isNearlySpent(_conversation()), isFalse);
    });

    test('does not fire once there is nothing left to warn about', () {
      // Warning somebody they are nearly out when they are entirely out
      // is a second, worse way to tell them the same thing.
      final spent = _conversation(
        turnsUsed: ConversationBudget.turnsPerConversation,
      );
      expect(ConversationBudget.isNearlySpent(spent), isFalse);
    });
  });

  group('subject identity', () {
    test('is deterministic and namespaced by kind', () {
      // A match and its report are two products about the same pairing;
      // owning one must not silently open the other.
      const match = MatchSubject('person:alex|celeb:taylor-swift');
      const report = ReportSubject('person:alex|celeb:taylor-swift');
      expect(match.key, isNot(report.key));
      expect(
        match.key,
        const MatchSubject('person:alex|celeb:taylor-swift').key,
      );
    });

    test('a day is keyed by the calendar day, not the instant', () {
      expect(
        DaySubject(DateTime(2026, 9, 5, 8)).key,
        DaySubject(DateTime(2026, 9, 5, 23)).key,
      );
    });
  });
}
