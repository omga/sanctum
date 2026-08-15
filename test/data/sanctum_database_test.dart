import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';

void main() {
  late SanctumDatabase db;

  setUp(() => db = SanctumDatabase.memory());
  tearDown(() async => db.close());

  group('SanctumDatabase', () {
    test('opens and reports its schema version', () async {
      // Also proves package:sqlite3 3.x loads its native library through
      // Dart build hooks, with no sqlite3_flutter_libs present.
      expect(db.schemaVersion, 1);
      await db.customSelect('SELECT 1').get();
    });

    test('round-trips a journal entry', () async {
      await db
          .into(db.journalEntries)
          .insert(
            JournalEntriesCompanion.insert(
              createdAt: DateTime(2026, 8, 15, 9),
              kind: JournalKind.gratitude,
              body: 'The light through the kitchen window.',
              prompt: const Value('What felt good today?'),
            ),
          );

      final rows = await db.select(db.journalEntries).get();

      expect(rows, hasLength(1));
      expect(rows.single.kind, JournalKind.gratitude);
      expect(rows.single.prompt, 'What felt good today?');
    });

    test('stores the enum by name, not by index', () async {
      await db
          .into(db.journalEntries)
          .insert(
            JournalEntriesCompanion.insert(
              createdAt: DateTime(2026, 8, 15),
              kind: JournalKind.manifestation,
              body: 'x',
            ),
          );

      final raw = await db
          .customSelect('SELECT kind FROM journal_entries')
          .getSingle();

      // If this ever reads '1' instead of 'manifestation', reordering the
      // enum would silently rewrite every historical entry.
      expect(raw.data['kind'], 'manifestation');
    });

    test('oracle draws default to unrevealed', () async {
      await db
          .into(db.oracleDraws)
          .insert(
            OracleDrawsCompanion.insert(
              cardId: 'the-threshold',
              drawnOn: DateTime(2026, 8, 15),
            ),
          );

      final draw = await db.select(db.oracleDraws).getSingle();
      expect(draw.revealed, isFalse);
    });

    test('practice log accepts multiple sessions per day', () async {
      for (var i = 0; i < 3; i++) {
        await db
            .into(db.practiceLog)
            .insert(
              PracticeLogCompanion.insert(
                sessionId: 'session-$i',
                completedAt: DateTime(2026, 8, 15, 8 + i),
                durationSeconds: 600,
              ),
            );
      }

      expect(await db.select(db.practiceLog).get(), hasLength(3));
    });
  });
}
