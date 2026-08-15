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
