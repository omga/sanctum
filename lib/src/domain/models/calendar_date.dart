import 'package:dart_mappable/dart_mappable.dart';

/// Serialises a birth date as the calendar date it actually is.
///
/// ## The bug this exists to fix
///
/// `dart_mappable` encodes every `DateTime` by converting it to UTC.
/// That is the right behaviour for an *instant* — `JournalEntry.createdAt`
/// and `CompatibilityMatch.createdAt` genuinely are instants and should
/// normalise — and it is wrong for a birth date, which is a calendar
/// date with no time and no zone.
///
/// The app builds birth dates as `DateTime(y, m, d)`, which is local
/// midnight. East of UTC that encodes to the *previous* day:
///
/// ```text
/// saved     1996-06-15 00:00 local  (UTC+3)
/// stored    "1996-06-14T21:00:00.000Z"
/// restored  1996-06-14
/// ```
///
/// So every birth date in this app moved back a day the first time it
/// was read from storage, for every user east of Greenwich — which
/// includes all of Europe. A cusp birthday therefore reported the wrong
/// sun sign from the second launch onwards, `MatchPerson.key` no longer
/// matched the id a saved reading had been stored under, and with birth
/// times now in play the Moon was computed from the wrong day entirely.
///
/// ## How it is fixed, and why old blobs still work
///
/// Encoding writes **UTC midnight** of the local calendar date, so the
/// stored string names the right day and does not depend on where the
/// phone was when it was written. Decoding then reads the UTC fields
/// straight back.
///
/// A blob written before this hook existed does not have midnight in it
/// — it has whatever the zone offset made of it — and that is exactly
/// what tells the two formats apart. Those are converted back to local
/// first, which recovers the original date on the device that wrote it.
/// After one save the value is in the new format and the ambiguity is
/// gone for good.
class CalendarDateHook extends MappingHook {
  /// Creates the hook.
  const CalendarDateHook();

  @override
  Object? beforeEncode(Object? value) => _map(value, _toUtcMidnight);

  @override
  Object? afterDecode(Object? value) => _map(value, _toLocalDate);

  /// Applies [transform] to a `DateTime`, or to every value of a map of
  /// them — `QuizAnswers.dates` is keyed by question id.
  ///
  /// The map branch must rebuild a `Map<String, DateTime>` rather than a
  /// map literal: whatever a hook returns is cast straight back to the
  /// field's declared type, and a `Map<dynamic, dynamic>` fails that
  /// cast at runtime with the field's whole value lost.
  static Object? _map(Object? value, DateTime Function(DateTime) transform) {
    if (value is DateTime) return transform(value);
    if (value is Map) {
      return <String, DateTime>{
        for (final entry in value.entries)
          if (entry.value is DateTime)
            '${entry.key}': transform(entry.value as DateTime),
      };
    }
    return value;
  }

  static DateTime _toUtcMidnight(DateTime date) {
    final local = date.isUtc ? date.toLocal() : date;
    return DateTime.utc(local.year, local.month, local.day);
  }

  static DateTime _toLocalDate(DateTime date) {
    if (!date.isUtc) return DateTime(date.year, date.month, date.day);

    // Midnight UTC is this hook's own output, and is already the right
    // calendar date wherever the phone happens to be. Anything else was
    // written by the old behaviour, where the local date is recoverable
    // only by undoing the shift.
    final isMidnight =
        date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        date.millisecond == 0;
    if (isMidnight) return DateTime(date.year, date.month, date.day);

    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
