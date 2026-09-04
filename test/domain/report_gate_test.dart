import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/report_gate.dart';

const _match = 'person:alex:1996-6-15|celeb:taylor-swift';
const _other = 'person:sam:1990-1-2|celeb:taylor-swift';

ReportAccess _decide({
  Set<String> purchased = const {},
  String? included,
  bool isPremium = false,
}) => ReportGate.decide(
  matchId: _match,
  purchasedIds: purchased,
  includedReportId: included,
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

    test('is for sale to a free user', () {
      expect(_decide(), ReportAccess.forSale);
    });
  });

  group("a subscriber's included report", () {
    test('is offered while it is unspent', () {
      expect(_decide(isPremium: true), ReportAccess.includedWithPremium);
    });

    test('is not offered twice', () {
      // The point of including one rather than all of them: the second
      // report a subscriber wants is still sold.
      expect(_decide(isPremium: true, included: _other), ReportAccess.forSale);
    });

    test('opens the pairing it was spent on, forever', () {
      expect(_decide(isPremium: true, included: _match), ReportAccess.owned);
    });

    test('survives the subscription lapsing', () {
      // Rule one is that owned stays owned. Clawing back a document
      // somebody has read is what produces refunds and one-star reviews.
      expect(_decide(included: _match), ReportAccess.owned);
    });

    test('is not offered to a free user', () {
      expect(_decide(), ReportAccess.forSale);
      expect(
        ReportGate.hasIncludedReport(isPremium: false, includedReportId: null),
        isFalse,
      );
    });

    test('is spent exactly once, tracked by which pairing took it', () {
      expect(
        ReportGate.hasIncludedReport(isPremium: true, includedReportId: null),
        isTrue,
      );
      expect(
        ReportGate.hasIncludedReport(
          isPremium: true,
          includedReportId: _match,
        ),
        isFalse,
      );
    });
  });

  group('purchase history is separate from ownership', () {
    test('a claimed report is owned but was never bought', () {
      // The two must not be conflated, or the receipt history starts
      // claiming purchases that never happened — and `purchase_completed`
      // starts counting sales nobody paid for.
      expect(
        ReportGate.isOwned(
          matchId: _match,
          purchasedIds: const {},
          includedReportId: _match,
        ),
        isTrue,
      );
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
