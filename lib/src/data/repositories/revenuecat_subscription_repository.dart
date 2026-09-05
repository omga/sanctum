import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/repositories/entitlement_repository.dart';
import 'package:sanctum/src/data/repositories/subscription_repository.dart';
import 'package:sanctum/src/domain/models/report_product.dart';
import 'package:sanctum/src/domain/models/subscription_plan.dart';

/// Billing, backed by RevenueCat.
///
/// The drop-in replacement for `LocalSubscriptionRepository` that the
/// two interfaces were written for. Nothing above this file knows a
/// payment SDK exists — no feature, no widget, no view model, no test —
/// which is the whole reason the seam was built before the paywall was.
///
/// ## The user is never identified, and that is load-bearing
///
/// [configure] passes **no `appUserID`**, so RevenueCat generates an
/// anonymous one. That is not laziness, it is the reason the app's
/// central privacy claim survives having a payment vendor at all:
///
/// > "No account, ever. Your name, your birth date and your journal stay
/// > on this phone."
///
/// Calling `Purchases.logIn` with an email, a name, or anything derived
/// from the quiz would break that sentence in the onboarding copy, and
/// it is the one claim this product is differentiated on. If a future
/// feature needs cross-device restore, that is a product decision with a
/// consent gate attached — not a one-line SDK change.
///
/// ## Why the app still works on a plane
///
/// The SDK caches `CustomerInfo` on the device, so [watch] keeps
/// reporting premium with no network. That matters more here than in
/// most apps: everything else in Sanctum is computed locally and works
/// offline, and an entitlement that evaporated in aeroplane mode would
/// be the only part of the product that needed a signal.
class RevenueCatSubscriptionRepository implements BillingRepository {
  /// Creates the repository. [configure] must have run first.
  RevenueCatSubscriptionRepository();

  /// The public SDK key.
  ///
  /// Committed, like PostHog's, and for the same reason: RevenueCat's
  /// SDK keys are public by design, are extractable from any shipped
  /// binary, and cannot read or mutate anything on their own. A *secret*
  /// key (`sk_…`) is a different object entirely and must never appear
  /// in this repository.
  ///
  /// The current value is a **Test Store** key. Test Store purchases
  /// behave like real ones — they update `CustomerInfo`, trigger
  /// entitlements and show up on the dashboard — but they transact
  /// against nothing. Shipping needs the per-platform `appl_…` and
  /// `goog_…` keys plus real products in App Store Connect and Play
  /// Console, selected per platform rather than from this one constant.
  static const String apiKey = String.fromEnvironment(
    'REVENUECAT_KEY',
    defaultValue: 'test_YcEwnJYyIpVxXwSrTJQIxOSdCDg',
  );

  /// The entitlement identifier configured in the RevenueCat dashboard.
  ///
  /// The *identifier*, not the display name. "Sanctum Pro" is what the
  /// dashboard shows a human; the SDK matches on the id, and a mismatch
  /// fails silently — `entitlements.active` is simply always empty, the
  /// paywall never unlocks, and nothing anywhere throws.
  static const String entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT',
    defaultValue: 'Sanctum Pro',
  );

  /// Whether [apiKey] is a RevenueCat Test Store key.
  static bool get usingTestStore => apiKey.startsWith('test_');

  /// Whether [configure] actually started the SDK.
  ///
  /// False means every call here fails closed: no plans, no purchase, and
  /// [SanctumEntitlement.free]. Never true-by-default — a billing layer
  /// that grants access when it cannot reach the store is a worse bug
  /// than one that denies it.
  static bool get isConfigured => _configured;
  static bool _configured = false;

  /// Configures the SDK. Call once, before the first frame.
  ///
  /// ## The release-build guard is not defensive coding
  ///
  /// RevenueCat's SDK **deliberately crashes the app** if a Test Store
  /// key is used in a release build — it launches its own dialog
  /// activity and throws from `onPause`. That is a reasonable thing for
  /// them to do, because an app submitted with a test key is rejected in
  /// review, and a loud crash on a developer's device beats a silent
  /// rejection weeks later.
  ///
  /// It is still a crash, and this repo builds release APKs to test on
  /// real hardware. So a test key in a release build configures nothing:
  /// the app runs, the free tier works, and the paywall reports that
  /// plans are unavailable. Purchases are tested with a **debug** build,
  /// which is what the Test Store is for.
  ///
  /// Shipping needs `--dart-define=REVENUECAT_KEY=goog_…` / `appl_…`. If
  /// that is ever forgotten, this guard means the store is dead rather
  /// than the app — and the log line below is the breadcrumb.
  static Future<void> configure() async {
    if (usingTestStore && kReleaseMode) {
      debugPrint(
        'RevenueCat: Test Store key in a release build — billing '
        'disabled. Pass --dart-define=REVENUECAT_KEY=<goog_/appl_ key> '
        'to enable it, or use a debug build to test purchases.',
      );
      return;
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    // No appUserID: anonymous. See the class doc — this line is the
    // privacy promise.
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
  }

  @override
  Stream<SanctumEntitlement> watch() {
    late final StreamController<SanctumEntitlement> controller;

    void onUpdate(CustomerInfo info) {
      if (!controller.isClosed) controller.add(_entitlementFrom(info));
    }

    controller = StreamController<SanctumEntitlement>(
      onListen: () async {
        if (!_configured) {
          controller.add(SanctumEntitlement.free);
          return;
        }
        Purchases.addCustomerInfoUpdateListener(onUpdate);
        try {
          onUpdate(await Purchases.getCustomerInfo());
        } on Object {
          // Never having reached RevenueCat is indistinguishable from
          // not having paid, and free is the safe reading of it. A real
          // subscriber is covered by the SDK's own cache.
          if (!controller.isClosed) controller.add(SanctumEntitlement.free);
        }
      },
      onCancel: () {
        if (_configured) Purchases.removeCustomerInfoUpdateListener(onUpdate);
      },
    );

    // `addCustomerInfoUpdateListener` replays the last known value the
    // moment it is attached, so the first `getCustomerInfo` usually
    // arrives as a duplicate. Every listener rebuilds a widget.
    return controller.stream.distinct();
  }

  @override
  Future<Result<List<SubscriptionPlan>>> plans() => Result.guard(
    () async {
      if (!_configured) throw StateError('billing is not configured');
      final offering = (await Purchases.getOfferings()).current;
      if (offering == null) {
        throw StateError(
          'No current offering is configured in RevenueCat',
        );
      }

      final monthly = offering.availablePackages
          .where((p) => p.packageType == PackageType.monthly)
          .firstOrNull;

      final plans = <SubscriptionPlan>[];
      for (final package in offering.availablePackages) {
        final period = periodFrom(package.packageType);
        if (period == null) continue;
        plans.add(_planFrom(package, period, monthly));
      }
      if (plans.isEmpty) {
        throw StateError(
          'Offering "${offering.identifier}" has no monthly or annual '
          'package for this store',
        );
      }
      return plans;
    },
    // Our own StateErrors are already specific — "no current offering is
    // configured", "offering X has no plans" — and those are exactly the
    // two dashboard mistakes that produce an empty paywall. Collapsing
    // them into one generic string, which is what this did, throws away
    // the only diagnosis available at the point of failure. Anything
    // thrown by the SDK itself stays generic: a user does not need to
    // read a network stack trace.
    onError: (error, stackTrace) => ContentFailure(
      switch (error) {
        StateError(:final message) => message,
        _ => 'Could not reach the store',
      },
      cause: error,
      stackTrace: stackTrace,
    ),
  );

  @override
  Future<Result<bool>> purchase(String planId) async {
    if (!_configured) {
      return const Result.err(
        UnexpectedFailure('Purchases are unavailable in this build'),
      );
    }
    try {
      final offering = (await Purchases.getOfferings()).current;
      final package = offering?.availablePackages
          .where((p) => p.storeProduct.identifier == planId)
          .firstOrNull;
      if (package == null) {
        return const Result.err(
          NotFoundFailure('That plan is no longer available'),
        );
      }
      // `purchase(PurchaseParams)` rather than the deprecated
      // `purchasePackage`: it is the call the 10.x SDK keeps, and it is
      // the only one that can carry a promotional or win-back offer if a
      // one-off lifetime offer ever gets built on top of this.
      await Purchases.purchase(PurchaseParams.package(package));
      return const Result.ok(true);
    } on PlatformException catch (error, stackTrace) {
      // Backing out of the store sheet is a decision, not a fault. Left
      // to `Result.guard` it would land in Sentry as a handled failure
      // and the paywall would show an error for something the user did
      // deliberately — so it is caught before the guard sees it.
      //
      // `ok(false)`, not `ok(null)`: for a long time this returned the
      // latter and the paywall could not tell a cancellation from a
      // sale. See the interface.
      if (PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return const Result.ok(false);
      }
      return Result.err(
        UnexpectedFailure(
          'Purchase could not be completed',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<bool>> restore() => Result.guard(
    () async {
      if (!_configured) throw StateError('billing is not configured');
      // Restore must exist regardless of whether it usually finds
      // anything: store review requires a way back for somebody who
      // reinstalls, and with anonymous ids this is the only one there
      // is. The returned CustomerInfo is the answer to "did it work",
      // and the listener that drives `watch` updates independently.
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(entitlementId);
    },
    onError: (error, stackTrace) => UnexpectedFailure(
      'Could not restore purchases',
      cause: error,
      stackTrace: stackTrace,
    ),
  );

  @override
  Future<Result<ReportProduct?>> reportProduct() {
    return Result.guard(
      () async {
        if (!_configured) return null;

        // Fetched as a product rather than from an offering.
        // `getOfferings` returns what the dashboard has arranged into
        // packages for a paywall; a single consumable does not need to
        // be in one, and requiring it there would make the offer
        // disappear the day somebody reorganises the offerings.
        final products = await Purchases.getProducts(
          const [SubscriptionRepository.reportProductId],
          productCategory: ProductCategory.nonSubscription,
        );
        final product = products.firstOrNull;
        if (product == null) return null;

        return ReportProduct(
          id: product.identifier,
          // Straight from the store: already localised, already in the
          // user's currency. Never computed here.
          displayPrice: product.priceString,
        );
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not load the report price',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<bool>> purchaseReport() async {
    if (!_configured) {
      return const Result.err(
        UnexpectedFailure('Purchases are unavailable in this build'),
      );
    }
    try {
      final products = await Purchases.getProducts(
        const [SubscriptionRepository.reportProductId],
        productCategory: ProductCategory.nonSubscription,
      );
      final product = products.firstOrNull;
      if (product == null) {
        return const Result.err(
          NotFoundFailure('That report is not available right now'),
        );
      }

      await Purchases.purchase(PurchaseParams.storeProduct(product));
      return const Result.ok(true);
    } on PlatformException catch (error, stackTrace) {
      // Cancelling returns `ok(false)`, not `ok(null)`: backing out is a
      // decision rather than a fault, so it must not reach Sentry or
      // show an error — and it must not be mistaken for a completed
      // purchase either, or the caller grants a paid document to
      // somebody who declined to buy it.
      if (PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return const Result.ok(false);
      }
      return Result.err(
        UnexpectedFailure(
          'Purchase could not be completed',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<ReportProduct?>> messagePackProduct() {
    return Result.guard(
      () async {
        if (!_configured) return null;

        // Same reasoning as the report: fetched as a product rather
        // than from an offering, so reorganising the paywall's
        // offerings cannot make the pack disappear.
        final products = await Purchases.getProducts(
          const [SubscriptionRepository.messagePackId],
          productCategory: ProductCategory.nonSubscription,
        );
        final product = products.firstOrNull;
        if (product == null) return null;

        return ReportProduct(
          id: product.identifier,
          // Straight from the store: already localised, already in the
          // user's currency. Never computed here.
          displayPrice: product.priceString,
        );
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not load the message pack price',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<bool>> purchaseMessagePack() async {
    if (!_configured) {
      return const Result.err(
        UnexpectedFailure('Purchases are unavailable in this build'),
      );
    }
    try {
      final products = await Purchases.getProducts(
        const [SubscriptionRepository.messagePackId],
        productCategory: ProductCategory.nonSubscription,
      );
      final product = products.firstOrNull;
      if (product == null) {
        return const Result.err(
          NotFoundFailure('Messages are not available right now'),
        );
      }

      await Purchases.purchase(PurchaseParams.storeProduct(product));
      return const Result.ok(true);
    } on PlatformException catch (error, stackTrace) {
      // Cancelling returns `ok(false)`. Granting messages on anything
      // else means handing them to somebody who backed out of the
      // sheet.
      if (PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return const Result.ok(false);
      }
      return Result.err(
        UnexpectedFailure(
          'Purchase could not be completed',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  SanctumEntitlement _entitlementFrom(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlementId)
      ? SanctumEntitlement.premium
      : SanctumEntitlement.free;

  /// Maps a RevenueCat package onto the app's own model.
  ///
  /// [monthly] is passed so a yearly plan can state what it saves. That
  /// is a ratio of two prices in one currency, which is safe to compute;
  /// the prices themselves are never computed, only read.
  SubscriptionPlan _planFrom(
    Package package,
    BillingPeriod period,
    Package? monthly,
  ) {
    final product = package.storeProduct;
    final monthlyPrice = monthly?.storeProduct.price;

    int? savings;
    if (period == BillingPeriod.yearly &&
        monthlyPrice != null &&
        monthlyPrice > 0) {
      final full = monthlyPrice * 12;
      savings = (((full - product.price) / full) * 100).round().clamp(0, 99);
    }

    return SubscriptionPlan(
      id: product.identifier,
      period: period,
      displayPrice: product.priceString,
      displayPricePerMonth: product.pricePerMonthString,
      trialDays: trialDaysFrom(product.introductoryPrice),
      savingsPercent: savings == null || savings <= 0 ? null : savings,
    );
  }

  /// The app's billing period for a RevenueCat package type,
  /// or null for a package this UI cannot describe.
  @visibleForTesting
  static BillingPeriod? periodFrom(PackageType type) => switch (type) {
    PackageType.monthly => BillingPeriod.monthly,
    PackageType.annual => BillingPeriod.yearly,
    PackageType.lifetime => BillingPeriod.lifetime,
    // Weekly is deliberately unmapped: it is the highest-refund
    // configuration in this category and the app does not sell it.
    // Anything else is a custom package this UI cannot describe.
    _ => null,
  };

  /// Length of an introductory free period, in days.
  ///
  /// Only a genuinely free intro counts. A discounted-but-paid intro
  /// price is also an `introductoryPrice`, and calling that "7 days free"
  /// on the button is exactly the kind of copy App Store review rejects.
  @visibleForTesting
  static int trialDaysFrom(IntroductoryPrice? intro) {
    if (intro == null || intro.price > 0) return 0;
    return switch (intro.periodUnit) {
      PeriodUnit.day => intro.periodNumberOfUnits,
      PeriodUnit.week => intro.periodNumberOfUnits * 7,
      PeriodUnit.month => intro.periodNumberOfUnits * 30,
      PeriodUnit.year => intro.periodNumberOfUnits * 365,
      PeriodUnit.unknown => 0,
    };
  }
}
