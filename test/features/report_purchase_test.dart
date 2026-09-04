import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/analytics/analytics_service.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/report_repository.dart';
import 'package:sanctum/src/data/repositories/subscription_repository.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/report_product.dart';
import 'package:sanctum/src/domain/models/subscription_plan.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
import 'package:sanctum/src/domain/services/report_gate.dart';
import 'package:sanctum/src/features/compatibility/view_model/report_view_model.dart';

import '../support/copy.dart';

final CopyBook _copy = loadEnglishCopy();

final CompatibilityMatch _match = CompatibilityComposer.compose(
  you: MatchPerson(name: 'Andrew', birthDate: DateTime(1996, 6, 15)),
  them: MatchPerson(name: 'Alex', birthDate: DateTime(1994, 12, 2)),
  now: DateTime(2026, 9, 4),
  copy: _copy,
);

/// An in-memory receipt store.
class _Reports implements ReportRepository {
  _Reports({this.owned = const {}, this.failsToRead = false,
      this.failsToWrite = false});

  Set<String> owned;
  bool failsToRead;
  bool failsToWrite;
  int writes = 0;

  @override
  Future<Result<Set<String>>> purchased() async => failsToRead
      ? const Result.err(StorageFailure('nope'))
      : Result.ok(owned);

  @override
  Future<Result<void>> recordPurchase(String matchId) async {
    if (failsToWrite) return const Result.err(StorageFailure('nope'));
    writes++;
    owned = {...owned, matchId};
    return const Result.ok(null);
  }
}

/// A store that can be told exactly how the sheet ends.
class _Store implements SubscriptionRepository {
  _Store({this.outcome = const Result.ok(true)});

  Result<bool> outcome;
  ReportProduct? product = const ReportProduct(
    id: 'sanctum.report.relationship',
    displayPrice: '£4.99',
  );
  int attempts = 0;

  @override
  Future<Result<List<SubscriptionPlan>>> plans() async =>
      const Result.ok([]);

  @override
  Future<Result<bool>> purchase(String planId) async => const Result.ok(true);

  @override
  Future<Result<ReportProduct?>> reportProduct() async => Result.ok(product);

  @override
  Future<Result<bool>> purchaseReport() async {
    attempts++;
    return outcome;
  }

  @override
  Future<Result<bool>> restore() async => const Result.ok(false);
}

({ProviderContainer container, RecordingAnalyticsService analytics})
_harness({
  required _Reports reports,
  required _Store store,
  bool isPremium = false,
}) {
  final analytics = RecordingAnalyticsService();
  final container = ProviderContainer(
    overrides: [
      reportRepositoryProvider.overrideWithValue(reports),
      subscriptionRepositoryProvider.overrideWithValue(store),
      isPremiumProvider.overrideWithValue(isPremium),
      analyticsProvider.overrideWithValue(analytics),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, analytics: analytics);
}

void main() {
  test('an unbought report is for sale, with a price', () async {
    final h = _harness(reports: _Reports(), store: _Store());
    final state = await h.container.read(
      reportControllerProvider(_match).future,
    );

    expect(state.access, ReportAccess.forSale);
    expect(state.canBuy, isTrue);
    expect(state.product!.displayPrice, '£4.99');
  });

  test('a bought report is owned', () async {
    final h = _harness(
      reports: _Reports(owned: {_match.id}),
      store: _Store(),
    );
    final state = await h.container.read(
      reportControllerProvider(_match).future,
    );

    expect(state.isOwned, isTrue);
  });

  test('buying grants it and reports the purchase once', () async {
    final reports = _Reports();
    final store = _Store();
    final h = _harness(reports: reports, store: store);
    await h.container.read(reportControllerProvider(_match).future);

    final bought = await h.container
        .read(reportControllerProvider(_match).notifier)
        .buy();

    expect(bought, isTrue);
    expect(reports.owned, contains(_match.id));
    expect(h.analytics.names, ['purchase_started', 'purchase_completed']);

    final state = await h.container.read(
      reportControllerProvider(_match).future,
    );
    expect(state.isOwned, isTrue);
  });

  test('backing out of the sheet grants nothing and reports nothing', () async {
    // The bug this exists to prevent: `SubscriptionRepository.purchase`
    // maps a cancellation to `Result.ok`, and the subscription paywall
    // consequently counts it as a completed purchase. Doing that here
    // would hand out a paid document to somebody who declined to buy it.
    final reports = _Reports();
    final store = _Store(outcome: const Result.ok(false));
    final h = _harness(reports: reports, store: store);
    await h.container.read(reportControllerProvider(_match).future);

    final bought = await h.container
        .read(reportControllerProvider(_match).notifier)
        .buy();

    expect(bought, isFalse);
    expect(reports.owned, isEmpty);
    expect(reports.writes, 0);
    expect(h.analytics.names, ['purchase_started']);

    final state = await h.container.read(
      reportControllerProvider(_match).future,
    );
    expect(state.isOwned, isFalse);
  });

  test('a failed purchase grants nothing', () async {
    final reports = _Reports();
    final h = _harness(
      reports: reports,
      store: _Store(outcome: const Result.err(UnexpectedFailure('boom'))),
    );
    await h.container.read(reportControllerProvider(_match).future);

    final bought = await h.container
        .read(reportControllerProvider(_match).notifier)
        .buy();

    expect(bought, isFalse);
    expect(reports.owned, isEmpty);
    expect(h.analytics.names, ['purchase_started']);
  });

  test('a receipt that cannot be written is not reported as a sale', () async {
    // Better to fail visibly than to show the document once and forget
    // it was ever bought.
    final reports = _Reports(failsToWrite: true);
    final h = _harness(reports: reports, store: _Store());
    await h.container.read(reportControllerProvider(_match).future);

    final bought = await h.container
        .read(reportControllerProvider(_match).notifier)
        .buy();

    expect(bought, isFalse);
    expect(h.analytics.names, ['purchase_started']);
    expect(
      h.container.read(reportControllerProvider(_match)).hasError,
      isTrue,
    );
  });

  test('a receipt store that cannot be read is an error, not "owns nothing"',
      () async {
    // Treating a read failure as an empty set would offer to re-sell a
    // document the user has already paid for.
    final h = _harness(reports: _Reports(failsToRead: true), store: _Store());

    await expectLater(
      h.container.read(reportControllerProvider(_match).future),
      throwsA(isA<StateError>()),
    );
  });

  test('no price means nothing to sell', () async {
    final h = _harness(
      reports: _Reports(),
      store: _Store()..product = null,
    );
    final state = await h.container.read(
      reportControllerProvider(_match).future,
    );

    expect(state.canBuy, isFalse);

    final bought = await h.container
        .read(reportControllerProvider(_match).notifier)
        .buy();
    expect(bought, isFalse);
  });

  test('a subscriber is still offered the report', () async {
    final h = _harness(
      reports: _Reports(),
      store: _Store(),
      isPremium: true,
    );
    final state = await h.container.read(
      reportControllerProvider(_match).future,
    );

    expect(state.isOwned, isFalse);
    expect(state.canBuy, isTrue);
  });
}
