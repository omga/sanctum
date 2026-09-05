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

  /// The pairing's best number, named. Specific without implying a
  /// problem — see `ConversationStarters._fillers`.
  strongestFacet,

  /// What the pairing is like when nothing in particular is happening.
  ordinaryDay,

  /// Who needs more reassurance. True of every pairing, answerable from
  /// the chart, and the question people actually have.
  reassurance,

  /// What the user's own chart is like. The self conversation's
  /// equivalent of [ordinaryDay]: specific, answerable, and implying no
  /// problem.
  selfChart,

  /// No angle in particular, asked about oneself. Worded separately
  /// from [anything], which says "this pairing" and would be nonsense
  /// on a screen with no pairing behind it.
  selfAnything,

  /// No angle in particular. The last resort.
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
  ///
  /// Diagnostics first, when the reading actually raised one, then
  /// [_fillers] until the row is full. Seen on a device, the
  /// diagnostics-only version left an ordinary 77% pairing with one
  /// vague chip on an empty screen — which is the common case, not an
  /// edge case, and it undersold the whole feature.
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

    for (final filler in _fillers(match)) {
      if (starters.length >= limit) break;
      starters.add(filler);
    }
    return starters.take(limit).toList();
  }

  /// Questions worth asking about any pairing.
  ///
  /// ## Why these and not "the lowest facet, always"
  ///
  /// The obvious way to fill the row is to drop [lowFacetThreshold] and
  /// name the weakest number whatever it is. That trades the honesty
  /// rule for a full screen: on a strong pairing it manufactures a worry
  /// the reading never raised, which is the same mistake as claiming
  /// every Tuesday is significant.
  ///
  /// These are specific to the pairing and imply nothing is wrong. Each
  /// is answerable from what the app already computed — the highest
  /// facet by name and number, the aspect behind an ordinary day, and
  /// the Moons behind who needs reassuring — so the answer is still
  /// about *this* chart rather than about star signs.
  ///
  /// Ordered most-concrete-first, and deterministic.
  static List<ConversationStarter> _fillers(CompatibilityMatch match) {
    // Drama is excluded from "highest", because a high one is not a
    // strength and the app says so itself: `report.mechanism.drama`
    // reads "It is volatility, not virtue: a high number here is not a
    // compliment." Offering "Drama is the highest here at 98, what does
    // that give us?" would have the suggestion row contradict the
    // document — which is exactly how every number in the app starts
    // looking invented.
    final scored = match.facets
        .where((facet) => facet.facet != CompatibilityFacet.drama)
        .toList();
    final strongest = (scored.isEmpty ? match.facets : scored).reduce(
      (a, b) => b.score > a.score ? b : a,
    );
    return [
      ConversationStarter(
        StarterKind.strongestFacet,
        facet: strongest.facet,
      ),
      const ConversationStarter(StarterKind.ordinaryDay),
      const ConversationStarter(StarterKind.reassurance),
      // Never reached while three fillers exist. Kept as the floor, so
      // that shortening this list can never produce an empty row.
      const ConversationStarter(StarterKind.anything),
    ];
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

  /// Starters for a conversation about the user's own chart.
  ///
  /// Today's sky leads when there is one, for the same reason the entry
  /// cards lead with a low facet: a question the user already has beats
  /// one they have to invent. [StarterKind.selfChart] and
  /// [StarterKind.selfAnything] are the floor, so the row is never
  /// empty on a day with nothing in it.
  ///
  /// [today] is nullable because the transit needs a birth date and the
  /// app can be reached without one — the chart questions still work.
  static List<ConversationStarter> forSelf(DailyTransitReading? today) => [
    if (today?.transit != null)
      const ConversationStarter(StarterKind.transitToday)
    else if (today != null)
      const ConversationStarter(StarterKind.quietDay),
    const ConversationStarter(StarterKind.selfChart),
    const ConversationStarter(StarterKind.selfAnything),
  ];

  /// Whether a split is lopsided enough to be the most specific true
  /// thing about a pairing — the same threshold the share card and the
  /// report use, so the three never describe one split differently.
  static bool _isStrong(DirectionalReading reading) =>
      (reading.yourShare - 50).abs() >= DirectionalReading.strongTolerance;
}
