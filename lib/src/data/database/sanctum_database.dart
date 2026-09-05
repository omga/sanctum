import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sanctum/src/data/database/tables.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
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
  tables: [
    PracticeLog,
    JournalEntries,
    EnergyCheckIns,
    OracleDraws,
    Conversations,
    ChatMessages,
  ],
)
class SanctumDatabase extends _$SanctumDatabase {
  /// Opens the real on-disk database.
  SanctumDatabase() : super(_openConnection());

  /// Opens an in-memory database, for tests.
  ///
  /// Same schema, same queries, no file — so repository tests run in
  /// milliseconds and cannot leak state between cases.
  SanctumDatabase.memory() : super(NativeDatabase.memory());

  /// Opens over an executor the caller owns.
  ///
  /// Exists for the migration test, which has to build a *version 1*
  /// database by hand and then let this class upgrade it. Nothing in the
  /// app uses it: the two constructors above are the real entry points.
  SanctumDatabase.on(super.e);

  /// Bumped to 2 for the advisor's conversations and messages.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // The first real migration this database has had. Additive only:
    // two new tables, nothing touched that already holds a user's
    // journal, and therefore nothing that can lose one.
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(conversations);
        await m.createTable(chatMessages);
      }
    },
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
