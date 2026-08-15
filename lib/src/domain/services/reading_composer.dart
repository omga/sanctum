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
abstract final class ReadingComposer {
  /// Element-led opening. Sets the voice before it says anything specific.
  static const openings = <ZodiacElement, String>{
    ZodiacElement.fire:
        'You move first and understand it afterwards. It has cost you '
        'things, and it has also been the only reason anything '
        'started.',
    ZodiacElement.earth:
        'You need the ground to hold before you put weight on it. People '
        'read that as slowness. It is not slowness.',
    ZodiacElement.air:
        'You live half a step ahead of the room, already three moves into '
        'a conversation nobody has started yet.',
    ZodiacElement.water:
        'You feel the temperature of a room before anyone speaks. You have '
        'been told this is too much. It is not too much.',
  };

  /// Named back to them, from the heaviest thing they admitted.
  static const recognitions = <String, String>{
    'mixed_signals':
        'You are trying to read someone who is not being clear, and '
        'calling your confusion a failure of intuition. It is not. '
        'They are being unclear.',
    'repeating':
        'You can already describe the pattern. That is the part people '
        'miss — you are not stuck because you cannot see it. You are '
        'stuck because seeing it was supposed to be enough.',
    'letting_go':
        'You are still carrying something that finished a while ago. Not '
        'because you are weak about it, but because nobody ever told '
        'you when you were allowed to put it down.',
    'racing':
        'Your mind is moving faster than your day actually requires. The '
        'speed is not the problem. Having nowhere to put it is.',
    'stuck':
        'You are waiting to feel ready. Ready is something that arrives '
        'afterwards, which is an unfair way for it to work, and it is '
        'still how it works.',
    'drained':
        'You have been pouring out of a cup that nobody has refilled, and '
        'calling the emptiness a character flaw.',
  };

  /// What the app will do about it, from what they came for.
  static const intentions = <String, String>{
    'love':
        'Your readings will be written toward the people in your life — '
        'the ones you are trying to understand, and the one you are '
        'trying to become for them.',
    'clarity':
        'Your readings will keep returning you to the decision, until you '
        'stop circling it and make it.',
    'calm':
        'Your readings will be quiet on purpose. Less to think about, not '
        'more.',
    'purpose':
        'Your readings will stay on the long shape of it, not the noise '
        'of any particular week.',
    'self':
        'Your readings will tell you things about yourself that you '
        'already suspect and have not said out loud.',
    'people':
        'Your readings will be about the people around you, and what they '
        'are doing that you keep explaining away.',
  };

  /// The closing, from what they promised.
  static const commitments = <String, String>{
    'daily': 'Every morning. That was your word, not ours.',
    'most': 'Most days. Enough to build something.',
    'when': 'When you need it. It will be here either way.',
  };

  /// Builds the reading for [answers].
  static Reading compose(QuizAnswers answers) {
    final birth = answers.dates['birth_date'];
    final sign = birth == null ? ZodiacSign.aries : Zodiac.signFor(birth);

    final weights = answers.optionsFor('weight');
    final goals = answers.optionsFor('goals');
    final commitment = answers.optionsFor('commitment').firstOrNull;

    return Reading(
      name: answers.name,
      sign: sign,
      hasBirthDate: birth != null,
      opening: openings[sign.element]!,
      // The first admitted weight leads. Stacking all of them turns a
      // reading into a list of grievances.
      recognition: _first(recognitions, weights),
      intention: _first(intentions, goals),
      closing: commitment == null ? null : commitments[commitment],
    );
  }

  static String? _first(Map<String, String> copy, List<String> ids) {
    for (final id in ids) {
      final line = copy[id];
      if (line != null) return line;
    }
    return null;
  }
}
