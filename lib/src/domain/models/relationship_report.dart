import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/planet.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/aspects.dart';

/// A point in a chart that a report is allowed to name.
///
/// Deliberately *not* [Planet], which excludes the Moon on purpose
/// because a birth date alone cannot place it. The report is the one
/// surface that may talk about the Moon — and only in the case that
/// makes it legitimate, which is both people having supplied a birth
/// time. Widening `Planet` to carry the Moon would let every other
/// consumer of it, transits included, start reading a body none of them
/// can locate.
enum ChartPoint {
  /// Identity.
  sun,

  /// Emotional register. Only ever populated when a birth time is known.
  moon,

  /// What someone is drawn to.
  venus,

  /// How someone pursues.
  mars,

  /// What someone takes seriously.
  saturn,
}

/// Where a facet's score sits, which is what selects its paragraph.
///
/// Three bands rather than a continuous description, because the copy is
/// written prose and there is no honest way to interpolate a sentence.
enum FacetBand {
  /// Working, and worth naming as a strength.
  high,

  /// Real but unremarkable. The most common answer, and it says so.
  mid,

  /// The fault line.
  low,
}

/// Which way a split leans, and how hard.
enum DirectionLean {
  /// The user, decisively.
  youStrong,

  /// The user, but not by much.
  you,

  /// Close enough to even to be called even.
  even,

  /// The other person, but not by much.
  them,

  /// The other person, decisively.
  themStrong,
}

/// One synastry contact: two placements, and the angle between them.
///
/// Carries the geometry rather than a rendered sentence, because the
/// planet names and the aspect names are UI chrome and belong in the ARB
/// with the rest of the interface — see `sanctum_lexicon.dart`. What the
/// report composes as prose is the *explanation*; what it computes is
/// the angle, and the two are kept apart on purpose.
class ReportContact {
  /// Creates a contact.
  const ReportContact({
    required this.yourPoint,
    required this.theirPoint,
    this.facet,
    this.aspect,
    this.separation,
  });

  /// The user's placement.
  final ChartPoint yourPoint;

  /// The other person's placement.
  final ChartPoint theirPoint;

  /// The axis this contact feeds, or `null` when it belongs to a
  /// directional split rather than to one of the six axes.
  final CompatibilityFacet? facet;

  /// The named angle, or `null` when nothing is in orb.
  ///
  /// Null is the common case and an honest one. Most planet pairs in
  /// most charts are simply not in contact, and a report that found
  /// something to say about all of them would be inventing.
  final AspectContact? aspect;

  /// Angular separation between the two placements, `0–180`, or `null`
  /// when one of them could not be placed at all.
  ///
  /// Carried even when [aspect] is null, which is the case for about two
  /// in five sections. Without it a facet whose contacts are all out of
  /// orb would render as three lines of "no contact" underneath a
  /// paragraph explaining a score — a document that says "here is what
  /// this number is made of" and then shows nothing. The angle is real
  /// either way; only the *name* requires an orb.
  final double? separation;

  /// Whether these two placements are actually in contact.
  bool get isInContact => aspect != null;
}

/// One facet of the reading, explained rather than merely scored.
///
/// The free reveal shows six numbers on a hexagon and a line about the
/// highest and the lowest. This is what the other four are for.
class ReportFacet {
  /// Creates a facet section.
  const ReportFacet({
    required this.facet,
    required this.score,
    required this.band,
    required this.mechanism,
    required this.reading,
    required this.contacts,
  });

  /// Which axis.
  final CompatibilityFacet facet;

  /// Its score, copied from the match rather than recomputed.
  final int score;

  /// Which band the score falls in.
  final FacetBand band;

  /// What drives this axis at all — the standing claim, same for
  /// everyone, and the thing that makes the number legible.
  final String mechanism;

  /// What this particular score means for these two people.
  final String reading;

  /// The contacts behind the number.
  final List<ReportContact> contacts;
}

/// One directional split, at length.
class ReportDirection {
  /// Creates a direction section.
  const ReportDirection({
    required this.kind,
    required this.yourShare,
    required this.lean,
    required this.reading,
    required this.contacts,
  });

  /// Pull or power.
  final DirectionKind kind;

  /// The user's share of 100, copied from the match.
  final int yourShare;

  /// Which way it leans, and how hard.
  final DirectionLean lean;

  /// The long reading for that lean.
  final String reading;

  /// The two one-way contacts that produced the split.
  final List<ReportContact> contacts;

  /// The other side's share.
  int get theirShare => 100 - yourShare;
}

/// The Moon section, which exists only when both birth times are known.
class ReportMoon {
  /// Creates a Moon section.
  const ReportMoon({
    required this.yourSign,
    required this.theirSign,
    required this.reading,
    this.aspect,
  });

  /// The sign the user's Moon was in.
  final ZodiacSign yourSign;

  /// The sign the other person's Moon was in.
  final ZodiacSign theirSign;

  /// What the contact between them means.
  final String reading;

  /// The angle between the two Moons, or `null` when none is in orb.
  final AspectContact? aspect;
}

/// The deep "You & X" reading, sold once per pairing.
///
/// ## Why it takes a composed match rather than two birth dates
///
/// The report *deepens* a reading the user has already seen. Recomputing
/// from the dates would let the two disagree — a 77% on the reveal and a
/// 78% in the thing they paid for — which is the single fastest way to
/// make every number in the app look invented. Every score here is
/// copied from [match]; nothing is recalculated.
///
/// ## What it sells, and what it refuses to
///
/// Depth, not horizon. Every facet explained, both directional splits at
/// length, the actual angles behind each number, and the fault line
/// named. No forecast: the category's headline SKU is a ten-year
/// prophecy about a named private individual, and one of those would
/// turn the honesty the rest of this app is built on — quiet days
/// admitted, captions naming work that actually happens, a score floor
/// that is kind but not a lie — into a marketing position. See
/// `roadmap.md` §1.
class RelationshipReport {
  /// Creates a report.
  const RelationshipReport({
    required this.match,
    required this.opening,
    required this.facets,
    required this.pull,
    required this.power,
    required this.watchFor,
    required this.closing,
    this.moon,
    this.moonAbsence,
  });

  /// The reading this deepens.
  final CompatibilityMatch match;

  /// The first paragraph, from the aspect between the two signs.
  final String opening;

  /// All six facets, in display order.
  final List<ReportFacet> facets;

  /// Who wants it more.
  final ReportDirection pull;

  /// Who sets the terms.
  final ReportDirection power;

  /// The fault line, from the weakest facet, and what it looks like in
  /// practice. Conditions rather than dates — this app does not forecast.
  final String watchFor;

  /// The last paragraph, from the headline score band.
  final String closing;

  /// The Moon section, or `null` when either birth time is unknown.
  final ReportMoon? moon;

  /// Why the Moon is missing. Non-null exactly when [moon] is null.
  ///
  /// Stated as a limit rather than as an upsell. It is one — a reading
  /// without the Moon is thinner, and saying so is what makes the rest
  /// of the document trustworthy.
  final String? moonAbsence;

  /// Both directional splits, in display order.
  List<ReportDirection> get directions => [pull, power];

  /// Every contact the report names, facets then directions.
  List<ReportContact> get contacts => [
    for (final facet in facets) ...facet.contacts,
    for (final direction in directions) ...direction.contacts,
  ];

  /// Contacts that are actually in orb.
  List<ReportContact> get liveContacts =>
      [for (final one in contacts) if (one.isInContact) one];

  /// Identity of the pairing this reports on. Matches
  /// [CompatibilityMatch.id], which is what a purchase is recorded
  /// against.
  String get id => match.id;
}
