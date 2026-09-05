import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/message_balance.dart';
import 'package:sanctum/src/domain/services/message_budget.dart';

const _week = '2026-W37';

int _remaining(MessageBalance balance, {bool isPremium = true}) =>
    MessageBudget.remaining(
      balance: balance,
      week: _week,
      isPremium: isPremium,
    );

MessageBalance _spend(
  MessageBalance balance, {
  bool isPremium = true,
  String week = _week,
  int times = 1,
}) {
  var result = balance;
  for (var i = 0; i < times; i++) {
    result = MessageBudget.spend(
      balance: result,
      week: week,
      isPremium: isPremium,
    );
  }
  return result;
}

void main() {
  group('a subscriber', () {
    test('starts the week with the free allowance', () {
      expect(_remaining(MessageBalance.empty), MessageBudget.weeklyFree);
    });

    test('spends free messages before bought ones', () {
      // The free ones expire on Sunday and the bought ones do not.
      // Spending the wrong one first takes money for nothing.
      final after = _spend(const MessageBalance(purchased: 5));
      expect(after.purchased, 5);
      expect(after.freeUsed, 1);
    });

    test('falls through to bought messages once the free are gone', () {
      final spent = _spend(
        const MessageBalance(purchased: 5),
        times: MessageBudget.weeklyFree,
      );
      expect(_remaining(spent), 5);

      final more = _spend(spent);
      expect(more.purchased, 4);
    });

    test('runs out when both are gone', () {
      final spent = _spend(
        MessageBalance.empty,
        times: MessageBudget.weeklyFree,
      );
      expect(_remaining(spent), 0);
      expect(
        MessageBudget.canAsk(
          balance: spent,
          week: _week,
          isPremium: true,
        ),
        isFalse,
      );
    });

    test('cannot be driven negative by a caller that did not check', () {
      final spent = _spend(
        MessageBalance.empty,
        times: MessageBudget.weeklyFree + 3,
      );
      expect(_remaining(spent), 0);
      expect(spent.freeUsed, MessageBudget.weeklyFree);
    });
  });

  group('the weekly reset', () {
    test('gives the allowance back in a new week', () {
      final spent = _spend(
        MessageBalance.empty,
        times: MessageBudget.weeklyFree,
      );
      expect(
        MessageBudget.remaining(
          balance: spent,
          week: '2026-W38',
          isPremium: true,
        ),
        MessageBudget.weeklyFree,
      );
    });

    test('does not give back bought messages, because they never left', () {
      final spent = _spend(
        const MessageBalance(purchased: 2),
        times: MessageBudget.weeklyFree + 1,
      );
      expect(spent.purchased, 1);
      expect(
        MessageBudget.remaining(
          balance: spent,
          week: '2026-W38',
          isPremium: true,
        ),
        MessageBudget.weeklyFree + 1,
      );
    });

    test('resets the counter as it writes the new week', () {
      final spent = _spend(
        MessageBalance.empty,
        times: MessageBudget.weeklyFree,
      );
      final nextWeek = _spend(spent, week: '2026-W38');
      expect(nextWeek.freeWeek, '2026-W38');
      expect(nextWeek.freeUsed, 1);
    });
  });

  group('a non-subscriber', () {
    test('has no free messages', () {
      expect(_remaining(MessageBalance.empty, isPremium: false), 0);
    });

    test('can still spend what they bought', () {
      const bought = MessageBalance(purchased: 5);
      expect(_remaining(bought, isPremium: false), 5);

      final after = _spend(bought, isPremium: false);
      expect(after.purchased, 4);
      // Not charged against a free allowance they do not have.
      expect(after.freeUsed, 0);
    });

    test('gains the weekly allowance the moment they subscribe', () {
      const bought = MessageBalance(purchased: 2);
      expect(_remaining(bought, isPremium: false), 2);
      expect(_remaining(bought), MessageBudget.weeklyFree + 2);
    });

    test('keeps bought messages if a subscription lapses', () {
      // Owned stays owned, the rule this app applies everywhere else.
      final spent = _spend(const MessageBalance(purchased: 3));
      expect(_remaining(spent, isPremium: false), 3);
    });
  });

  group('buying a pack', () {
    test('adds messages without touching the free count', () {
      final spent = _spend(MessageBalance.empty, times: 2);
      final bought = MessageBudget.grantPack(spent);
      expect(bought.purchased, MessageBudget.messagesPerPack);
      expect(bought.freeUsed, 2);
    });

    test('stacks', () {
      final twice = MessageBudget.grantPack(
        MessageBudget.grantPack(MessageBalance.empty),
      );
      expect(twice.purchased, MessageBudget.messagesPerPack * 2);
    });
  });

  group('ISO weeks', () {
    test('run Monday to Sunday', () {
      // 2026-09-07 is a Monday.
      final monday = MessageBudget.weekFor(DateTime(2026, 9, 7));
      final sunday = MessageBudget.weekFor(DateTime(2026, 9, 13, 23, 59));
      expect(monday, sunday);
      expect(MessageBudget.weekFor(DateTime(2026, 9, 14)), isNot(monday));
    });

    test('put a late-December week in the year that owns its Thursday', () {
      // The bug this exists to prevent: a naive week number hands out a
      // second allowance in the last days of the year, every year.
      // 2026-12-31 is a Thursday, so that week is 2026-W53.
      expect(MessageBudget.weekFor(DateTime(2026, 12, 31)), '2026-W53');
      expect(MessageBudget.weekFor(DateTime(2027, 1, 3)), '2026-W53');
      expect(MessageBudget.weekFor(DateTime(2027, 1, 4)), '2027-W01');
    });

    test('are sortable as strings', () {
      final weeks = [
        MessageBudget.weekFor(DateTime(2026, 1, 5)),
        MessageBudget.weekFor(DateTime(2026, 3, 2)),
        MessageBudget.weekFor(DateTime(2026, 11, 2)),
      ];
      expect(weeks, orderedEquals([...weeks]..sort()));
    });
  });

  group('the warning', () {
    test('fires on the last message and not before', () {
      final one = _spend(
        MessageBalance.empty,
        times: MessageBudget.weeklyFree - 1,
      );
      expect(
        MessageBudget.isNearlySpent(
          balance: one,
          week: _week,
          isPremium: true,
        ),
        isTrue,
      );
      expect(
        MessageBudget.isNearlySpent(
          balance: MessageBalance.empty,
          week: _week,
          isPremium: true,
        ),
        isFalse,
      );
    });

    test('does not fire when there is nothing left to warn about', () {
      final none = _spend(
        MessageBalance.empty,
        times: MessageBudget.weeklyFree,
      );
      expect(
        MessageBudget.isNearlySpent(
          balance: none,
          week: _week,
          isPremium: true,
        ),
        isFalse,
      );
    });
  });
}
