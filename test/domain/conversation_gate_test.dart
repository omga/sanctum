import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/conversation_budget.dart';
import 'package:sanctum/src/domain/services/conversation_gate.dart';

const _subject = 'match:person:alex:1996-6-15|celeb:taylor-swift';
const _other = 'match:person:sam:1990-1-2|celeb:taylor-swift';
const _now = '2026-09';

ConversationAccess _decide({
  Set<String> owned = const {},
  String? includedPeriod,
  bool isPremium = false,
  int turnsUsed = 0,
}) => ConversationGate.decide(
  subjectKey: _subject,
  ownedKeys: owned,
  period: _now,
  includedPeriod: includedPeriod,
  isPremium: isPremium,
  turnsUsed: turnsUsed,
);

void main() {
  group('a conversation that has been bought', () {
    test('opens', () {
      expect(_decide(owned: {_subject}), ConversationAccess.open);
    });

    test('stays owned when the subscription lapses', () {
      // Rule one, shared with ReportGate: clawing back something
      // somebody has read is what produces refunds.
      expect(_decide(owned: {_subject}), ConversationAccess.open);
      expect(
        _decide(owned: {_subject}, isPremium: true),
        ConversationAccess.open,
      );
    });

    test('does not open a conversation about somebody else', () {
      // The unit sold is one subject. Buying questions about Alex must
      // not answer questions about Sam.
      expect(_decide(owned: {_other}), ConversationAccess.forSale);
    });
  });

  group('a conversation whose questions are spent', () {
    final spent = _decide(
      owned: {_subject},
      turnsUsed: ConversationBudget.turnsPerConversation,
    );

    test('is spent, not for sale', () {
      // The distinction the whole gate exists for. Somebody who paid for
      // ten answers must not be shown a price where their transcript
      // was.
      expect(spent, ConversationAccess.spent);
      expect(spent, isNot(ConversationAccess.forSale));
    });

    test('is still readable', () {
      expect(
        ConversationGate.canRead(
          subjectKey: _subject,
          ownedKeys: {_subject},
        ),
        isTrue,
      );
    });

    test('reads as spent if the cap is lowered underneath it', () {
      // Tuning turnsPerConversation downward must not put a conversation
      // into a state where it owes questions back.
      expect(
        _decide(
          owned: {_subject},
          turnsUsed: ConversationBudget.turnsPerConversation + 5,
        ),
        ConversationAccess.spent,
      );
    });
  });

  group("a subscriber's included conversation", () {
    test('is offered while this period is unclaimed', () {
      expect(
        _decide(isPremium: true),
        ConversationAccess.includedWithPremium,
      );
    });

    test('is not offered twice in the same period', () {
      expect(
        _decide(isPremium: true, includedPeriod: _now),
        ConversationAccess.forSale,
      );
    });

    test('comes back next period', () {
      // The difference from the report's once-ever allowance, and the
      // mechanic that makes a subscription drive chat sales.
      expect(
        _decide(isPremium: true, includedPeriod: '2026-08'),
        ConversationAccess.includedWithPremium,
      );
    });

    test('is not offered to a free user', () {
      expect(_decide(), ConversationAccess.forSale);
    });

    test('does not override something already owned', () {
      // A subscriber re-opening a conversation they bought must not be
      // charged their monthly allowance for it.
      expect(
        _decide(owned: {_subject}, isPremium: true),
        ConversationAccess.open,
      );
    });
  });

  group('periods', () {
    test('are calendar months, zero-padded so they sort', () {
      expect(ConversationGate.periodFor(DateTime(2026, 9, 5)), '2026-09');
      expect(ConversationGate.periodFor(DateTime(2026, 12, 31)), '2026-12');
    });

    test('change at the month boundary and nowhere else', () {
      final first = ConversationGate.periodFor(DateTime(2026, 9, 1));
      final last = ConversationGate.periodFor(DateTime(2026, 9, 30, 23, 59));
      final next = ConversationGate.periodFor(DateTime(2026, 10, 1));
      expect(first, last);
      expect(next, isNot(first));
    });
  });
}
