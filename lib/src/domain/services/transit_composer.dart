import 'package:sanctum/src/domain/models/planet.dart';
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
  /// Composes today's reading for someone born on [birthDate].
  static DailyTransitReading compose({
    required DateTime birthDate,
    required DateTime day,
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
      line: today == null ? quietDay : _lineFor(today),
      tomorrow: _tomorrowFor(today, next),
      retrogrades: retrogrades,
      retrogradeNote: retrogrades.isEmpty
          ? null
          : retrogradeNotes[retrogrades.first],
    );
  }

  static String _lineFor(Transit transit) {
    final body = pairs[transit.transiting]?[transit.natal];
    if (body == null) return quietDay;

    final opener = openers[transit.aspect]!;
    final rerun = transit.retrograde ? ' $retrogradeRerun' : '';
    return '$opener $body$rerun';
  }

  /// The tease, when tomorrow brings something different.
  ///
  /// Deliberately says what, not what it means. A promise with the
  /// payoff already spent is not a reason to come back.
  static String? _tomorrowFor(Transit? today, Transit? next) {
    if (next == null) return null;
    if (today != null &&
        today.transiting == next.transiting &&
        today.natal == next.natal &&
        today.aspect == next.aspect) {
      return null;
    }
    return '${next.headline}.';
  }

  /// Sets the tone, from the angle.
  static const openers = <TransitAspect, String>{
    TransitAspect.conjunction:
        'These two are sitting on top of each other today.',
    TransitAspect.sextile: 'There is a quiet opening here.',
    TransitAspect.square: 'Today has an edge to it.',
    TransitAspect.trine: 'This one is easy, if you let it be.',
    TransitAspect.opposition: 'You are being pulled two ways at once.',
  };

  /// Added when the transiting body is retrograde.
  static const retrogradeRerun =
      'And it is retrograde, so this is a rerun — you have met this '
      'one before.';

  /// Shown when nothing is in orb.
  ///
  /// Quiet days are real and saying so is better than inventing weather.
  /// The app has already spent its credibility if it claims every
  /// Tuesday is significant.
  static const quietDay =
      'The sky is not doing anything to you today. Those days exist, '
      'and they are the ones things actually get finished on.';

  /// What each transiting body does to each natal point.
  ///
  /// Twenty lines. A body aspecting its own natal position is skipped by
  /// the calculator — the Sun meeting your Sun is a birthday, and the
  /// slow ones are the background of a life rather than news about a
  /// Tuesday.
  static const pairs = <Planet, Map<Planet, String>>{
    Planet.sun: {
      Planet.venus:
          'The light is on what you want. Whatever you have been '
          'calling a preference is going to look a lot more like a need '
          'by this evening.',
      Planet.mars:
          'Your temper is nearer the surface than usual, and so is your '
          'nerve. Spend the second one before the first one spends you.',
      Planet.saturn:
          'Today asks whether you meant it — not dramatically, just in '
          'the small moment where you decide whether to do the thing '
          'you said you would.',
    },
    Planet.mercury: {
      Planet.sun:
          'You will explain yourself today, probably more than once. '
          'The version you arrive at on the third attempt is the true '
          'one.',
      Planet.venus:
          'Say the nice thing out loud. You have been assuming it was '
          'obvious, and it is not obvious.',
      Planet.mars:
          'You will win the argument. Consider, briefly, whether you '
          'want to.',
      Planet.saturn:
          'The thought you keep circling will not resolve by being '
          'thought about again. Write it down, or say it to somebody.',
    },
    Planet.venus: {
      Planet.sun:
          'You are easier to be around today, and you will notice '
          'people responding to it before you notice why.',
      Planet.mars:
          'Wanting something and going after it line up today. That is '
          'rarer than it sounds, and it does not last.',
      Planet.saturn:
          'Affection today arrives with a condition attached. It is '
          'yours, not theirs, and it is worth knowing which one.',
    },
    Planet.mars: {
      Planet.sun:
          'Something will need doing and you are the one who does it. '
          'Move early — the day gets less patient as it goes on.',
      Planet.venus:
          'You will want something and you will not be patient about '
          'it. That is not a flaw today, but it is a fact.',
      Planet.saturn:
          'Pushing on the locked door is the temptation today. The door '
          'is not the problem; the wall beside it is thinner than it '
          'looks.',
    },
    Planet.jupiter: {
      Planet.sun:
          'The room is wider today. Ask for the thing you decided last '
          'month was too much to ask for.',
      Planet.venus:
          'Generosity comes easily today, including toward yourself. '
          'Enjoy it. Do not sign anything.',
      Planet.mars:
          'Your appetite outruns your judgement today and mostly gets '
          'away with it. Mostly.',
      Planet.saturn:
          'The slow thing you have been building gets a little more '
          'room. Not a breakthrough — a door left open.',
    },
    Planet.saturn: {
      Planet.sun:
          'This is one of the seasons that makes you. It will not feel '
          'like that while it is happening. It never does.',
      Planet.venus:
          'Something you love is being asked to be real rather than '
          'lovely. That is not the same as it going wrong.',
      Planet.mars:
          'Your drive meets a wall this week, and the wall wins on '
          'points. Whatever survives that is the part worth keeping.',
    },
  };

  /// One line per retrograde body.
  static const retrogradeNotes = <Planet, String>{
    Planet.mercury:
        'Mercury is retrograde. Everything you send gets read twice — '
        'once by them, and once by you at two in the morning.',
    Planet.venus:
        'Venus is retrograde. Old names resurface. Answering is '
        'optional.',
    Planet.mars:
        'Mars is retrograde. Effort travels sideways rather than '
        'forward for a while. Push anyway if you must, but expect the '
        'angle.',
    Planet.jupiter:
        'Jupiter is retrograde. The growth is inward this time, which '
        'is less fun and considerably more useful.',
    Planet.saturn:
        'Saturn is retrograde. The thing you thought you had settled is '
        'asking to be settled properly.',
  };
}
