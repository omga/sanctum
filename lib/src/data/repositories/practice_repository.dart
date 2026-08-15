import 'package:drift/drift.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/domain/models/streak_summary.dart';
import 'package:sanctum/src/domain/services/streak_calculator.dart';

/// Reads and writes the practice log, and derives streaks from it.
///
/// Note the split of responsibilities: this class knows about SQL, and
/// [StreakCalculator] knows about streak rules. Neither knows about the
/// other's domain. That is why the streak rules can be exhaustively unit
/// tested without a database, and why the storage can be replaced without
/// re-deriving what a streak means.
abstract interface class PracticeRepository {
  /// Records a completed session.
  Future<Result<void>> recordCompletion({
    required String sessionId,
    required DateTime completedAt,
    required Duration listened,
  });

  /// The user's streak as of [today], recomputed on every change.
  Stream<StreakSummary> watchStreak(DateTime today);

  /// Total number of completed sessions.
  Future<Result<int>> totalSessions();
}

/// Drift-backed [PracticeRepository].
class DriftPracticeRepository implements PracticeRepository {
  /// Creates a repository over [SanctumDatabase].
  const DriftPracticeRepository(this._db);

  final SanctumDatabase _db;

  @override
  Future<Result<void>> recordCompletion({
    required String sessionId,
    required DateTime completedAt,
    required Duration listened,
  }) {
    return Result.guard(
      () async {
        await _db
            .into(_db.practiceLog)
            .insert(
              PracticeLogCompanion.insert(
                sessionId: sessionId,
                completedAt: completedAt,
                durationSeconds: listened.inSeconds,
              ),
            );
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not record practice',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Stream<StreakSummary> watchStreak(DateTime today) {
    // Only the dates are selected, not whole rows: the streak rules need
    // nothing else, and a user with years of history should not pull
    // every column into memory to find out their streak is 4.
    final query = _db.selectOnly(_db.practiceLog, distinct: true)
      ..addColumns([_db.practiceLog.completedAt]);

    return query.watch().map((rows) {
      final dates = rows
          .map((row) => row.read(_db.practiceLog.completedAt))
          .whereType<DateTime>();
      return StreakCalculator.summarise(activeDates: dates, today: today);
    });
  }

  @override
  Future<Result<int>> totalSessions() {
    return Result.guard(
      () async {
        final count = _db.practiceLog.id.count();
        final row = await (_db.selectOnly(
          _db.practiceLog,
        )..addColumns([count])).getSingle();
        return row.read(count) ?? 0;
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not count sessions',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
