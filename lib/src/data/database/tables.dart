/// Drift generates a row class per table, named by singularising the
/// table. Left alone, `JournalEntries` would generate `JournalEntry` and
/// `EnergyCheckIns` would generate `EnergyCheckIn` — colliding head-on
/// with the domain models of the same names.
///
/// Renaming them with a `Row` suffix does more than dodge the collision:
/// it makes it obvious at every call site whether a value is a database
/// row or a domain object. Rows must never escape the data layer; the
/// repositories map them across the boundary.
library;

import 'package:drift/drift.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';

/// Every completed practice, one row each.
///
/// Streaks are derived from this table rather than stored as a counter.
/// A stored counter is a second source of truth that drifts the first
/// time a write fails halfway; a log cannot disagree with itself.
@DataClassName('PracticeLogRow')
class PracticeLog extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// Catalogue id of the session practised.
  TextColumn get sessionId => text()();

  /// When the session finished.
  DateTimeColumn get completedAt => dateTime()();

  /// How long was actually listened to, which is not always the full
  /// session — useful later for judging whether content is too long.
  IntColumn get durationSeconds => integer()();
}

/// Journal writing.
@DataClassName('JournalEntryRow')
class JournalEntries extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// When it was written.
  DateTimeColumn get createdAt => dateTime()();

  /// The kind of writing, stored by enum *name* rather than index so
  /// that reordering the enum cannot silently rewrite history.
  TextColumn get kind => textEnum<JournalKind>()();

  /// The user's words.
  TextColumn get body => text()();

  /// The prompt shown, if any.
  TextColumn get prompt => text().nullable()();
}

/// Daily energy check-ins.
@DataClassName('EnergyCheckInRow')
class EnergyCheckIns extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// When it was recorded.
  DateTimeColumn get recordedAt => dateTime()();

  /// Ordinal 1–5. Stored as the number so it can be averaged and charted
  /// in SQL without a lookup.
  IntColumn get level => integer()();

  /// Optional free text.
  TextColumn get note => text().nullable()();
}

/// A record of each oracle card drawn.
@DataClassName('OracleDrawRow')
class OracleDraws extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// Catalogue id of the card.
  TextColumn get cardId => text()();

  /// The local date the card belongs to, time stripped.
  DateTimeColumn get drawnOn => dateTime()();

  /// Whether the user has flipped it yet. A card is *assigned* at
  /// midnight but only *revealed* when tapped, and the difference is the
  /// entire ceremony of the feature.
  BoolColumn get revealed => boolean().withDefault(const Constant(false))();
}

/// One advisor conversation.
///
/// ## Why the subject is two columns and not one key
///
/// `ConversationSubject.key` is what the gate and the store care about,
/// and it would be the obvious thing to write here. It is stored split —
/// a kind and a reference — because the *reference* for a pairing is
/// `CompatibilityMatch.id`, which is built from both people's names and
/// birth dates, and a single opaque key column makes that impossible to
/// find later. Split, it is one column to clear, one column to migrate,
/// and one column to look at when somebody asks what this table knows
/// about a person.
@DataClassName('ConversationRow')
class Conversations extends Table {
  /// Stable id, assigned by the domain rather than the database.
  ///
  /// Text rather than an autoincrementing integer because the id is
  /// derived from the subject — reopening the same pairing must find the
  /// same conversation rather than start a second one beside it.
  TextColumn get id => text()();

  /// Who is answering: an advisor, or eventually a person.
  TextColumn get kind => textEnum<ConversationKind>()();

  /// Which sort of subject this is about.
  TextColumn get subjectKind => text()();

  /// The subject's reference — a match id, or a date, or empty.
  TextColumn get subjectRef => text().withDefault(const Constant(''))();

  /// When it was opened.
  DateTimeColumn get startedAt => dateTime()();

  /// Exchanges spent. The number the user paid for.
  IntColumn get turnsUsed => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Every message in every conversation.
@DataClassName('ChatMessageRow')
class ChatMessages extends Table {
  /// Stable id, assigned by the domain.
  TextColumn get id => text()();

  /// The conversation this belongs to.
  ///
  /// `onDelete: cascade` so deleting a conversation takes its messages
  /// with it. That is enforced by SQLite rather than by remembering to
  /// write a second delete — and it only works because `beforeOpen`
  /// turns foreign keys on, which is off by default and the reason that
  /// pragma exists in `sanctum_database.dart`.
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: KeyAction.cascade)();

  /// Who wrote it.
  TextColumn get author => textEnum<MessageAuthor>()();

  /// The text, as the user sees it. Names included: this is the local
  /// transcript, and the redaction happens on the way *out* to a
  /// transport, not on the way into storage.
  TextColumn get body => text()();

  /// When it was written.
  DateTimeColumn get at => dateTime()();

  /// Sent, or failed. Nothing is stored mid-flight.
  TextColumn get status => textEnum<MessageStatus>()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
