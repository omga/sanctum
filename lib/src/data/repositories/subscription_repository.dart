import 'dart:async';

import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/repositories/entitlement_repository.dart';
import 'package:sanctum/src/domain/models/report_product.dart';
import 'package:sanctum/src/domain/models/subscription_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Buying a subscription.
///
/// Deliberately separate from [EntitlementRepository]. Almost every
/// feature needs to ask "is this user premium?"; only the paywall needs
/// "what can they buy and how do I charge them". Keeping the read side
/// tiny means a feature can depend on entitlements without dragging a
/// billing SDK into its tests.
abstract interface class SubscriptionRepository {
  /// Store identifier for the one-off report.
  ///
  /// One product, not one per pairing: the store sells "a relationship
  /// report", and *which* pairing it unlocks is the app's own business.
  /// A product per pairing would mean an App Store Connect entry per
  /// human being on earth.
  ///
  /// It must be configured as a **consumable** (iOS) / repeatable
  /// one-time product (Play). A non-consumable can only be bought once
  /// ever, which would let a user buy exactly one report and then be
  /// told they already own the product when they try to buy a second.
  /// Verified against the RevenueCat Test Store: two purchases of this
  /// id in a row both succeed.
  ///
  /// Lives on the interface rather than on the local stub, so the
  /// RevenueCat implementation does not have to reach into a
  /// development stand-in for the id it sells.
  static const String reportProductId = 'sanctum.report.relationship';

  /// The message pack's store id.
  ///
  /// A consumable, bought repeatedly. Named for what it contains rather
  /// than for a price, because the price is per storefront and the
  /// contents are not.
  static const String messagePackId = 'sanctum.advisor.messages5';

  /// The plans on offer.
  Future<Result<List<SubscriptionPlan>>> plans();

  /// Purchases [planId].
  ///
  /// Returns **whether it was actually bought**. Backing out of the
  /// store sheet is a decision rather than a fault, so it must not be an
  /// `Err` — that would land in Sentry and show an error for something
  /// the user chose. It must not read as success either: this returned
  /// `Result<void>` once, and the paywall consequently treated every
  /// cancellation as a completed sale — firing `purchase_completed`,
  /// flipping the screen to its purchased state, closing itself, and
  /// skipping the dismissal that drives the trigger's backoff.
  Future<Result<bool>> purchase(String planId);

  /// The one-off relationship report, or `null` where it is not on sale.
  ///
  /// Null is a real answer: a build with no store account, a product not
  /// yet approved, or a region where it is not offered. The caller shows
  /// no offer at all rather than a button that cannot work.
  Future<Result<ReportProduct?>> reportProduct();

  /// Buys the one-off report.
  ///
  /// Same contract as [purchase] — the bool is whether they bought —
  /// and a separate method because it is a separate store call: a
  /// consumable product rather than a package from an offering.
  Future<Result<bool>> purchaseReport();

  /// The message pack's price, or null where it is not on sale.
  Future<Result<ReportProduct?>> messagePackProduct();

  /// Buys a pack of advisor messages.
  ///
  /// Same contract as [purchaseReport]: the bool is whether they bought,
  /// and a cancelled store sheet is a *successful* result carrying
  /// false. Anything else has this app counting a refusal as a sale,
  /// which `analytics.md` records it doing once already.
  Future<Result<bool>> purchaseMessagePack();

  /// Restores a previous purchase. See [EntitlementRepository.restore].
  Future<Result<bool>> restore();
}

/// Both halves of billing, served by one object.
///
/// `Purchases` is a single SDK that answers "what can they buy" and "what
/// do they own", and every implementation here mirrors that. The
/// interfaces stay separate because almost every feature needs only the
/// second one; this exists so a provider can hand out one instance
/// without the call site casting.
abstract interface class BillingRepository
    implements SubscriptionRepository, EntitlementRepository {}

/// A local stand-in for a real store.
///
/// ## Why this exists
///
/// Real purchases cannot be exercised without App Store Connect products
/// and a RevenueCat key. Rather than write a paywall that cannot be run,
/// this implements the same two interfaces against `shared_preferences`:
/// the flow, the gating, the trigger logic and the UI are all genuinely
/// testable today.
///
/// Swapping in RevenueCat is one new class implementing these interfaces
/// plus one changed provider. Nothing else in the app knows the
/// difference — no feature, no widget, no test.
///
/// The prices below are placeholders. Real ones must come from the store
/// at runtime; hard-coding prices is both a localisation bug and an App
/// Store rejection.
class LocalSubscriptionRepository implements BillingRepository {
  /// Creates the local store.
  LocalSubscriptionRepository();

  static const _entitlementKey = 'sanctum.entitlement_premium';

  final _controller = StreamController<SanctumEntitlement>.broadcast();

  @override
  Stream<SanctumEntitlement> watch() async* {
    yield await _read();
    yield* _controller.stream;
  }

  /// Stand-in plans, mirroring what the store is configured at today.
  ///
  /// Kept in step with the real products for one reason: a local-billing
  /// build is what gets screenshotted and demoed, and a paywall showing
  /// a price nobody will be charged — or, worse, a free trial that does
  /// not exist — is a promise the store will not keep. **`trialDays` is
  /// null because the live products have no introductory offer.** The
  /// previous value here claimed seven free days.
  ///
  /// Still not authoritative. Real prices are per storefront and change
  /// without the app shipping; only the store knows them, which is why
  /// every other path reads them at runtime.
  @override
  Future<Result<List<SubscriptionPlan>>> plans() async {
    return const Result.ok([
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
  }

  @override
  Future<Result<bool>> purchase(String planId) {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_entitlementKey, true);
        _controller.add(SanctumEntitlement.premium);
        // Always true: cancellation is only reachable through a real
        // store sheet, and the bool exists for that path.
        return true;
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Purchase could not be completed',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  /// A stand-in price, and it says so.
  ///
  /// Mirrors what the store is configured at today so a local-billing
  /// build does not show a number nobody will ever be charged — but it
  /// is not authoritative and never can be: a real price is per
  /// storefront, per currency, and changes without the app shipping.
  /// The only real price is [SubscriptionRepository.reportProduct]'s,
  /// read from the store at runtime.
  static const String placeholderReportPrice = r'$3.99';

  /// The message pack's placeholder price. Same caveat as above: the
  /// only real one comes from the store.
  static const String placeholderMessagePackPrice = r'$2.99';

  @override
  Future<Result<ReportProduct?>> reportProduct() async => const Result.ok(
    ReportProduct(
      id: SubscriptionRepository.reportProductId,
      displayPrice: placeholderReportPrice,
    ),
  );

  @override
  Future<Result<bool>> purchaseReport() async {
    // The local store always succeeds. Cancellation is only reachable
    // through a real store sheet, and the tri-state exists for that
    // path — see the interface.
    return const Result.ok(true);
  }

  @override
  Future<Result<ReportProduct?>> messagePackProduct() async =>
      const Result.ok(
        ReportProduct(
          id: SubscriptionRepository.messagePackId,
          displayPrice: placeholderMessagePackPrice,
        ),
      );

  @override
  Future<Result<bool>> purchaseMessagePack() async => const Result.ok(true);

  @override
  Future<Result<bool>> restore() {
    return Result.guard(
      () async {
        final entitlement = await _read();
        _controller.add(entitlement);
        return entitlement.isPremium;
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not restore purchases',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Development affordance: drop back to the free tier.
  ///
  /// Without this there is no way to see the paywall twice on one device,
  /// which makes the whole flow untestable by hand.
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entitlementKey);
    _controller.add(SanctumEntitlement.free);
  }

  Future<SanctumEntitlement> _read() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_entitlementKey) ?? false)
        ? SanctumEntitlement.premium
        : SanctumEntitlement.free;
  }
}
