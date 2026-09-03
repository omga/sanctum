import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/transit.dart';
import 'package:sanctum/src/domain/services/transit_calculator.dart';

/// Turns a transit into something a person would actually read.
///
/// ## The rule the copy follows
///
/// Every line names a thing that could happen today and stops. No
/// advice that could be printed in any newspaper on any date, no "the
/// stars align for you", nothing that would still be true if the sky
/// were somewhere else. If a line would survive being moved to a
/// different transit, it is not written well enough.
abstract final class TransitComposer {
  /// Composes today's reading for someone born on [birthDate], in the
  /// language of [copy].
  static DailyTransitReading compose({
    required DateTime birthDate,
    required DateTime day,
    required CopyBook copy,
  }) {
    final today = TransitCalculator.headline(
      birthDate: birthDate,
      day: day,
    );
    final retrogrades = TransitCalculator.retrogrades(day);

    final next = TransitCalculator.headline(
      birthDate: birthDate,
      day: day.add(const Duration(days: 1)),
    );

    return DailyTransitReading(
      transit: today,
      line: today == null
          ? copy.get('transit.quietDay')
          : _lineFor(today, copy),
      headline: today == null
          ? copy.get('transit.quietSky')
          : today.headlineIn(copy),
      tomorrow: _tomorrowFor(today, next, copy),
      retrogrades: retrogrades,
      retrogradeNote: retrogrades.isEmpty
          ? null
          : copy.maybe('transit.retrograde.${retrogrades.first.name}'),
    );
  }

  static String _lineFor(Transit transit, CopyBook copy) {
    // A pair with no line written is a real case rather than a mistake —
    // the calculator can produce a contact the copy deck does not cover
    // — so this is `maybe` and falls back to the quiet day.
    final body = copy.maybe(
      'transit.pair.${transit.transiting.name}.${transit.natal.name}',
    );
    if (body == null) return copy.get('transit.quietDay');

    final opener = copy.get('transit.opener.${transit.aspect.name}');
    final rerun = transit.retrograde
        ? ' ${copy.get('transit.retrogradeRerun')}'
        : '';
    return '$opener $body$rerun';
  }

  /// The tease, when tomorrow brings something different.
  ///
  /// Deliberately says what, not what it means. A promise with the
  /// payoff already spent is not a reason to come back.
  static String? _tomorrowFor(Transit? today, Transit? next, CopyBook copy) {
    if (next == null) return null;
    if (today != null &&
        today.transiting == next.transiting &&
        today.natal == next.natal &&
        today.aspect == next.aspect) {
      return null;
    }
    return '${next.headlineIn(copy)}.';
  }
}
