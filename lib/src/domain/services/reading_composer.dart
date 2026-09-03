import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/reading.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';

/// Turns quiz answers into the reading shown at the end of onboarding.
///
/// ## Why this is templated rather than generated
///
/// Every line here is selected by something the user actually told us —
/// their sign from their birth date, their heaviest weight from their own
/// tap. Nothing is invented and nothing is random, so the same answers
/// always produce the same reading, and every sentence can be traced to
/// an input.
///
/// That matters more than it sounds. The payoff screen is where someone
/// decides whether this app is worth paying for. Generic mysticism reads
/// as generic mysticism; a sentence that names the thing they just
/// admitted reads as being seen. The difference is not sophistication,
/// it is whether the copy is actually keyed to the answer.
///
/// The lines themselves live in `assets/content/<language>/copy.json`
/// under `reading.*`, reached through [CopyBook] — see there for why the
/// prose is data rather than constants.
abstract final class ReadingComposer {

  /// Builds the reading for [answers].
  static Reading compose(QuizAnswers answers, CopyBook copy) {
    final birth = answers.dates['birth_date'];
    final sign = birth == null ? ZodiacSign.aries : Zodiac.signFor(birth);

    final weights = answers.optionsFor('weight');
    final goals = answers.optionsFor('goals');
    final commitment = answers.optionsFor('commitment').firstOrNull;

    return Reading(
      name: answers.name,
      sign: sign,
      hasBirthDate: birth != null,
      opening: copy.get('reading.opening.${sign.element.name}'),
      // The first admitted weight leads. Stacking all of them turns a
      // reading into a list of grievances.
      recognition: _first(copy, 'reading.recognition', weights),
      intention: _first(copy, 'reading.intention', goals),
      closing: commitment == null
          ? null
          : copy.maybe('reading.commitment.$commitment'),
    );
  }

  /// The first of [ids] that has a line under [group].
  ///
  /// `maybe` rather than `get`: not every option id has copy written for
  /// it, and an unwritten one should fall through to the next answer
  /// rather than fail the whole reading.
  static String? _first(CopyBook copy, String group, List<String> ids) {
    for (final id in ids) {
      final line = copy.maybe('$group.$id');
      if (line != null) return line;
    }
    return null;
  }
}
