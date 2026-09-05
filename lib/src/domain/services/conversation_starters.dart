import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/transit.dart';

/// Which question a starter is.
///
/// The copy lives in `copy.json` under `advisor.starter.<kind>` like
/// every other written line; this is the selection, not the wording.
enum StarterKind {
  /// The weakest facet, named. "Why is Trust only 43?"
  lowFacet,

  /// The other person wants it more.
  pullThem,

  /// The user wants it more. The most-asked question in the category,
  /// and the one people are least likely to type first.
  pullYou,

  /// The other person sets the terms.
  powerThem,

  /// The user sets the terms.
  powerYou,

  /// Today's transit, when there is one.
  transitToday,

  /// Today's sky is quiet, and the app said so.
  quietDay,

  /// No angle in particular. Always offered last.
  anything,
}

/// One suggested question.
///
/// ## Why there are two copy keys
///
/// A starter is rendered with the person's name — "Why does Alex want
/// this more than I do?" — because that is what makes it feel like the
/// app is talking about *your* situation, and the name is already on the
/// phone.
///
/// The same question is *sent* without it. [promptKey] is the neutral
/// wording, and it is what goes to the transport. Two keys rather than
/// running `MessageRedaction` over the rendered one, because a starter
/// is copy this repository wrote: it can simply be written twice, and a
/// deliberate second string is more reliable than a regex over the
/// first. The redactor exists for text the *user* types, where there is
/// no second string to reach for.
class ConversationStarter {
  /// Creates a starter.
  const ConversationStarter(this.kind, {this.facet});

  /// Which question.
  final StarterKind kind;

  /// The facet this is about, for [StarterKind.lowFacet].
  final CompatibilityFacet? facet;

  /// Copy key for what the user reads. May carry a `{name}` slot.
  String get displayKey => 'advisor.starter.${kind.name}';

  /// Copy key for what is sent. Never carries a `{name}` slot.
  String get promptKey => 'advisor.prompt.${kind.name}';
}

/// Which questions to offer, and in what order.
///
/// ## Why the app suggests questions at all
///
/// `roadmap.md` §2: "The compatibility feature also generates the
/// questions for free. 'Why is our Trust only 43?' is a question a user
/// already has, on a screen they are already looking at, about numbers
/// the app already computed."
///
/// A blank text box asks somebody to invent a question about astrology
/// on the spot, which is a small essay assignment. A row of three
/// specific questions about numbers they are currently looking at is a
/// tap.
///
/// ## Why it is ranked and capped
///
/// Three fit on a phone above the keyboard. More than that is a menu,
/// and a menu is a decision rather than an invitation. The ranking is
/// most-specific-first: a named low score beats a lopsided split, which
/// beats "ask me anything", because specificity is the entire
/// difference between this and a generic chat wrapper.
///
/// Pure and deterministic, so the same reading always offers the same
/// questions — a suggestion that changes between two visits to the same
/// screen reads as the app having no idea what it thinks.
abstract final class ConversationStarters {
  /// How many are offered.
  static const int limit = 3;

  /// A facet at or below this is worth asking about by name.
  ///
  /// Deliberately not "the lowest facet, always": on a strong pairing
  /// the lowest facet is a 71, and asking "why is Depth only 71" invents
  /// a problem the reading did not describe. This app admits quiet days;
  /// it should not manufacture worried ones.
  static const int lowFacetThreshold = 55;

  /// Starters for a compatibility reading.
  static List<ConversationStarter> forMatch(CompatibilityMatch match) {
    final starters = <ConversationStarter>[];

    final weakest = match.facets.reduce(
      (a, b) => b.score < a.score ? b : a,
    );
    if (weakest.score <= lowFacetThreshold) {
      starters.add(
        ConversationStarter(StarterKind.lowFacet, facet: weakest.facet),
      );
    }

    // Pull before power. Both are lopsided splits, but "who wants this
    // more" is the question people arrive with, and "who sets the terms"
    // is one they recognise only once it is put to them.
    if (_isStrong(match.pull)) {
      starters.add(
        ConversationStarter(
          match.pull.leansYou ? StarterKind.pullYou : StarterKind.pullThem,
        ),
      );
    }

    if (_isStrong(match.power)) {
      starters.add(
        ConversationStarter(
          match.power.leansYou ? StarterKind.powerYou : StarterKind.powerThem,
        ),
      );
    }

    starters.add(const ConversationStarter(StarterKind.anything));
    return starters.take(limit).toList();
  }

  /// Starters for today's reading.
  ///
  /// A quiet sky gets its own question rather than no questions. "Why is
  /// nothing happening today?" is a real thing to wonder, and offering
  /// silence instead would make the quiet-day honesty feel like the app
  /// running out of things to say.
  static List<ConversationStarter> forToday(DailyTransitReading reading) => [
    if (reading.transit != null)
      const ConversationStarter(StarterKind.transitToday)
    else
      const ConversationStarter(StarterKind.quietDay),
    const ConversationStarter(StarterKind.anything),
  ];

  /// Whether a split is lopsided enough to be the most specific true
  /// thing about a pairing — the same threshold the share card and the
  /// report use, so the three never describe one split differently.
  static bool _isStrong(DirectionalReading reading) =>
      (reading.yourShare - 50).abs() >= DirectionalReading.strongTolerance;
}
