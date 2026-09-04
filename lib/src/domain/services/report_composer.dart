import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/relationship_report.dart';
import 'package:sanctum/src/domain/services/aspects.dart';
import 'package:sanctum/src/domain/services/compatibility_calculator.dart';

/// Builds the deep "You & X" report from a reading the user already has.
///
/// ## Why it deepens rather than recomputes
///
/// Every score in the output is copied from the [CompatibilityMatch] it
/// is given. Recomputing from the two birth dates would be one line
/// shorter and would let the paid document disagree with the free reveal
/// the user is looking at — a 77 on the dial and a 78 in the report —
/// which is the fastest available way to make every number in the app
/// look invented. The report adds explanation and geometry. It adds no
/// arithmetic.
///
/// ## What the report is allowed to claim
///
/// Depth, not horizon. The competitor's headline SKU in this category is
/// a ten-year forecast about a named private individual; that shape is
/// rejected in `roadmap.md` §1 and this composer has nowhere to put one.
/// [RelationshipReport.watchFor] names the fault line and the conditions
/// it shows up under — never a date.
///
/// ## Where the geometry comes in
///
/// The free reveal shows six numbers. This names the contacts behind
/// each of them, mirroring `CompatibilityCalculator`'s terms exactly, so
/// a reader can trace any score to the two placements that produced it.
/// Contacts that are not in orb are still listed, and still say so — a
/// document that found something to report about all thirty of them
/// would be inventing, and the value on sale here is that it does not.
///
/// ## Where the words live
///
/// `assets/content/<language>/copy.json` under `report.*`, reached
/// through [CopyBook]. Same split as every other composer: selection
/// logic here, prose as data, keys built from the enums that choose them
/// so a missing one fails loudly at the key rather than composing a
/// blank paragraph into something somebody paid for.
abstract final class ReportComposer {
  /// At or above this, a facet reads as a strength.
  static const int highBand = 75;

  /// At or below this, a facet reads as the fault line.
  static const int lowBand = 60;

  /// Composes the report for [match], in the language of [copy].
  ///
  /// Pure: the same match and the same copy book always compose the same
  /// document, which is what makes it testable and what makes a report
  /// the user re-opens next month identical to the one they bought.
  static RelationshipReport compose({
    required CompatibilityMatch match,
    required CopyBook copy,
  }) {
    final you = match.you;
    final them = match.them;
    final hasMoon = match.usesMoon;

    final facets = [
      for (final scored in match.facets)
        ReportFacet(
          facet: scored.facet,
          score: scored.score,
          band: bandFor(scored.score),
          mechanism: copy.get('report.mechanism.${scored.facet.name}'),
          reading: copy.get(
            'report.facet.${scored.facet.name}.${bandFor(scored.score).name}',
          ),
          contacts: _contactsFor(scored.facet, you, them, hasMoon: hasMoon),
        ),
    ];

    final moonContact = hasMoon
        ? Aspects.contact(you.moon!, them.moon!)
        : null;

    return RelationshipReport(
      match: match,
      opening: copy.get('report.opening.${match.aspect.name}'),
      facets: facets,
      pull: _direction(DirectionKind.pull, match.pull, you, them, copy),
      power: _direction(DirectionKind.power, match.power, you, them, copy),
      watchFor: _watchFor(match, copy),
      closing: copy.get('report.closing.${verdictKey(match.verdict)}'),
      moon: hasMoon
          ? ReportMoon(
              yourSign: you.moonSign!,
              theirSign: them.moonSign!,
              aspect: moonContact,
              reading: copy.get(
                'report.moon.${moonContact?.tone.name ?? 'none'}',
              ),
            )
          : null,
      moonAbsence: hasMoon ? null : copy.get('report.moon.absent'),
    );
  }

  /// The fault line, or an admission that there is not one.
  ///
  /// Keying this to the weakest facet unconditionally produces a
  /// document that calls an axis a strength on one page and warns about
  /// it on the next — which happens for about one pairing in a hundred
  /// and six, where every facet lands in the top band. Rare is not the
  /// same as acceptable in something somebody paid for, and "the lowest
  /// axis here is still a working one" is both true and the same posture
  /// as the daily reading admitting a quiet day.
  static String _watchFor(CompatibilityMatch match, CopyBook copy) {
    final weakest = match.weakest;
    if (bandFor(weakest.score) == FacetBand.high) {
      return copy.get('report.watch.none');
    }
    return copy.get('report.watch.${weakest.facet.name}');
  }

  /// Which band [score] falls in.
  static FacetBand bandFor(int score) => switch (score) {
    >= highBand => FacetBand.high,
    <= lowBand => FacetBand.low,
    _ => FacetBand.mid,
  };

  /// Which way [yourShare] leans, and how hard.
  static DirectionLean leanFor(int yourShare) {
    final offset = yourShare - 50;
    if (offset.abs() <= DirectionalReading.evenTolerance) {
      return DirectionLean.even;
    }
    final decisive = offset.abs() >= DirectionalReading.strongTolerance;
    if (offset > 0) {
      return decisive ? DirectionLean.youStrong : DirectionLean.you;
    }
    return decisive ? DirectionLean.themStrong : DirectionLean.them;
  }

  /// The copy key segment for a verdict word.
  ///
  /// Derived from [CompatibilityCalculator.verdictFor]'s own output
  /// rather than from a second switch on the same thresholds. Two
  /// switches would be free to drift apart, and the day they did, a
  /// score would show one word on the dial and select the paragraph for
  /// another.
  static String verdictKey(String verdict) =>
      verdict.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  static ReportDirection _direction(
    DirectionKind kind,
    DirectionalReading reading,
    MatchPerson you,
    MatchPerson them,
    CopyBook copy,
  ) {
    final lean = leanFor(reading.yourShare);
    final group = kind == DirectionKind.pull ? 'pull' : 'power';

    // The two one-way contacts the split is literally made of. Pull is
    // Mars reaching Venus, power is Saturn reaching Sun — see
    // `CompatibilityCalculator.pullShare` and `powerShare`.
    final contacts = kind == DirectionKind.pull
        ? [
            _contact(you, them, ChartPoint.mars, ChartPoint.venus),
            _contact(you, them, ChartPoint.venus, ChartPoint.mars),
          ]
        : [
            _contact(you, them, ChartPoint.saturn, ChartPoint.sun),
            _contact(you, them, ChartPoint.sun, ChartPoint.saturn),
          ];

    return ReportDirection(
      kind: kind,
      yourShare: reading.yourShare,
      lean: lean,
      reading: copy.get('report.$group.${lean.name}'),
      contacts: contacts,
    );
  }

  /// The contacts behind one facet, mirroring the calculator's terms.
  ///
  /// The Moon terms appear only when both birth times are known, which
  /// is the same condition the calculator uses to include them in the
  /// score. Listing a Moon contact the score did not use would be
  /// claiming the number came from somewhere it did not.
  static List<ReportContact> _contactsFor(
    CompatibilityFacet facet,
    MatchPerson you,
    MatchPerson them, {
    required bool hasMoon,
  }) {
    ReportContact pair(ChartPoint yours, ChartPoint theirs) =>
        _contact(you, them, yours, theirs, facet);

    return switch (facet) {
      // Desire is Venus and Mars. The Moon is not about wanting, so the
      // calculator leaves it out of Spark and so does this.
      CompatibilityFacet.spark => [
        pair(ChartPoint.venus, ChartPoint.mars),
        pair(ChartPoint.mars, ChartPoint.venus),
        pair(ChartPoint.mars, ChartPoint.mars),
      ],
      CompatibilityFacet.vibe => [
        pair(ChartPoint.sun, ChartPoint.sun),
        pair(ChartPoint.venus, ChartPoint.venus),
        if (hasMoon) pair(ChartPoint.moon, ChartPoint.moon),
      ],
      CompatibilityFacet.trust => [
        pair(ChartPoint.sun, ChartPoint.venus),
        pair(ChartPoint.venus, ChartPoint.sun),
        if (hasMoon) ...[
          pair(ChartPoint.moon, ChartPoint.venus),
          pair(ChartPoint.venus, ChartPoint.moon),
        ],
      ],
      CompatibilityFacet.drama => [
        pair(ChartPoint.sun, ChartPoint.sun),
        pair(ChartPoint.mars, ChartPoint.mars),
        if (hasMoon) ...[
          pair(ChartPoint.moon, ChartPoint.mars),
          pair(ChartPoint.mars, ChartPoint.moon),
        ],
      ],
      CompatibilityFacet.depth => [
        pair(ChartPoint.saturn, ChartPoint.venus),
        pair(ChartPoint.venus, ChartPoint.saturn),
        if (hasMoon) ...[
          pair(ChartPoint.saturn, ChartPoint.moon),
          pair(ChartPoint.moon, ChartPoint.saturn),
        ],
      ],
      // Saturn to Sun is the commitment contact and stands alone.
      CompatibilityFacet.future => [
        pair(ChartPoint.saturn, ChartPoint.sun),
        pair(ChartPoint.sun, ChartPoint.saturn),
      ],
    };
  }

  static ReportContact _contact(
    MatchPerson you,
    MatchPerson them,
    ChartPoint yours,
    ChartPoint theirs, [
    CompatibilityFacet? facet,
  ]) {
    final a = _longitude(you, yours);
    final b = _longitude(them, theirs);

    // Null longitudes mean an unknown birth time, which is not a contact
    // of zero strength — it is an absence of information, and the report
    // says so rather than reporting an angle to a body it could not
    // place. The separation is carried whenever both are placed, in orb
    // or not, so a section always has real geometry under it.
    if (a == null || b == null) {
      return ReportContact(
        yourPoint: yours,
        theirPoint: theirs,
        facet: facet,
      );
    }

    return ReportContact(
      yourPoint: yours,
      theirPoint: theirs,
      facet: facet,
      aspect: Aspects.contact(a, b),
      separation: Aspects.separation(a, b),
    );
  }

  static double? _longitude(MatchPerson person, ChartPoint point) =>
      switch (point) {
        ChartPoint.sun => person.sun,
        ChartPoint.moon => person.moon,
        ChartPoint.venus => person.venus,
        ChartPoint.mars => person.mars,
        ChartPoint.saturn => person.saturn,
      };
}
