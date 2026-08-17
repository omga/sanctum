import 'package:sanctum/src/domain/models/compatibility.dart';

/// The caption that travels with a shared carousel.
///
/// Pure, and in `domain/` rather than in the widget that posts it, for
/// the same reason every other line of user-facing copy lives here: it
/// is product rather than presentation, it needs tests, and the day this
/// app is localised a translator needs one file to open instead of a
/// widget tree to read.
///
/// ## Why the split leads and the score does not
///
/// The overall score is a fact about a couple, and nobody argues with a
/// couple. [DirectionalReading] is a fact about a *person* — "she is 70%
/// of this one" — and arguing in the comments is the distribution
/// mechanism this product has instead of an ad budget. So whenever the
/// pull is lopsided enough to be worth saying out loud, it goes first
/// and the score is demoted to context.
abstract final class CarouselCaption {
  /// Tags every post carries, before the two sign tags are added.
  static const List<String> baseTags = [
    'astrology',
    'compatibility',
    'zodiac',
  ];

  /// The caption for [match], ready to paste.
  static String forMatch(CompatibilityMatch match) {
    final tags = tagsFor(match).map((tag) => '#$tag').join(' ');
    return '${headline(match)}\n${hook(match)}\n\n$tags';
  }

  /// The first line: who, and the number.
  static String headline(CompatibilityMatch match) =>
      '${match.you.name} + ${match.them.name} — ${match.overall}%';

  /// The line that does the work.
  ///
  /// Falls back to [CompatibilityMatch.shareLine] when the pull is too
  /// even to be interesting. A "51% / 49%" hook is worse than no hook:
  /// it reads as a model with nothing to say, which is exactly the
  /// impression [DirectionalReading.isBalanced] exists to avoid giving.
  static String hook(CompatibilityMatch match) {
    final pull = match.pull;
    if (pull.isBalanced) return match.shareLine;
    final leader = pull.leansYou ? match.you : match.them;
    final share = pull.leansYou ? pull.yourShare : pull.theirShare;
    return '${leader.name} is $share% of this one.';
  }

  /// Hashtags, without their leading `#`, in posting order.
  ///
  /// Both sun signs are appended because sign tags are how this content
  /// gets found by people who were not looking for an app.
  static List<String> tagsFor(CompatibilityMatch match) {
    final signs = <String>{
      match.you.sign.displayName.toLowerCase(),
      match.them.sign.displayName.toLowerCase(),
    };
    return [...baseTags, ...signs];
  }
}
