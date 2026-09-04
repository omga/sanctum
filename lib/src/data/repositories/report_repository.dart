import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which reports the user has bought.
///
/// ## Why this is not part of `CompatibilityState`
///
/// It would fit there — same feature, same screen, one fewer read. It is
/// deliberately separate because of how that blob handles corruption:
/// `PreferencesCompatibilityRepository` catches a decode failure and
/// returns an *empty* state, on the reasoning that "losing old matches on
/// an upgrade is a small cost" and a feature that can never write again
/// is a large one. That reasoning is correct for match history and wrong
/// for receipts. A match the user can recompute in four taps is not the
/// same object as a document they paid for, and silently discarding the
/// second one is a refund and a support email rather than a small cost.
///
/// So purchases live under their own key, as a flat list of ids that no
/// model change can invalidate, written independently of anything else.
/// The blob shape most likely to break — the one holding composed
/// readings, which changes whenever the reading model does — cannot take
/// this with it.
///
/// ## Why the store is not the source of truth
///
/// These are consumables. Unlike a subscription, a consumable does not
/// come back as an active entitlement, and there is nothing on the device
/// or in RevenueCat's customer info that says "they own the report about
/// this pairing" — the pairing is the app's own concept and the store has
/// never heard of it. The grant is therefore local, and this file is the
/// receipt. See the caveat on [recordPurchase].
abstract interface class ReportRepository {
  /// Ids of the matches whose reports have been bought.
  Future<Result<Set<String>>> purchased();

  /// Records that the report for [matchId] was bought.
  ///
  /// Called only after the store has confirmed a completed purchase.
  ///
  /// **A reinstall loses this.** Consumables do not restore, so there is
  /// nothing to replay against. That is a real product decision and not
  /// an oversight: the alternatives are a backend that maps a customer to
  /// their purchased pairings, or granting anything the user asks for on
  /// a fresh install. Until one is chosen, this is what the refund policy
  /// has to cover.
  Future<Result<void>> recordPurchase(String matchId);
}

/// [ReportRepository] backed by shared_preferences.
class PreferencesReportRepository implements ReportRepository {
  /// Creates a repository.
  const PreferencesReportRepository();

  static const _key = 'sanctum.reports_purchased';

  @override
  Future<Result<Set<String>>> purchased() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        return (prefs.getStringList(_key) ?? const <String>[]).toSet();
      },
      // Note the difference from the match blob: this failure is
      // reported rather than swallowed into an empty set. A read error
      // here means somebody may be about to be charged twice, which is
      // worth surfacing instead of quietly re-selling.
      onError: (error, stackTrace) => StorageFailure(
        'Could not read your reports',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> recordPurchase(String matchId) {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final owned = prefs.getStringList(_key) ?? const <String>[];
        if (owned.contains(matchId)) return;
        await prefs.setStringList(_key, [...owned, matchId]);
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save your purchase',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
