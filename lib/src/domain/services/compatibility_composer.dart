import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
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
///
/// ## Where the words live
///
/// In `assets/content/<language>/copy.json`, reached through [CopyBook],
/// not in this file. The selection logic above is the same in every
/// language; the prose is not, and `domain/` cannot import the generated
/// localisations. Keys are built from the enums that choose them —
/// `compatibility.dynamic.trine` — so adding an aspect or a facet breaks
/// at the missing key rather than silently composing a blank line.
abstract final class CompatibilityComposer {
  /// Composes the reading for [you] and [them], in the language of
  /// [copy].
  ///
  /// Still a pure function of its arguments — the same two dates and the
  /// same copy book always compose the same reading. The prose simply
  /// arrives as data now instead of being compiled in.
  static CompatibilityMatch compose({
    required MatchPerson you,
    required MatchPerson them,
    required DateTime now,
    required CopyBook copy,
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
      copy,
    );
    final power = _direction(
      DirectionKind.power,
      CompatibilityCalculator.powerShare(you, them),
      copy,
    );

    return CompatibilityMatch(
      you: you,
      them: them,
      aspect: aspect,
      overall: overall,
      facets: facets,
      verdict: CompatibilityCalculator.verdictFor(overall),
      dynamicLine: copy.get('compatibility.dynamic.${aspect.name}'),
      elementLine: copy.get(
        'compatibility.element.${elementKey(you.sign, them.sign)}',
      ),
      worksLine: copy.get('compatibility.works.${strongest.facet.name}'),
      watchLine: copy.get('compatibility.watch.${weakest.facet.name}'),
      shareLine: _shareLine(facets, pull, aspect, copy),
      pull: pull,
      power: power,
      createdAt: now,
    );
  }

  static DirectionalReading _direction(
    DirectionKind kind,
    int yourShare,
    CopyBook copy,
  ) {
    final offset = yourShare - 50;
    final lean = offset.abs() <= DirectionalReading.evenTolerance
        ? _Lean.even
        : (offset > 0 ? _Lean.you : _Lean.them);

    final group = kind == DirectionKind.pull ? 'pull' : 'power';
    return DirectionalReading(
      kind: kind,
      yourShare: yourShare,
      line: copy.get('compatibility.$group.${lean.name}'),
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
    CopyBook copy,
  ) {
    if ((pull.yourShare - 50).abs() >= DirectionalReading.strongTolerance) {
      return copy.get('compatibility.lopsided');
    }

    final strongest = facets.reduce((a, b) => b.score > a.score ? b : a);
    if (strongest.score >= 82) {
      return copy.get('compatibility.punchline.${strongest.facet.name}');
    }

    return copy.get('compatibility.share.${aspect.name}');
  }

  /// Canonical unordered key for two elements, e.g. `fire+water`.
  static String elementKey(ZodiacSign a, ZodiacSign b) {
    final pair = [a.element, b.element]
      ..sort((x, y) => x.index.compareTo(y.index));
    return '${pair.first.name}+${pair.last.name}';
  }
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
