import 'dart:async';

import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/repositories/entitlement_repository.dart';
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
  /// The plans on offer.
  Future<Result<List<SubscriptionPlan>>> plans();

  /// Purchases [planId].
  Future<Result<void>> purchase(String planId);

  /// Restores a previous purchase.
  Future<Result<void>> restore();
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

  @override
  Future<Result<List<SubscriptionPlan>>> plans() async {
    return const Result.ok([
      SubscriptionPlan(
        id: 'sanctum.premium.monthly',
        period: BillingPeriod.monthly,
        displayPrice: '£6.99',
        displayPricePerMonth: '£6.99',
      ),
      SubscriptionPlan(
        id: 'sanctum.premium.yearly',
        period: BillingPeriod.yearly,
        displayPrice: '£39.99',
        displayPricePerMonth: '£3.33',
        trialDays: 7,
        savingsPercent: 52,
      ),
    ]);
  }

  @override
  Future<Result<void>> purchase(String planId) {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_entitlementKey, true);
        _controller.add(SanctumEntitlement.premium);
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Purchase could not be completed',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> restore() {
    return Result.guard(
      () async {
        _controller.add(await _read());
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
