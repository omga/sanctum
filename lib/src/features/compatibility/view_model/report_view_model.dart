import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/relationship_report.dart';
import 'package:sanctum/src/domain/models/report_product.dart';
import 'package:sanctum/src/domain/services/report_composer.dart';
import 'package:sanctum/src/domain/services/report_gate.dart';

part 'report_view_model.g.dart';

/// The deep report for one already-revealed [match].
///
/// A family keyed on the match itself rather than on its id: the id is
/// only meaningful against stored state, and the composer needs the
/// whole reading anyway. `dart_mappable` gives [CompatibilityMatch] value
/// equality, so two builds with the same pairing hit the same provider
/// instead of recomposing.
///
/// Composition is pure and takes well under a millisecond — the
/// ephemeris already ran to produce the match — so this is async only
/// because the content catalogue is.
///
/// Deliberately unaware of whether the report has been paid for.
/// Composing is free, and keeping the document and the entitlement in
/// separate providers is what lets the offer card quote real details
/// from a report nobody has bought yet.
@riverpod
Future<RelationshipReport> relationshipReport(
  Ref ref,
  CompatibilityMatch match,
) async {
  final catalog = await ref.watch(contentCatalogProvider.future);
  return ReportComposer.compose(match: match, copy: catalog.copy);
}

/// The price of the one-off report, or null where it is not on sale.
@riverpod
Future<ReportProduct?> reportProduct(Ref ref) async {
  final result = await ref.watch(subscriptionRepositoryProvider)
      .reportProduct();
  // A price we cannot read is the same as no offer: better to show
  // nothing than a button whose price is a guess.
  return result.getOrElse(null);
}

/// What the user may do with the report for a given match.
class ReportUiState {
  /// Creates the state.
  const ReportUiState({
    required this.access,
    required this.product,
    required this.isPurchasing,
  });

  /// Owned, included with a subscription, or for sale.
  final ReportAccess access;

  /// What it costs, when it is on sale at all.
  final ReportProduct? product;

  /// Whether a store sheet is open right now.
  final bool isPurchasing;

  /// Whether the document may be shown.
  bool get isOwned => access == ReportAccess.owned;

  /// Whether a subscriber can open this one on their included slot.
  bool get isIncluded => access == ReportAccess.includedWithPremium;

  /// Whether there is something to sell and a price to sell it at.
  bool get canBuy => access == ReportAccess.forSale && product != null;
}

/// Owns the buy flow for one match's report.
@riverpod
class ReportController extends _$ReportController {
  @override
  Future<ReportUiState> build(CompatibilityMatch match) async {
    final repository = ref.watch(reportRepositoryProvider);
    final purchased = await repository.purchased();
    final included = await repository.includedReportId();
    final product = await ref.watch(reportProductProvider.future);

    // A read failure must not be read as "owns nothing": that would
    // offer to re-sell a document the user has already paid for, or hand
    // out a second free one. Both are surfaced as errors instead, and
    // the screen says so.
    return ReportUiState(
      access: ReportGate.decide(
        matchId: match.id,
        purchasedIds: switch (purchased) {
          Ok(:final value) => value,
          Err(:final failure) => throw StateError(failure.message),
        },
        includedReportId: switch (included) {
          Ok(:final value) => value,
          Err(:final failure) => throw StateError(failure.message),
        },
        isPremium: ref.watch(isPremiumProvider),
      ),
      product: product,
      isPurchasing: false,
    );
  }

  /// Spends the subscriber's included report on this pairing.
  ///
  /// Deliberately an action rather than something that happens on open:
  /// it is the only one they get, and spending it silently on a pairing
  /// they tapped out of curiosity would be a worse surprise than one
  /// extra tap. The compatibility gate asks for its invite the same way.
  Future<bool> claimIncluded() async {
    final current = state.value;
    if (current == null || !current.isIncluded) return false;

    // Captured before the await. See [buy] for why reaching for a
    // provider afterwards is not safe.
    final reports = ref.read(reportRepositoryProvider);
    final analytics = ref.read(analyticsProvider);

    final saved = await reports.claimIncludedReport(match.id);

    if (saved case Err(:final failure)) {
      if (ref.mounted) state = AsyncError(failure, StackTrace.current);
      return false;
    }

    // Not `purchaseCompleted`: nothing was bought. Counting this as a
    // sale would inflate the number the whole SKU is being judged on.
    analytics.track(AnalyticsEvent.reportUnlocked(access: 'included'));
    if (ref.mounted) ref.invalidateSelf();
    return true;
  }

  /// Buys the report for this pairing.
  ///
  /// Returns whether the user now owns it. `false` covers backing out of
  /// the store sheet, which is not an error and must not be reported as
  /// one — nor granted as a purchase.
  ///
  /// ## Every dependency is read before the first await
  ///
  /// This provider auto-disposes, and a store sheet can outlive the
  /// screen that opened it — the user can background the app or pop back
  /// while it is up. `ref.read(...)` on a disposed `Ref` throws, so
  /// reaching for the repository *after* the purchase returns would
  /// crash exactly where the money has already moved, losing the grant
  /// for a report they were charged for. Reading them up front means the
  /// grant only needs the objects, not the `Ref`.
  ///
  /// `state` and `invalidateSelf` still need it, and those are guarded:
  /// skipping a UI update for a screen that is gone is correct, whereas
  /// skipping the receipt never is.
  Future<bool> buy() async {
    final current = state.value;
    if (current == null || current.isOwned) return current?.isOwned ?? false;

    final product = current.product;
    if (product == null) return false;

    final analytics = ref.read(analyticsProvider)
      ..track(AnalyticsEvent.purchaseStarted(plan: product.id));
    final reports = ref.read(reportRepositoryProvider);
    final store = ref.read(subscriptionRepositoryProvider);

    state = AsyncData(
      ReportUiState(
        access: current.access,
        product: product,
        isPurchasing: true,
      ),
    );

    final result = await store.purchaseReport();

    switch (result) {
      case Ok(value: final bought):
        if (!bought) {
          // Cancelled. Nothing is granted and nothing is reported: a
          // purchase event here is exactly the bug that makes
          // `purchase_completed` unusable on the subscription paywall.
          if (ref.mounted) {
            state = AsyncData(
              ReportUiState(
                access: current.access,
                product: product,
                isPurchasing: false,
              ),
            );
          }
          return false;
        }

        // Recorded before the state flips, so a write failure cannot
        // leave the user looking at a document the app will not
        // remember they bought.
        final saved = await reports.recordPurchase(match.id);
        if (saved case Err(:final failure)) {
          if (ref.mounted) state = AsyncError(failure, StackTrace.current);
          return false;
        }

        analytics
          ..track(AnalyticsEvent.purchaseCompleted(plan: product.id))
          ..track(AnalyticsEvent.reportUnlocked(access: 'purchase'));
        if (ref.mounted) ref.invalidateSelf();
        return true;

      case Err(:final failure):
        if (ref.mounted) state = AsyncError(failure, StackTrace.current);
        return false;
    }
  }
}
