import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/report_gate.dart';

const _match = 'person:alex:1996-6-15|celeb:taylor-swift';
const _other = 'person:sam:1990-1-2|celeb:taylor-swift';

ReportAccess _decide({
  Set<String> purchased = const {},
  bool isPremium = false,
}) => ReportGate.decide(
  matchId: _match,
  purchasedIds: purchased,
  isPremium: isPremium,
);

void main() {
  group('a report that has been bought', () {
    test('is owned', () {
      expect(_decide(purchased: {_match}), ReportAccess.owned);
    });

    test('stays owned regardless of subscription state', () {
      // The document was paid for once. Letting a lapsed subscription
      // close it would be taking back a thing somebody bought.
      expect(
        _decide(purchased: {_match}, isPremium: true),
        ReportAccess.owned,
      );
      expect(
        _decide(purchased: {_match}),
        ReportAccess.owned,
      );
    });

    test('does not unlock a different pairing', () {
      // The unit sold is "You & X". Buying one report must not open the
      // report about somebody else.
      expect(_decide(purchased: {_other}), ReportAccess.forSale);
    });
  });

  group('a report that has not been bought', () {
    test('is for sale', () {
      expect(_decide(), ReportAccess.forSale);
    });

    test('is for sale to a subscriber, under the current policy', () {
      // roadmap.md §1: the one-off exists to answer whether relationship
      // intent monetises *beyond* the subscription. Bundling it into
      // Premium means no subscriber ever buys one, and the experiment
      // can only ever measure non-subscribers.
      expect(ReportGate.premiumIncludesReports, isFalse);
      expect(_decide(isPremium: true), ReportAccess.forSale);
    });
  });

  group('purchase history is separate from access', () {
    test('a subscriber who has not bought it has not bought it', () {
      // The two must not be conflated: the day the bundling policy
      // flips, receipts must not start claiming purchases that never
      // happened.
      expect(
        ReportGate.isPurchased(matchId: _match, purchasedIds: const {}),
        isFalse,
      );
      expect(
        ReportGate.isPurchased(matchId: _match, purchasedIds: {_match}),
        isTrue,
      );
    });
  });
}
