import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sanctum/src/data/database/tables.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';

part 'sanctum_database.g.dart';

/// Sanctum's on-device database.
///
/// ## Opening it
///
/// Note what is *absent*: `sqlite3_flutter_libs`. As of `package:sqlite3`
/// 3.0 that package is end-of-life — sqlite3 now ships SQLite itself via
/// Dart build hooks, and its changelog explicitly says to drop the
/// dependency. Most Drift tutorials still tell you to add it, and
/// `drift_flutter` 0.3.1 still pulls it in transitively, which is why
/// this file wires the connection by hand instead.
@DriftDatabase(
  tables: [PracticeLog, JournalEntries, EnergyCheckIns, OracleDraws],
)
class SanctumDatabase extends _$SanctumDatabase {
  /// Opens the real on-disk database.
  SanctumDatabase() : super(_openConnection());

  /// Opens an in-memory database, for tests.
  ///
  /// Same schema, same queries, no file — so repository tests run in
  /// milliseconds and cannot leak state between cases.
  SanctumDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Off by default in SQLite, and Sanctum relies on it for
      // cascading deletes.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'sanctum.sqlite'));
    // createInBackground moves SQLite onto its own isolate, so a slow
    // query cannot jank the aurora.
    return NativeDatabase.createInBackground(file);
  });
}
