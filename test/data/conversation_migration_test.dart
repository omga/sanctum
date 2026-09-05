import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/data/repositories/conversation_repository.dart';
import 'package:sanctum/src/data/repositories/journal_repository.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';
import 'package:sqlite3/sqlite3.dart';

/// Schema 1, written out by hand.
///
/// A fixture rather than a generated snapshot: `drift_dev`'s schema
/// tooling would be the thorough answer, and it is worth adding the day
/// this database gets a migration that *changes* something. This one is
/// additive, so what has to be proved is narrow and provable here —
/// nothing that already exists is touched, and a journal written before
/// the upgrade is still readable after it.
const _schemaV1 = [
  '''
  CREATE TABLE practice_log (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    completed_at INTEGER NOT NULL,
    duration_seconds INTEGER NOT NULL
  );''',
  '''
  CREATE TABLE journal_entries (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    created_at INTEGER NOT NULL,
    kind TEXT NOT NULL,
    body TEXT NOT NULL,
    prompt TEXT NULL
  );''',
  '''
  CREATE TABLE energy_check_ins (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    recorded_at INTEGER NOT NULL,
    level INTEGER NOT NULL,
    note TEXT NULL
  );''',
  '''
  CREATE TABLE oracle_draws (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    card_id TEXT NOT NULL,
    drawn_on INTEGER NOT NULL,
    revealed INTEGER NOT NULL DEFAULT 0 CHECK (revealed IN (0, 1))
  );''',
];

void main() {
  late Database raw;
  late SanctumDatabase db;

  setUp(() {
    // A version 1 database, exactly as a user upgrading from the last
    // release has on their phone.
    raw = sqlite3.openInMemory();
    _schemaV1.forEach(raw.execute);
    raw.execute('PRAGMA user_version = 1');
  });

  tearDown(() async {
    await db.close();
  });

  /// Opens the current schema over the version 1 database, running the
  /// migration on the way.
  Future<void> upgrade() async {
    db = SanctumDatabase.on(NativeDatabase.opened(raw));
    // Drift migrates lazily, on the first query.
    await db.customSelect('SELECT 1').get();
  }

  test('a journal written before the upgrade is still there after it', () {
    // The only thing that actually matters. Everything else in this
    // file is a check that the upgrade ran at all.
    raw.execute(
      'INSERT INTO journal_entries (created_at, kind, body, prompt) '
      "VALUES (1756000000, 'reflection', 'Something I wrote', NULL)",
    );

    return upgrade().then((_) async {
      final entries = await DriftJournalRepository(db).watchEntries().first;
      expect(entries, hasLength(1));
      expect(entries.single.body, 'Something I wrote');
      expect(entries.single.kind, JournalKind.reflection);
    });
  });

  test('reports the new schema version afterwards', () async {
    await upgrade();
    expect(db.schemaVersion, 2);
    expect(raw.userVersion, 2);
  });

  test('the conversation tables exist and work', () async {
    await upgrade();
    final repository = DriftConversationRepository(db);

    await repository.open(
      Conversation(
        id: 'advisor:pair-1',
        kind: ConversationKind.advisor,
        subject: const MatchSubject('pair-1'),
        startedAt: DateTime(2026, 9, 5),
      ),
    );
    final found = await repository.find(const MatchSubject('pair-1'));
    expect(found.valueOrNull?.id, 'advisor:pair-1');
  });

  test('foreign keys are on, so a delete still cascades', () async {
    // The pragma is set in `beforeOpen`, which runs on a migrated
    // database as well as a fresh one — and the cascade is the only
    // thing stopping orphaned messages from outliving the conversation
    // they belong to.
    await upgrade();
    final repository = DriftConversationRepository(db);
    await repository.open(
      Conversation(
        id: 'c1',
        kind: ConversationKind.advisor,
        subject: const MatchSubject('pair-1'),
        startedAt: DateTime(2026, 9, 5),
      ),
    );
    await repository.save(
      ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        author: MessageAuthor.you,
        body: 'Why?',
        at: DateTime(2026, 9, 5),
      ),
    );

    await repository.delete('c1');
    expect(await db.select(db.chatMessages).get(), isEmpty);
  });

  test('every table from version 1 survives', () async {
    await upgrade();
    final names = raw
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row['name'] as String)
        .toSet();

    expect(
      names,
      containsAll([
        'practice_log',
        'journal_entries',
        'energy_check_ins',
        'oracle_draws',
        'conversations',
        'chat_messages',
      ]),
    );
  });
}
