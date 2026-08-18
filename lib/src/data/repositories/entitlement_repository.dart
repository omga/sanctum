import 'package:sanctum/src/core/result/result.dart';

/// What the user is entitled to.
enum SanctumEntitlement {
  /// The free tier.
  free,

  /// Full access.
  premium;

  /// Whether everything is unlocked.
  bool get isPremium => this == SanctumEntitlement.premium;
}

/// The single place the app asks "is this user premium?".
///
/// ## Why this exists before there is a paywall
///
/// Sanctum v1 ships without subscriptions — that was a deliberate scoping
/// call. This interface exists anyway because the alternative is worse:
/// without it, "is this locked?" checks get written inline against
/// whatever is convenient, and adding RevenueCat later means touching
/// every feature that ever gated anything.
///
/// With it, the whole migration is one new implementation of one
/// interface and one changed provider override. Nothing above this line
/// knows a payment SDK exists — which is also what keeps the widget tests
/// from needing one.
abstract interface class EntitlementRepository {
  /// The current entitlement, updated when it changes.
  Stream<SanctumEntitlement> watch();

  /// Restores a previous purchase.
  ///
  /// Resolves to whether the user holds an entitlement *after* the
  /// attempt. A plain `Result<void>` cannot express "that worked and
  /// found nothing", which is the single most common outcome and the
  /// one a user most needs told — otherwise the button looks broken.
  Future<Result<bool>> restore();
}

/// Grants everything, always.
///
/// The v1 implementation. Swapping this for a RevenueCat-backed one is
/// the entire paywall migration on this side of the boundary.
class UnlockedEntitlementRepository implements EntitlementRepository {
  /// Creates an always-premium repository.
  const UnlockedEntitlementRepository();

  @override
  Stream<SanctumEntitlement> watch() =>
      Stream.value(SanctumEntitlement.premium);

  @override
  Future<Result<bool>> restore() async => const Result.ok(true);
}
