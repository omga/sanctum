import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/relationship_report.dart';
import 'package:sanctum/src/domain/models/transit.dart';

/// Everything the advisor is allowed to be told.
///
/// ## Why this is a closed set and not a `Map<String, dynamic>`
///
/// This is the same decision, for the same reason, as `AnalyticsEvent`:
/// a private constructor and a fixed list of named factories, so that
/// **call sites cannot leak personal data because no constructor accepts
/// any**. It is the type system rather than a convention somebody has to
/// catch in review.
///
/// The stakes here are higher than they are for analytics. `handoff.md`
/// §3 states the promise the whole product is differentiated on — "your
/// name, your birth date and your journal stay on this phone" — and
/// notes that it survives analytics and RevenueCat and **does not
/// survive AI chat**. It survives this file, and only because of what
/// this file refuses to carry.
///
/// ## What is sent
///
/// Computed positions, angles, scores and enum names. All of it is
/// derived, none of it identifies anybody, and a chart is reconstructible
/// from positions without the date that produced them — which is exactly
/// why the date is not here.
///
/// ## What is not, and cannot be
///
/// No name. No birth date. No birth time. No journal text. No free-text
/// answer from the quiz. Nothing from the celebrity catalogue except an
/// id that is identical for every user who taps the same row.
///
/// There is no `String name` field and no `DateTime birthDate` field
/// anywhere in this type, so a future caller cannot pass one without
/// first deleting this paragraph. `advisor_context_test.dart` backs it
/// with a denylist, a primitives-only walk and a length check that would
/// catch prose, and asserts that a real match's payload contains no
/// substring of either person's name.
///
/// ## The name the user sees
///
/// The nudge says "You + Alex" and the transcript says "Alex", because
/// the name is already on the phone and never needs to leave it. The
/// prompt says `them`; the screen substitutes locally on the way in and
/// on the way out. See `advisor.md` §1.
final class AdvisorContext {
  const AdvisorContext._(
    this.surface,
    this.facts, {
    required this.languageCode,
  });

  /// A question about a compatibility reading.
  ///
  /// Takes the composed match rather than two birth dates for the same
  /// reason `RelationshipReport` does: every number here is *copied*
  /// from what the user was shown, so the advisor can never quote a
  /// score that disagrees with the screen the question was asked from.
  factory AdvisorContext.forMatch(
    CompatibilityMatch match, {
    required String languageCode,
  }) => AdvisorContext._('match', {
    'aspect': match.aspect.name,
    'overall': match.overall,
    'you': _positions(match.you),
    'them': _positions(match.them),
    'facets': [
      for (final facet in match.facets)
        {'facet': facet.facet.name, 'score': facet.score},
    ],
    'pull': _direction(match.pull),
    'power': _direction(match.power),
  }, languageCode: languageCode);

  /// A question about a relationship report the user owns.
  ///
  /// Carries the report's extra geometry — the per-facet band and the
  /// contacts behind each score — because somebody holding a document
  /// they paid for asks more specific questions than somebody looking at
  /// a percentage, and the answer has to be able to reach the same
  /// detail they are reading.
  factory AdvisorContext.forReport(
    RelationshipReport report, {
    required String languageCode,
  }) {
    final match = report.match;
    return AdvisorContext._('report', {
      'aspect': match.aspect.name,
      'overall': match.overall,
      'you': _positions(match.you),
      'them': _positions(match.them),
      'facets': [
        for (final facet in report.facets)
          {
            'facet': facet.facet.name,
            'score': facet.score,
            'band': facet.band.name,
            'contacts': [
              for (final contact in facet.contacts) _contact(contact),
            ],
          },
      ],
      'pull': _reportDirection(report.pull),
      'power': _reportDirection(report.power),
      if (report.moon case final moon?)
        'moon': {
          'your_sign': moon.yourSign.name,
          'their_sign': moon.theirSign.name,
          if (moon.aspect case final aspect?) 'aspect': aspect.aspect.name,
          if (moon.aspect case final aspect?) 'orb': _round(aspect.orb),
        },
    }, languageCode: languageCode);
  }

  /// A question about today.
  ///
  /// A quiet sky is a fact worth sending, not an absence worth hiding.
  /// The app admits quiet days on the home screen (`handoff.md`), and an
  /// advisor that invents significance for one would undo that in a
  /// sentence.
  factory AdvisorContext.forToday(
    DailyTransitReading reading, {
    required String languageCode,
  }) => AdvisorContext._('today', _sky(reading), languageCode: languageCode);

  /// A question about the user's own chart.
  ///
  /// The only surface with one set of positions rather than two, and
  /// the reason it exists: everything else the advisor answers is about
  /// a pairing, and "what am I actually like" is the question the app
  /// has the data for and was refusing to take.
  ///
  /// Carries today's sky as well when there is one, because a natal
  /// chart alone invites the timeless horoscope-filler answer this
  /// prompt spends three rules forbidding — the transit is the concrete
  /// thing there is to say something about today.
  ///
  /// Same rule as everywhere else in this file: [_positions] is
  /// longitudes and a sign, and the birth date that produced them is
  /// not here and cannot be.
  factory AdvisorContext.forSelf({
    required MatchPerson you,
    required String languageCode,
    DailyTransitReading? today,
  }) => AdvisorContext._('self', {
    'you': _positions(you),
    if (today case final reading?) ..._sky(reading),
  }, languageCode: languageCode);

  /// What one day's sky looks like as facts.
  ///
  /// Shared by [AdvisorContext.forToday] and [AdvisorContext.forSelf] so
  /// the two surfaces can never describe the same day differently.
  static Map<String, Object> _sky(DailyTransitReading reading) => {
    'quiet': reading.transit == null,
    if (reading.transit case final transit?)
      'transit': {
        'transiting': transit.transiting.name,
        'natal': transit.natal.name,
        'aspect': transit.aspect.name,
        'orb': _round(transit.orb),
        'retrograde': transit.retrograde,
      },
    'retrogrades': [
      for (final planet in reading.retrogrades) planet.name,
    ],
  };

  /// Which screen the question was asked from.
  ///
  /// Selects the system prompt server-side. A question asked from a
  /// report should be answered with the report open, so to speak.
  final String surface;

  /// The computed facts, and nothing else.
  ///
  /// Values are numbers, booleans, enum *names*, and lists and maps of
  /// those. Enum names travel for the same reason question ids do in
  /// analytics: they come from this repository, are identical for every
  /// user, and are the entire content of the message.
  final Map<String, Object> facts;

  /// Which language the answer should be written in.
  ///
  /// A locale code, not a preference profile. The advisor answering in
  /// English to somebody reading the app in Ukrainian is the most basic
  /// way this feature can feel broken.
  final String languageCode;

  /// Positions for one side of a pairing.
  ///
  /// Longitudes rather than a birth date, which is the whole design: the
  /// chart is derivable from these, the date is not derivable from them,
  /// and the model needs the former.
  static Map<String, Object> _positions(MatchPerson person) => {
    'sign': person.sign.name,
    'sun': _round(person.sun),
    'venus': _round(person.venus),
    'mars': _round(person.mars),
    'saturn': _round(person.saturn),
    // Absent rather than guessed when no birth time is known — the same
    // rule `MatchPerson.moon` already enforces, carried through so the
    // advisor cannot describe a Moon the app itself refuses to place.
    if (person.moon case final moon?) 'moon': _round(moon),
  };

  static Map<String, Object> _direction(DirectionalReading reading) => {
    'kind': reading.kind.name,
    'your_share': reading.yourShare,
  };

  static Map<String, Object> _reportDirection(ReportDirection direction) => {
    'kind': direction.kind.name,
    'your_share': direction.yourShare,
    'lean': direction.lean.name,
    'contacts': [for (final contact in direction.contacts) _contact(contact)],
  };

  static Map<String, Object> _contact(ReportContact contact) => {
    'your_point': contact.yourPoint.name,
    'their_point': contact.theirPoint.name,
    if (contact.aspect case final aspect?) 'aspect': aspect.aspect.name,
    if (contact.aspect case final aspect?) 'orb': _round(aspect.orb),
    if (contact.separation case final separation?)
      'separation': _round(separation),
  };

  /// One decimal place.
  ///
  /// Not cosmetic. A raw double carries fifteen significant figures of
  /// an ephemeris calculation, which is both meaningless to a language
  /// model and — across enough fields — a fingerprint. A tenth of a
  /// degree is finer than any interpretation this app makes.
  static double _round(double value) => (value * 10).roundToDouble() / 10;
}
