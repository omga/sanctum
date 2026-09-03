import 'package:dart_mappable/dart_mappable.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/calendar_date.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/ephemeris.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';

part 'compatibility.mapper.dart';

/// The classical angle between two signs on the wheel.
///
/// Everything the model needs is in here. Element and modality
/// relationships are *functions* of the distance between two signs —
/// signs three apart are always the same modality and clashing elements,
/// signs four apart are always the same element — so the aspect is not
/// one input among several, it is the whole geometry.
@MappableEnum()
enum ZodiacAspect {
  /// Same sign.
  conjunction('Same sign'),

  /// One sign apart. Neighbours with nothing in common.
  semiSextile('Neighbours'),

  /// Two apart. Easy and warm.
  sextile('Easy'),

  /// Three apart. Friction, and heat.
  square('Charged'),

  /// Four apart. The harmonious one.
  trine('In flow'),

  /// Five apart. Different operating systems.
  quincunx('Mismatched'),

  /// Six apart. Opposite ends of one axis.
  opposition('Magnetic');

  const ZodiacAspect(this.displayName);

  /// Short human-readable name.
  final String displayName;
}

/// The six axes of a reading.
///
/// ## Why these six, and why the names are short
///
/// The first version scored Spark, Communication, Trust and Staying
/// power, which reads like a performance review. People do not describe
/// their relationships in those words — they say it was intense, or it
/// was easy, or they could not let it go.
///
/// Every name here is also one short word on purpose. These are axis
/// labels on a hexagon, and the app is going to Spanish, Russian and
/// French: "Communication" becomes "Общение", "Staying power" becomes
/// "Долговечность", and a label that wraps to three lines wrecks a radar
/// chart. Short in English is the only way to stay short everywhere.
@MappableEnum()
enum CompatibilityFacet {
  /// Physical charge. Venus against Mars.
  spark('Spark'),

  /// Whether the ordinary days are enjoyable. Sun and Venus, flowing.
  vibe('Vibe'),

  /// Whether you are liked, not just wanted. Sun against Venus.
  trust('Trust'),

  /// Volatility. Sun against Sun, Mars against Mars — the hard angles.
  drama('Drama'),

  /// The weight that makes it hard to walk away. Saturn against Venus.
  depth('Depth'),

  /// Whether it survives being ordinary. Saturn against Sun, flowing.
  future('Future');

  const CompatibilityFacet(this.displayName);

  /// Human-readable name.
  final String displayName;
}

/// Something the two people do not share equally.
@MappableEnum()
enum DirectionKind {
  /// Who wants it more.
  pull('Who wants it more'),

  /// Who sets the terms.
  power('Who holds the power');

  const DirectionKind(this.displayName);

  /// Row heading.
  final String displayName;
}

/// One lopsided reading, as a split that sums to 100.
///
/// ## Why any of this is directional
///
/// Every number in the first version was symmetric, and symmetry is
/// exactly what nobody posts. "We are 86% compatible" is a fact about a
/// couple; "he is 71% more into this than you are" is a fact about a
/// person, and it is the single most screenshotted claim in this
/// category.
///
/// It is also the correct astrology rather than a growth trick. Your
/// Mars on their Venus is a different contact from their Mars on your
/// Venus, and Saturn is famously one-way: the Saturn person is the one
/// who sets the terms, and the other one feels it.
@MappableClass()
class DirectionalReading with DirectionalReadingMappable {
  /// Creates a reading.
  const DirectionalReading({
    required this.kind,
    required this.yourShare,
    required this.line,
  });

  /// What is being split.
  final DirectionKind kind;

  /// The user's share, `0–100`. Their share is the remainder.
  final int yourShare;

  /// The line shown under the bar.
  final String line;

  /// The other side's share.
  int get theirShare => 100 - yourShare;

  /// How far from an even split still counts as even.
  static const int evenTolerance = 6;

  /// Whether this is close enough to even to be worth calling even.
  bool get isBalanced => (yourShare - 50).abs() <= evenTolerance;

  /// Whether the user is the heavier side.
  bool get leansYou => yourShare > 50;
}

/// One scored facet.
@MappableClass()
class FacetScore with FacetScoreMappable {
  /// Creates a facet score.
  const FacetScore({required this.facet, required this.score});

  /// Which facet.
  final CompatibilityFacet facet;

  /// Its score, 0–100.
  final int score;
}

/// One side of a match.
@MappableClass()
class MatchPerson with MatchPersonMappable {
  /// Creates a person.
  const MatchPerson({
    required this.name,
    required this.birthDate,
    this.birthTime = BirthTime.unknown,
    this.celebrityId,
  });

  /// What to call them.
  final String name;

  /// Their birth date. The reading works from this alone.
  ///
  /// Hooked because it is a calendar date, not an instant — see
  /// [CalendarDateHook] for the day it used to lose in storage.
  @MappableField(hook: CalendarDateHook())
  final DateTime birthDate;

  /// Their birth time, when they know it.
  ///
  /// Defaults to unknown, which is what every person stored before this
  /// existed decodes to — so no migration, and no reading changes under
  /// anyone who has not answered the new question.
  final BirthTime birthTime;

  /// Set when this side came from the celebrity catalogue.
  ///
  /// Catalogue entries are birth *dates* from Wikidata's `P569`, which
  /// records no time. They are therefore always [BirthTime.unknown], and
  /// the picker does not ask — inventing 12:00 for a public figure would
  /// put a fabricated Moon sign next to a real name on a card designed
  /// to be posted.
  final String? celebrityId;

  /// Their sun sign, computed rather than stored — one source of truth,
  /// and a persisted match can never disagree with its own birth date.
  ZodiacSign get sign => Zodiac.signFor(birthDate);

  /// Ecliptic longitude of the Sun at birth, tropical degrees.
  double get sun => Ephemeris.sunLongitude(birthDate);

  /// Ecliptic longitude of Venus at birth. What they are drawn to.
  double get venus => Ephemeris.venusLongitude(birthDate);

  /// Ecliptic longitude of Mars at birth. How they pursue.
  double get mars => Ephemeris.marsLongitude(birthDate);

  /// Ecliptic longitude of Saturn at birth. What they take seriously.
  ///
  /// Saturn is the slowest body used here — two and a half years to a
  /// sign — which is what makes it trustworthy from a birth date with
  /// no time attached.
  double get saturn => Ephemeris.saturnLongitude(birthDate);

  /// The sign Venus was in.
  ZodiacSign get venusSign => Ephemeris.signAt(venus);

  /// Ecliptic longitude of the Moon at birth, or null without a time.
  ///
  /// Null rather than a noon guess, deliberately. The Moon crosses a
  /// sign every 2.3 days, so a noon value carries a ±6.5° error that
  /// would be indistinguishable from a real one by the time it reached a
  /// score. Nullable makes the absence visible to every caller, and
  /// `CompatibilityCalculator` is written to leave the Moon out of the
  /// model entirely rather than fill it in.
  double? get moon {
    final offset = birthTime.sinceMidnight;
    if (offset == null) return null;
    return Ephemeris.moonLongitude(birthDate, timeOfDay: offset);
  }

  /// The sign the Moon was in, or null without a birth time.
  ZodiacSign? get moonSign {
    final longitude = moon;
    return longitude == null ? null : Ephemeris.signAt(longitude);
  }

  /// The sign Mars was in.
  ZodiacSign get marsSign => Ephemeris.signAt(mars);

  /// First letter, for the avatar disc.
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// Stable identity for this person.
  ///
  /// Deterministic so that re-opening a match the user already paid for
  /// — or unlocked — is recognised as the same match rather than
  /// charging them twice for the same two birth dates.
  String get key {
    final id = celebrityId;
    if (id != null) return 'celeb:$id';
    final ymd = '${birthDate.year}-${birthDate.month}-${birthDate.day}';
    // The time joins the key only when it is known, so every person
    // stored before the question existed keeps the id they already have
    // and stays unlocked. Two different times are two different charts
    // and therefore two different readings, which is why they must not
    // collide on one id.
    final minutes = birthTime.minuteOfDay;
    final suffix = minutes == null ? '' : ':$minutes';
    return 'person:${name.trim().toLowerCase()}:$ymd$suffix';
  }
}

/// A composed compatibility reading.
@MappableClass()
class CompatibilityMatch with CompatibilityMatchMappable {
  /// Creates a match.
  const CompatibilityMatch({
    required this.you,
    required this.them,
    required this.aspect,
    required this.overall,
    required this.facets,
    required this.verdict,
    required this.dynamicLine,
    required this.elementLine,
    required this.worksLine,
    required this.watchLine,
    required this.shareLine,
    required this.pull,
    required this.power,
    required this.createdAt,
  });

  /// The user.
  final MatchPerson you;

  /// Who they checked.
  final MatchPerson them;

  /// The angle between the two signs.
  final ZodiacAspect aspect;

  /// Headline score, 0–100.
  final int overall;

  /// The four facet scores, in display order.
  final List<FacetScore> facets;

  /// One word for the score band. Postable on its own.
  final String verdict;

  /// The core dynamic, from the aspect.
  final String dynamicLine;

  /// The texture, from the two elements.
  final String elementLine;

  /// What is working, from the strongest facet.
  final String worksLine;

  /// What to watch, from the weakest facet.
  final String watchLine;

  /// The short line that goes on the shareable card.
  final String shareLine;

  /// Who wants it more.
  final DirectionalReading pull;

  /// Who sets the terms.
  final DirectionalReading power;

  /// Both lopsided readings, in display order.
  List<DirectionalReading> get directions => [pull, power];

  /// When it was first revealed.
  final DateTime createdAt;

  /// Identity of this pairing, used for unlock bookkeeping.
  String get id => '${you.key}|${them.key}';

  /// The strongest facet.
  FacetScore get strongest =>
      facets.reduce((a, b) => b.score > a.score ? b : a);

  /// The weakest facet.
  FacetScore get weakest =>
      facets.reduce((a, b) => b.score < a.score ? b : a);

  /// Whether the Moon was part of this reading.
  ///
  /// Read from the two stored birth times rather than saved as its own
  /// field, so an old persisted match answers correctly without a
  /// migration.
  bool get usesMoon => you.birthTime.isKnown && them.birthTime.isKnown;

  /// "Gemini and Leo", for headings.
  String get pairing => '${you.sign.displayName} and ${them.sign.displayName}';
}

/// Everything the compatibility tab remembers between launches.
///
/// One small blob rather than a table: it is read whole on tab open,
/// written whole on reveal, and a free user's copy holds exactly one
/// match. The moment it needs querying it should become a Drift table,
/// and not before.
@MappableClass()
class CompatibilityState with CompatibilityStateMappable {
  /// Creates a state.
  const CompatibilityState({
    this.matches = const [],
    this.revealedIds = const [],
    this.hasSharedInvite = false,
  });

  /// Every match composed so far, newest first.
  final List<CompatibilityMatch> matches;

  /// Ids of matches the user has actually unlocked.
  ///
  /// A list rather than a set because it is persisted as JSON; [revealed]
  /// is what the rest of the app should read.
  final List<String> revealedIds;

  /// Whether they have ever sent an invite.
  final bool hasSharedInvite;

  /// [revealedIds] as a set.
  Set<String> get revealed => revealedIds.toSet();

  /// The stored match for [id], or `null`.
  CompatibilityMatch? matchById(String id) {
    for (final match in matches) {
      if (match.id == id) return match;
    }
    return null;
  }
}
