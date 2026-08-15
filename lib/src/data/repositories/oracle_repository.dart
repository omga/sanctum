import 'package:drift/drift.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';

/// The state of a day's oracle draw.
class OracleDrawState {
  /// Creates a draw state.
  const OracleDrawState({required this.cardId, required this.revealed});

  /// Catalogue id of the assigned card.
  final String cardId;

  /// Whether the user has flipped it.
  final bool revealed;
}

/// Persists which card belongs to which day, and whether it is flipped.
///
/// The card *assignment* is computed, not stored — see
/// `DailyAttunementSelector`. What is stored is the reveal, because that
/// is a user action and cannot be recomputed.
abstract interface class OracleRepository {
  /// The draw for [day], or `null` if none has been assigned yet.
  Stream<OracleDrawState?> watchDraw(DateTime day);

  /// Assigns [cardId] to [day] if nothing is assigned yet.
  Future<Result<void>> ensureAssigned({
    required DateTime day,
    required String cardId,
  });

  /// Marks [day]'s card as revealed.
  Future<Result<void>> reveal(DateTime day);

  /// Ids of every card ever revealed, newest first.
  Stream<List<String>> watchRevealedHistory();
}

/// Drift-backed [OracleRepository].
class DriftOracleRepository implements OracleRepository {
  /// Creates a repository over [SanctumDatabase].
  const DriftOracleRepository(this._db);

  final SanctumDatabase _db;

  @override
  Stream<OracleDrawState?> watchDraw(DateTime day) {
    final query = _db.select(_db.oracleDraws)
      ..where((t) => t.drawnOn.equals(day.dateOnly))
      ..limit(1);

    return query.watchSingleOrNull().map(
      (row) => row == null
          ? null
          : OracleDrawState(cardId: row.cardId, revealed: row.revealed),
    );
  }

  @override
  Future<Result<void>> ensureAssigned({
    required DateTime day,
    required String cardId,
  }) {
    return Result.guard(
      () async {
        final date = day.dateOnly;
        final existing =
            await (_db.select(_db.oracleDraws)
                  ..where((t) => t.drawnOn.equals(date))
                  ..limit(1))
                .getSingleOrNull();
        if (existing != null) return;

        await _db
            .into(_db.oracleDraws)
            .insert(
              OracleDrawsCompanion.insert(cardId: cardId, drawnOn: date),
            );
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not assign card',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> reveal(DateTime day) {
    return Result.guard(
      () async {
        await (_db.update(_db.oracleDraws)
              ..where((t) => t.drawnOn.equals(day.dateOnly)))
            .write(const OracleDrawsCompanion(revealed: Value(true)));
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not reveal card',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Stream<List<String>> watchRevealedHistory() {
    final query = _db.select(_db.oracleDraws)
      ..where((t) => t.revealed.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.drawnOn)]);

    return query.watch().map((rows) => [for (final r in rows) r.cardId]);
  }
}
