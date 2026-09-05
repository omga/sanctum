import 'package:drift/drift.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/domain/models/conversation.dart';

/// Reads and writes conversations and their messages.
abstract interface class ConversationRepository {
  /// The conversation for [subject], or null if it has not been opened.
  Future<Result<Conversation?>> find(ConversationSubject subject);

  /// Creates [conversation] if it is not already stored.
  Future<Result<void>> open(Conversation conversation);

  /// Every conversation, newest first.
  Future<Result<List<Conversation>>> all();

  /// The transcript for [conversationId], oldest first.
  Future<Result<List<ChatMessage>>> messages(String conversationId);

  /// Appends [message], replacing any row with the same id.
  Future<Result<void>> save(ChatMessage message);

  /// Records that a turn was spent.
  Future<Result<void>> setTurnsUsed(String conversationId, int turnsUsed);

  /// Deletes a conversation and everything in it.
  Future<Result<void>> delete(String conversationId);
}

/// Drift-backed [ConversationRepository].
///
/// ## Why the transcript is stored and the streamed message is not
///
/// A message is written when it is *finished* — the user's question as
/// it is sent, the answer once it has completed. Nothing is written per
/// chunk. Storing every delta would mean a write per token, and would
/// leave a half-sentence in the database if the process died mid-answer,
/// which is a worse artefact than the missing answer it replaces.
///
/// ## Why the subject is reconstructed rather than parsed
///
/// The row stores a kind and a reference. Rebuilding the sealed
/// [ConversationSubject] from those two is a `switch` the compiler
/// checks, so adding a subject type is a compile error here rather than
/// a silent `null` at runtime.
class DriftConversationRepository implements ConversationRepository {
  /// Creates a repository over [SanctumDatabase].
  const DriftConversationRepository(this._db);

  final SanctumDatabase _db;

  @override
  Future<Result<Conversation?>> find(ConversationSubject subject) {
    return Result.guard(
      () async {
        final query = _db.select(_db.conversations)
          ..where((t) => t.subjectKind.equals(_kindOf(subject)))
          ..where((t) => t.subjectRef.equals(_refOf(subject)));
        final row = await query.getSingleOrNull();
        return row == null ? null : _toConversation(row);
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read the conversation',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> open(Conversation conversation) {
    return Result.guard(
      () async {
        await _db
            .into(_db.conversations)
            .insert(
              ConversationsCompanion.insert(
                id: conversation.id,
                kind: conversation.kind,
                subjectKind: _kindOf(conversation.subject),
                subjectRef: Value(_refOf(conversation.subject)),
                startedAt: conversation.startedAt,
                turnsUsed: Value(conversation.turnsUsed),
              ),
              // Reopening an existing conversation must not reset the
              // turns somebody has already spent, so an insert that
              // collides is a no-op rather than a replace.
              mode: InsertMode.insertOrIgnore,
            );
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not open the conversation',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<List<Conversation>>> all() {
    return Result.guard(
      () async {
        final query = _db.select(_db.conversations)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
        final rows = await query.get();
        return [for (final row in rows) _toConversation(row)];
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read conversations',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<List<ChatMessage>>> messages(String conversationId) {
    return Result.guard(
      () async {
        final query = _db.select(_db.chatMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.at)]);
        final rows = await query.get();
        return [
          for (final row in rows)
            ChatMessage(
              id: row.id,
              conversationId: row.conversationId,
              author: row.author,
              body: row.body,
              at: row.at,
              status: row.status,
            ),
        ];
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read the transcript',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> save(ChatMessage message) {
    return Result.guard(
      () async {
        await _db
            .into(_db.chatMessages)
            .insertOnConflictUpdate(
              ChatMessagesCompanion.insert(
                id: message.id,
                conversationId: message.conversationId,
                author: message.author,
                body: message.body,
                at: message.at,
                status: message.status,
              ),
            );
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save the message',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> setTurnsUsed(String conversationId, int turnsUsed) {
    return Result.guard(
      () async {
        await (_db.update(_db.conversations)
              ..where((t) => t.id.equals(conversationId)))
            .write(ConversationsCompanion(turnsUsed: Value(turnsUsed)));
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not record the turn',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> delete(String conversationId) {
    return Result.guard(
      () async {
        // The messages go with it, by foreign key rather than by a
        // second statement somebody has to remember.
        await (_db.delete(_db.conversations)
              ..where((t) => t.id.equals(conversationId)))
            .go();
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not delete the conversation',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  Conversation _toConversation(ConversationRow row) => Conversation(
    id: row.id,
    kind: row.kind,
    subject: _toSubject(row.subjectKind, row.subjectRef),
    startedAt: row.startedAt,
    turnsUsed: row.turnsUsed,
  );

  static String _kindOf(ConversationSubject subject) => switch (subject) {
    MatchSubject() => 'match',
    ReportSubject() => 'report',
    DaySubject() => 'day',
    OpenSubject() => 'open',
  };

  static String _refOf(ConversationSubject subject) => switch (subject) {
    MatchSubject(:final matchId) => matchId,
    ReportSubject(:final matchId) => matchId,
    DaySubject(:final date) => '${date.year}-${date.month}-${date.day}',
    OpenSubject() => '',
  };

  static ConversationSubject _toSubject(String kind, String ref) =>
      switch (kind) {
        'match' => MatchSubject(ref),
        'report' => ReportSubject(ref),
        'day' => DaySubject(_parseDate(ref)),
        // Anything unrecognised is a row written by a newer build than
        // this one. Falling back beats throwing on somebody's history.
        _ => const OpenSubject(),
      };

  static DateTime _parseDate(String ref) {
    final parts = ref.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((part) => part == null)) {
      return DateTime(1970);
    }
    return DateTime(parts[0]!, parts[1]!, parts[2]!);
  }
}
