import 'dart:math' as math;

import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-relational app state.
///
/// Deliberately not in the database. These are single scalar values read
/// on the very first frame; putting them in SQLite would mean opening a
/// database before the app can decide which screen to show.
abstract interface class SettingsRepository {
  /// A stable per-install identifier, created on first use.
  ///
  /// Used to salt daily content selection so two people do not receive
  /// the same card. It never leaves the device and identifies nobody —
  /// it exists purely to decorrelate two installs.
  Future<Result<String>> installSalt();

  /// Whether onboarding has been completed.
  Future<Result<bool>> hasOnboarded();

  /// Records that onboarding finished.
  Future<Result<void>> setOnboarded();

  /// The date of first launch, recorded on first read.
  ///
  /// Drives "days since install", which the paywall trigger needs and
  /// which no platform API reports reliably.
  Future<Result<DateTime>> installDate();

  /// How many times the paywall has been shown, and refused.
  Future<Result<({int shown, int dismissed, DateTime? lastShown})>>
  paywallState();

  /// Records that the paywall was shown at [at].
  Future<Result<void>> recordPaywallShown(DateTime at);

  /// Records that the paywall was dismissed without purchase.
  Future<Result<void>> recordPaywallDismissed();
}

/// [SettingsRepository] backed by shared_preferences.
class PreferencesSettingsRepository implements SettingsRepository {
  /// Creates a repository.
  const PreferencesSettingsRepository();

  static const _saltKey = 'sanctum.install_salt';
  static const _onboardedKey = 'sanctum.has_onboarded';
  static const _installDateKey = 'sanctum.install_date';
  static const _paywallShownKey = 'sanctum.paywall_shown_count';
  static const _paywallDismissedKey = 'sanctum.paywall_dismissed_count';
  static const _paywallLastShownKey = 'sanctum.paywall_last_shown';

  @override
  Future<Result<String>> installSalt() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final existing = prefs.getString(_saltKey);
        if (existing != null && existing.isNotEmpty) return existing;

        final generated = _generateSalt();
        await prefs.setString(_saltKey, generated);
        return generated;
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read install salt',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<bool>> hasOnboarded() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_onboardedKey) ?? false;
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read onboarding state',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> setOnboarded() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_onboardedKey, true);
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save onboarding state',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<DateTime>> installDate() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getInt(_installDateKey);
        if (stored != null) {
          return DateTime.fromMillisecondsSinceEpoch(stored);
        }
        final now = DateTime.now();
        await prefs.setInt(_installDateKey, now.millisecondsSinceEpoch);
        return now;
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read install date',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<({int shown, int dismissed, DateTime? lastShown})>>
  paywallState() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final last = prefs.getInt(_paywallLastShownKey);
        return (
          shown: prefs.getInt(_paywallShownKey) ?? 0,
          dismissed: prefs.getInt(_paywallDismissedKey) ?? 0,
          lastShown: last == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(last),
        );
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read paywall state',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> recordPaywallShown(DateTime at) {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final shown = prefs.getInt(_paywallShownKey) ?? 0;
        await prefs.setInt(_paywallShownKey, shown + 1);
        await prefs.setInt(_paywallLastShownKey, at.millisecondsSinceEpoch);
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not record paywall impression',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> recordPaywallDismissed() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final dismissed = prefs.getInt(_paywallDismissedKey) ?? 0;
        await prefs.setInt(_paywallDismissedKey, dismissed + 1);
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not record paywall dismissal',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  /// 128 bits of entropy, hex encoded.
  ///
  /// `Random.secure()` rather than `Random()` — not because this is a
  /// secret, but because a seeded generator on a freshly-booted device
  /// can produce the same value across installs, which would defeat the
  /// one job this string has.
  String _generateSalt() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
