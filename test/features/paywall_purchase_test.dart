import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/analytics/analytics_service.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/settings_repository.dart';
import 'package:sanctum/src/data/repositories/subscription_repository.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/domain/models/report_product.dart';
import 'package:sanctum/src/domain/models/subscription_plan.dart';
import 'package:sanctum/src/features/paywall/view/paywall_screen.dart';

import '../support/harness.dart';

/// A store whose sheet ends however the test says.
class _Store implements SubscriptionRepository {
  _Store(this.outcome);

  /// `ok(true)` bought, `ok(false)` cancelled, `err` failed.
  final Result<bool> outcome;
  int attempts = 0;

  @override
  Future<Result<List<SubscriptionPlan>>> plans() async => const Result.ok([
    SubscriptionPlan(
      id: 'sanctum.premium.monthly',
      period: BillingPeriod.monthly,
      displayPrice: r'$9.99',
      displayPricePerMonth: r'$9.99',
    ),
    SubscriptionPlan(
      id: 'sanctum.premium.yearly',
      period: BillingPeriod.yearly,
      displayPrice: r'$79.99',
      displayPricePerMonth: r'$6.66',
      savingsPercent: 33,
    ),
  ]);

  @override
  Future<Result<bool>> purchase(String planId) async {
    attempts++;
    return outcome;
  }

  @override
  Future<Result<ReportProduct?>> reportProduct() async =>
      const Result.ok(null);

  @override
  Future<Result<bool>> purchaseReport() async => const Result.ok(true);

  @override
  Future<Result<bool>> restore() async => const Result.ok(false);
}

/// Counts the dismissals the trigger's backoff depends on.
class _Settings implements SettingsRepository {
  int dismissals = 0;
  int impressions = 0;

  @override
  Future<Result<void>> recordPaywallDismissed() async {
    dismissals++;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> recordPaywallShown(DateTime at) async {
    impressions++;
    return const Result.ok(null);
  }

  @override
  Future<Result<String>> installSalt() async => const Result.ok('salt');

  @override
  Future<Result<bool>> hasOnboarded() async => const Result.ok(true);

  @override
  Future<Result<void>> setOnboarded() async => const Result.ok(null);

  @override
  Future<Result<DateTime>> installDate() async =>
      Result.ok(DateTime(2026));

  @override
  Future<Result<({int dismissed, DateTime? lastShown, int shown})>>
  paywallState() async =>
      const Result.ok((shown: 0, dismissed: 0, lastShown: null));
}

({RecordingAnalyticsService analytics, _Settings settings, _Store store})
_deps(Result<bool> outcome) =>
    (
      analytics: RecordingAnalyticsService(),
      settings: _Settings(),
      store: _Store(outcome),
    );

Future<void> _pump(
  WidgetTester tester,
  ({RecordingAnalyticsService analytics, _Settings settings, _Store store})
  deps,
) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(deps.store),
        settingsRepositoryProvider.overrideWithValue(deps.settings),
        analyticsProvider.overrideWithValue(deps.analytics),
      ],
      child: testApp(
        const PaywallScreen(moment: PaywallMoment.lockedContent),
      ),
    ),
  );
  // Not `pumpAndSettle`: the subscribe button's sheen repeats forever.
  await tester.pump();
  await tester.pump();
}

Future<void> _tapSubscribe(WidgetTester tester) async {
  final button = find.textContaining('Subscribe');
  expect(button, findsOneWidget);
  await tester.tap(button);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('a completed purchase is reported and closes the paywall', (
    tester,
  ) async {
    final deps = _deps(const Result.ok(true));
    await _pump(tester, deps);
    await _tapSubscribe(tester);

    expect(deps.store.attempts, 1);
    expect(
      deps.analytics.names,
      containsAllInOrder(['purchase_started', 'purchase_completed']),
    );
  });

  testWidgets('a cancelled purchase reports nothing and stays open', (
    tester,
  ) async {
    // The bug: `purchase` returned `Result<void>`, so "no error" read as
    // success. A cancellation fired `purchase_completed`, flashed the
    // purchased state, and closed the screen on somebody who had just
    // declined.
    final deps = _deps(const Result.ok(false));
    await _pump(tester, deps);
    await _tapSubscribe(tester);

    expect(deps.store.attempts, 1);
    expect(deps.analytics.names, contains('purchase_started'));
    expect(deps.analytics.names, isNot(contains('purchase_completed')));
    // Still on the paywall, plan still selectable.
    expect(find.textContaining('Subscribe'), findsOneWidget);
  });

  testWidgets('cancelling then closing still records the dismissal', (
    tester,
  ) async {
    // `_purchased` suppresses the dismissal, and a cancellation used to
    // set it — so `PaywallTrigger`'s 3 → 7 → 14 → 30 day backoff never
    // advanced and the same user was prompted again on the shortest
    // cooldown.
    final deps = _deps(const Result.ok(false));
    await _pump(tester, deps);
    await _tapSubscribe(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();

    expect(deps.settings.dismissals, 1);
    expect(
      deps.analytics.names,
      contains('paywall_dismissed'),
    );
  });

  testWidgets('a completed purchase records no dismissal', (tester) async {
    final deps = _deps(const Result.ok(true));
    await _pump(tester, deps);
    await _tapSubscribe(tester);

    expect(deps.settings.dismissals, 0);
    expect(
      deps.analytics.names,
      isNot(contains('paywall_dismissed')),
    );
  });

  testWidgets('a failed purchase reports no sale', (tester) async {
    final deps = _deps(const Result.err(UnexpectedFailure('boom')));
    await _pump(tester, deps);
    await _tapSubscribe(tester);

    expect(deps.analytics.names, isNot(contains('purchase_completed')));
  });
}
