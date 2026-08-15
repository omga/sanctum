import 'package:dart_mappable/dart_mappable.dart';

part 'journal_entry.mapper.dart';

/// What kind of writing an entry is.
@MappableEnum()
enum JournalKind {
  /// Naming what is already good.
  gratitude('Gratitude'),

  /// Writing a desired future in the present tense.
  manifestation('Manifestation'),

  /// Open reflection.
  reflection('Reflection'),

  /// Written as part of a moon ritual.
  ritual('Ritual');

  const JournalKind(this.displayName);

  /// Human-readable name.
  final String displayName;
}

/// One piece of writing.
@MappableClass()
class JournalEntry with JournalEntryMappable {
  /// Creates a journal entry.
  const JournalEntry({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.body,
    this.prompt,
  });

  /// Local database id.
  final int id;

  /// When it was written.
  final DateTime createdAt;

  /// The kind of writing.
  final JournalKind kind;

  /// The user's words.
  final String body;

  /// The prompt shown, if this entry answered one.
  final String? prompt;

  /// A short preview for list rows.
  String get preview {
    final flattened = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flattened.length <= 80
        ? flattened
        : '${flattened.substring(0, 79)}…';
  }
}
