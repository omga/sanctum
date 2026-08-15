import 'package:drift/drift.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/domain/models/energy_check_in.dart';

/// Reads and writes daily energy check-ins.
abstract interface class EnergyRepository {
  /// Check-ins from the last [days] days, oldest first.
  Stream<List<EnergyCheckIn>> watchRecent({int days = 30});

  /// Today's check-in, or `null` if not yet recorded.
  Stream<EnergyCheckIn?> watchFor(DateTime day);

  /// Records (or replaces) the check-in for [day].
  Future<Result<void>> record({
    required EnergyLevel level,
    required DateTime day,
    String? note,
  });
}

/// Drift-backed [EnergyRepository].
class DriftEnergyRepository implements EnergyRepository {
  /// Creates a repository over [SanctumDatabase].
  const DriftEnergyRepository(this._db);

  final SanctumDatabase _db;

  @override
  Stream<List<EnergyCheckIn>> watchRecent({int days = 30}) {
    final query = _db.select(_db.energyCheckIns)
      ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)])
      ..limit(days);

    return query.watch().map(
      (rows) => [for (final row in rows) _toDomain(row)],
    );
  }

  @override
  Stream<EnergyCheckIn?> watchFor(DateTime day) {
    final start = day.dateOnly;
    final end = start.add(const Duration(days: 1));

    final query = _db.select(_db.energyCheckIns)
      ..where((t) => t.recordedAt.isBetweenValues(start, end))
      ..limit(1);

    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toDomain(row),
    );
  }

  @override
  Future<Result<void>> record({
    required EnergyLevel level,
    required DateTime day,
    String? note,
  }) {
    return Result.guard(
      () async {
        final start = day.dateOnly;
        final end = start.add(const Duration(days: 1));

        // One check-in per day: changing your mind at noon should update
        // the day, not append a second reading that skews the average.
        await _db.transaction(() async {
          await (_db.delete(
            _db.energyCheckIns,
          )..where((t) => t.recordedAt.isBetweenValues(start, end))).go();
          await _db
              .into(_db.energyCheckIns)
              .insert(
                EnergyCheckInsCompanion.insert(
                  recordedAt: day,
                  level: level.value,
                  note: Value(note),
                ),
              );
        });
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save check-in',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  EnergyCheckIn _toDomain(EnergyCheckInRow row) => EnergyCheckIn(
    id: row.id,
    recordedAt: row.recordedAt,
    level: EnergyLevel.fromValue(row.level),
    note: row.note,
  );
}
