import 'package:drift/drift.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';

/// Reads and writes journal entries.
abstract interface class JournalRepository {
  /// All entries, newest first, updated live.
  Stream<List<JournalEntry>> watchEntries();

  /// Adds an entry and returns its new id.
  Future<Result<int>> add({
    required JournalKind kind,
    required String body,
    required DateTime createdAt,
    String? prompt,
  });

  /// Deletes the entry with [id].
  Future<Result<void>> delete(int id);
}

/// Drift-backed [JournalRepository].
class DriftJournalRepository implements JournalRepository {
  /// Creates a repository over [SanctumDatabase].
  const DriftJournalRepository(this._db);

  final SanctumDatabase _db;

  @override
  Stream<List<JournalEntry>> watchEntries() {
    final query = _db.select(_db.journalEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          JournalEntry(
            id: row.id,
            createdAt: row.createdAt,
            kind: row.kind,
            body: row.body,
            prompt: row.prompt,
          ),
      ],
    );
  }

  @override
  Future<Result<int>> add({
    required JournalKind kind,
    required String body,
    required DateTime createdAt,
    String? prompt,
  }) {
    return Result.guard(
      () => _db
          .into(_db.journalEntries)
          .insert(
            JournalEntriesCompanion.insert(
              createdAt: createdAt,
              kind: kind,
              body: body,
              prompt: Value(prompt),
            ),
          ),
      onError: (error, stackTrace) => StorageFailure(
        'Could not save entry',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> delete(int id) {
    return Result.guard(
      () async {
        await (_db.delete(
          _db.journalEntries,
        )..where((t) => t.id.equals(id))).go();
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not delete entry',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
