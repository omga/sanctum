import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the user has earned on the palm feature.
///
/// ## What is deliberately not here
///
/// **No scan is stored.** Not the still, not the landmarks, not the
/// derived curves, not a thumbnail. A palm scan is hand geometry, which
/// US biometric-privacy statutes name explicitly, and the only
/// defensible answer is that the measurement does not outlive the screen
/// that made it.
///
/// So this holds ids and a flag, and nothing that could be turned back
/// into a hand. The consequence is real and intended: a reading cannot
/// be reopened after the app is killed, because there is nothing left to
/// reopen it from. That is a worse product than a scan history and a
/// far better position to be in.
///
/// The id itself is a timestamp and a handedness — see
/// `PalmScanIdentity` — chosen so that it identifies a *session* rather
/// than a person. Two scans of the same palm produce different ids on
/// purpose.
abstract interface class PalmRepository {
  /// Scans whose reading has been unlocked.
  Future<Result<Set<String>>> unlockedReadings();

  /// Records that the reading for [scanId] is unlocked.
  Future<Result<void>> recordUnlock(String scanId);

  /// Whether a scan has ever been shared.
  ///
  /// One flag rather than a count, for the same reason
  /// `CompatibilityGate` uses one: the allowance is one reading, so a
  /// second share buys nothing and counting them would only invite
  /// somebody to try.
  Future<Result<bool>> hasSharedScan();

  /// Records that the share sheet reported a completed share.
  ///
  /// **This does not mean anything was posted.** The platform reports
  /// that an app was picked and nothing more — see
  /// `ShareController.shareInvite`, which says so at length. Picking a
  /// target is the strongest signal available, and the failure mode
  /// (somebody opens TikTok, backs out, keeps the reading) is a far
  /// better one than withholding a reading from a user who did share.
  Future<Result<void>> recordShare();
}

/// [PalmRepository] backed by shared_preferences.
class PreferencesPalmRepository implements PalmRepository {
  /// Creates a repository.
  const PreferencesPalmRepository();

  static const _unlockedKey = 'sanctum.palm_unlocked';
  static const _sharedKey = 'sanctum.palm_shared';

  @override
  Future<Result<Set<String>>> unlockedReadings() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        return (prefs.getStringList(_unlockedKey) ?? const <String>[]).toSet();
      },
      // Reported rather than swallowed into an empty set, like
      // `ReportRepository.purchased`: reading "nothing unlocked" when
      // something was is how a user gets asked to pay twice.
      onError: (error, stackTrace) => StorageFailure(
        'Could not read your readings',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> recordUnlock(String scanId) {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final owned = prefs.getStringList(_unlockedKey) ?? const <String>[];
        if (owned.contains(scanId)) return;
        await prefs.setStringList(_unlockedKey, [...owned, scanId]);
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save your reading',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<bool>> hasSharedScan() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_sharedKey) ?? false;
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read your share',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> recordShare() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_sharedKey, true);
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save your share',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
