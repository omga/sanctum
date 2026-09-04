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

  /// Owned, or for sale.
  final ReportAccess access;

  /// What it costs, when it is on sale at all.
  final ReportProduct? product;

  /// Whether a store sheet is open right now.
  final bool isPurchasing;

  /// Whether the document may be shown.
  bool get isOwned => access == ReportAccess.owned;

  /// Whether there is something to sell and a price to sell it at.
  bool get canBuy => !isOwned && product != null;
}

/// Owns the buy flow for one match's report.
@riverpod
class ReportController extends _$ReportController {
  @override
  Future<ReportUiState> build(CompatibilityMatch match) async {
    final purchased = await ref.watch(reportRepositoryProvider).purchased();
    final product = await ref.watch(reportProductProvider.future);

    return ReportUiState(
      access: ReportGate.decide(
        matchId: match.id,
        // A read failure must not be read as "owns nothing": that would
        // offer to re-sell a document the user has already paid for. It
        // is surfaced as an error instead, and the screen says so.
        purchasedIds: switch (purchased) {
          Ok(:final value) => value,
          Err(:final failure) => throw StateError(failure.message),
        },
        isPremium: ref.watch(isPremiumProvider),
      ),
      product: product,
      isPurchasing: false,
    );
  }

  /// Buys the report for this pairing.
  ///
  /// Returns whether the user now owns it. `false` covers backing out of
  /// the store sheet, which is not an error and must not be reported as
  /// one — nor granted as a purchase.
  Future<bool> buy() async {
    final current = state.value;
    if (current == null || current.isOwned) return current?.isOwned ?? false;

    final product = current.product;
    if (product == null) return false;

    final analytics = ref.read(analyticsProvider)
      ..track(AnalyticsEvent.purchaseStarted(plan: product.id));

    state = AsyncData(
      ReportUiState(
        access: current.access,
        product: product,
        isPurchasing: true,
      ),
    );

    final result = await ref
        .read(subscriptionRepositoryProvider)
        .purchaseReport();

    switch (result) {
      case Ok(value: final bought):
        if (!bought) {
          // Cancelled. Nothing is granted and nothing is reported: a
          // purchase event here is exactly the bug that makes
          // `purchase_completed` unusable on the subscription paywall.
          state = AsyncData(
            ReportUiState(
              access: current.access,
              product: product,
              isPurchasing: false,
            ),
          );
          return false;
        }

        // Recorded before the state flips, so a write failure cannot
        // leave the user looking at a document the app will not
        // remember they bought.
        final saved = await ref
            .read(reportRepositoryProvider)
            .recordPurchase(match.id);
        if (saved case Err(:final failure)) {
          state = AsyncError(failure, StackTrace.current);
          return false;
        }

        analytics.track(AnalyticsEvent.purchaseCompleted(plan: product.id));
        ref.invalidateSelf();
        return true;

      case Err(:final failure):
        state = AsyncError(failure, StackTrace.current);
        return false;
    }
  }
}
