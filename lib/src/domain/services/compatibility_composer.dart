import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/compatibility_calculator.dart';

/// Turns two birth dates into the reading the user actually reads.
///
/// ## Why two copy axes and not one
///
/// Keying every line to the aspect alone would be tidy and would also
/// mean every Aries-and-Leo reading is word-for-word identical to every
/// Taurus-and-Virgo one. Users compare results with their friends —
/// that is the entire distribution plan — so identical copy across
/// different pairings is not a cosmetic problem, it is the product
/// being caught lying about how much it knows.
///
/// So the dynamic comes from the aspect, the texture comes from the two
/// elements, and the last two lines come from which facet actually
/// scored highest and lowest for *this* pair. Four lines, three
/// independent inputs, no randomness: the same two dates always compose
/// the same reading, and every sentence is traceable to a number.
abstract final class CompatibilityComposer {
  /// Composes the reading for [you] and [them].
  static CompatibilityMatch compose({
    required MatchPerson you,
    required MatchPerson them,
    required DateTime now,
  }) {
    final aspect = CompatibilityCalculator.aspectBetween(
      you.sign,
      them.sign,
    );
    final overall = CompatibilityCalculator.overall(you, them);
    final facets = CompatibilityCalculator.facets(you, them);

    final strongest = facets.reduce((a, b) => b.score > a.score ? b : a);
    final weakest = facets.reduce((a, b) => b.score < a.score ? b : a);

    final pull = _direction(
      DirectionKind.pull,
      CompatibilityCalculator.pullShare(you, them),
    );
    final power = _direction(
      DirectionKind.power,
      CompatibilityCalculator.powerShare(you, them),
    );

    return CompatibilityMatch(
      you: you,
      them: them,
      aspect: aspect,
      overall: overall,
      facets: facets,
      verdict: CompatibilityCalculator.verdictFor(overall),
      dynamicLine: dynamics[aspect]!,
      elementLine: elements[elementKey(you.sign, them.sign)]!,
      worksLine: works[strongest.facet]!,
      watchLine: watches[weakest.facet]!,
      shareLine: _shareLine(facets, pull, aspect),
      pull: pull,
      power: power,
      createdAt: now,
    );
  }

  static DirectionalReading _direction(DirectionKind kind, int yourShare) {
    final offset = yourShare - 50;
    final lean = offset.abs() <= DirectionalReading.evenTolerance
        ? _Lean.even
        : (offset > 0 ? _Lean.you : _Lean.them);

    return DirectionalReading(
      kind: kind,
      yourShare: yourShare,
      line: (kind == DirectionKind.pull ? pullLines : powerLines)[lean]!,
    );
  }

  /// The line that goes on the card people post.
  ///
  /// ## Why this is chosen rather than fixed
  ///
  /// The card is the artifact that travels, so its line has to be the
  /// most *specific* thing true about this pairing, not a generic label
  /// for the aspect. A lopsided pull beats everything, because "one of
  /// you has already told their friends" is the sentence someone sends
  /// to a group chat. Then a standout facet. The aspect line is only the
  /// fallback for a pairing with nothing extreme in it.
  ///
  /// The humour is meant to come from being uncomfortably accurate
  /// rather than from jokes. A joke voice would be cheaper than the rest
  /// of the app and would undercut the thing people are being asked to
  /// subscribe to.
  static String _shareLine(
    List<FacetScore> facets,
    DirectionalReading pull,
    ZodiacAspect aspect,
  ) {
    if ((pull.yourShare - 50).abs() >= 18) return lopsidedShareLine;

    final strongest = facets.reduce((a, b) => b.score > a.score ? b : a);
    if (strongest.score >= 82) return punchlines[strongest.facet]!;

    return shareLines[aspect]!;
  }

  /// Canonical unordered key for two elements, e.g. `fire+water`.
  static String elementKey(ZodiacSign a, ZodiacSign b) {
    final pair = [a.element, b.element]
      ..sort((x, y) => x.index.compareTo(y.index));
    return '${pair.first.name}+${pair.last.name}';
  }

  /// The core dynamic, from the angle between the signs.
  static const dynamics = <ZodiacAspect, String>{
    ZodiacAspect.conjunction:
        'You are the same sign. You recognise each other on sight and '
        'you share exactly the same blind spot, which means nobody in '
        'this pairing is going to be the adult about it.',
    ZodiacAspect.semiSextile:
        'You sit next to each other on the wheel and have almost '
        'nothing in common. That is survivable. It just has to be '
        'chosen on purpose, over and over, rather than assumed.',
    ZodiacAspect.sextile:
        'This one is easy, and you may not trust it for exactly that '
        'reason. Somewhere along the way you were taught that real '
        'meant difficult. It does not.',
    ZodiacAspect.square:
        'There is friction here, and the friction is the attraction. '
        'You will not be bored. You will also have the same argument '
        'more than once before either of you admits it is the same one.',
    ZodiacAspect.trine:
        'You run on the same operating system. Things other people have '
        'to negotiate, the two of you will simply never need to discuss '
        '— which is its own risk, because unexamined is not the same '
        'as agreed.',
    ZodiacAspect.quincunx:
        'Neither of you is wrong. You are running different software. '
        'Nearly all the damage in this pairing comes from deciding the '
        'other one is being difficult on purpose.',
    ZodiacAspect.opposition:
        'You are the two ends of one axis. Everything you are missing, '
        'they are carrying — which is magnetic right up until it is the '
        'thing you fight about.',
  };

  /// The texture, from the two elements.
  static const elements = <String, String>{
    'fire+fire':
        'Two fires. Bright, fast, and nobody in the house remembers to '
        'eat.',
    'fire+earth':
        'One of you moves and one of you builds. It works right up until '
        'the builder gets treated as the brake.',
    'fire+air':
        'Air feeds fire. This is the pairing that starts things. The '
        'open question is which of you finishes them.',
    'fire+water':
        'Fire and water. One of you burns it off, the other holds it. '
        'Neither of those is the wrong way to survive something.',
    'earth+earth':
        'Two earth signs. Unshowy, unhurried, and far harder to break '
        'than it looks from outside.',
    'earth+air':
        'One of you wants it decided and the other wants it discussed. '
        'That gap is not a phase. It is the relationship.',
    'earth+water':
        'Water needs a bank to run along, and it has found one. This is '
        'the quietly durable pairing nobody makes films about.',
    'air+air':
        'Two air signs. Endless conversation, and a shared talent for '
        'never quite having the difficult one.',
    'air+water':
        'You explain feelings and they feel them. Translation is the '
        'work here, and it has to go both ways or it becomes a job.',
    'water+water':
        'Two water signs. You will always know what the other is '
        'feeling, including the parts you would both rather skip.',
  };

  /// What is working, from the strongest facet.
  static const works = <CompatibilityFacet, String>{
    CompatibilityFacet.spark:
        'The chemistry is not in question. Whatever else the two of you '
        'have to work out, you will never have to manufacture wanting '
        'each other.',
    CompatibilityFacet.vibe:
        'The ordinary days are good. Almost everybody underrates that '
        'until they have had the alternative.',
    CompatibilityFacet.trust:
        'Neither of you has to perform safety here. It is simply '
        'present, and it is the rarest thing on this page.',
    CompatibilityFacet.drama:
        'Nothing about this is boring. You will remember it whichever '
        'way it goes, which is more than most people get.',
    CompatibilityFacet.depth:
        'This goes deep fast. Neither of you will be able to explain it '
        'accurately to a friend, and you will both try.',
    CompatibilityFacet.future:
        'This one survives being ordinary — the only test that actually '
        'matters, and the one most pairings quietly fail.',
  };

  /// What to watch, from the weakest facet.
  static const watches = <CompatibilityFacet, String>{
    CompatibilityFacet.spark:
        'The heat has to be fed on purpose. Comfortable is not the same '
        'as over, but left alone long enough the two look identical.',
    CompatibilityFacet.vibe:
        'You are at your best when something is happening. Empty '
        'afternoons are where this one actually gets tested.',
    CompatibilityFacet.trust:
        'Reassurance has to be said out loud, and then said again, past '
        'the point either of you thinks it should still be necessary.',
    CompatibilityFacet.drama:
        'Nothing here will force anything into the open. This can drift '
        'for a year before either of you admits that it has.',
    CompatibilityFacet.depth:
        'This stays light. That is fine, as long as light is what you '
        'both actually came for.',
    CompatibilityFacet.future:
        'This runs hot and can burn down to nothing. The work is having '
        'a version of it that holds on an ordinary Tuesday.',
  };

  /// Blunt one-liners for the card, by standout facet.
  static const punchlines = <CompatibilityFacet, String>{
    CompatibilityFacet.spark: 'The chemistry was never the problem.',
    CompatibilityFacet.vibe: 'Suspiciously easy.',
    CompatibilityFacet.trust: 'Nobody here is performing.',
    CompatibilityFacet.drama: 'You will have this argument again.',
    CompatibilityFacet.depth: 'Neither of you walks away clean.',
    CompatibilityFacet.future: 'This one gets old together.',
  };

  /// The card line when one of you is much further in than the other.
  ///
  /// Deliberately does not say which. Ambiguity is what makes it safe to
  /// post and interesting to argue about.
  static const lopsidedShareLine =
      'One of you has already told their friends.';

  /// Who wants it more.
  static const pullLines = <_Lean, String>{
    _Lean.you:
        'You want this more than they do. That is not a flaw, but it is '
        'a fact, and pretending otherwise is where the trouble starts.',
    _Lean.them:
        'They are further into this than you are, and both of you can '
        'feel it even if neither has said so.',
    _Lean.even:
        'You want this about equally — which is genuinely the rarest '
        'result on this page.',
  };

  /// Who sets the terms.
  static const powerLines = <_Lean, String>{
    _Lean.you:
        'You set the terms here. They agreed to them a while ago, '
        'probably without either of you discussing it.',
    _Lean.them:
        'They set the terms. You will lose most of the arguments, and '
        'you will not always notice that you have.',
    _Lean.even:
        'Neither of you is running this, which sounds unremarkable and '
        'is the reason it might last.',
  };

  /// The short line on the shareable card. Written to be screenshotted.
  static const shareLines = <ZodiacAspect, String>{
    ZodiacAspect.conjunction: 'Same sign. Same blind spot.',
    ZodiacAspect.semiSextile: 'Nothing in common. Chosen anyway.',
    ZodiacAspect.sextile: 'Easy — and neither of us trusts easy.',
    ZodiacAspect.square: 'The friction is the attraction.',
    ZodiacAspect.trine: 'Same operating system.',
    ZodiacAspect.quincunx: 'Different software. Same destination.',
    ZodiacAspect.opposition: 'Opposite ends of one axis.',
  };
}

/// Which side a lopsided reading falls on.
enum _Lean {
  /// The user.
  you,

  /// The other person.
  them,

  /// Close enough to even.
  even,
}
