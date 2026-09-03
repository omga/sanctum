import 'package:dart_mappable/dart_mappable.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/planet.dart';

part 'transit.mapper.dart';

/// The angle a transit makes.
@MappableEnum()
enum TransitAspect {
  /// Same degree. Fusion — the loudest of them.
  conjunction(0, 'meets', hard: true),

  /// 60°. Easy, and easily missed.
  sextile(60, 'supports', hard: false),

  /// 90°. Friction that forces a decision.
  square(90, 'presses on', hard: true),

  /// 120°. Flowing, sometimes to the point of laziness.
  trine(120, 'flows with', hard: false),

  /// 180°. Pulled in two directions at once.
  opposition(180, 'pulls against', hard: true);

  const TransitAspect(this.angle, this.verb, {required this.hard});

  /// Exact separation, in degrees.
  final int angle;

  /// Reads as `Mars <verb> your Venus`.
  final String verb;

  /// Whether this one is felt as pressure rather than as ease.
  final bool hard;

  /// Relative significance.
  double get weight => switch (this) {
    TransitAspect.conjunction => 1.2,
    TransitAspect.opposition => 1.1,
    TransitAspect.square => 1.05,
    TransitAspect.trine => 1.0,
    TransitAspect.sextile => 0.85,
  };
}

/// One planet in the sky today, touching one planet in a birth chart.
///
/// This is what a horoscope actually is, as opposed to the newspaper
/// version: not "Geminis will have a good day" but "Mars is at 14° Libra
/// today and your Venus is at 15° Capricorn, so those two are square".
/// It is different every day because the sky moved, and different for
/// every user because their chart is theirs.
@MappableClass()
class Transit with TransitMappable {
  /// Creates a transit.
  const Transit({
    required this.transiting,
    required this.natal,
    required this.aspect,
    required this.orb,
    required this.retrograde,
  });

  /// The body in the sky now.
  final Planet transiting;

  /// The body in the birth chart it is touching.
  final Planet natal;

  /// The angle between them.
  final TransitAspect aspect;

  /// Degrees away from exact. Smaller is stronger.
  final double orb;

  /// Whether the transiting body is retrograde.
  final bool retrograde;

  /// `1.0` at exact, falling to `0.0` at the edge of the orb.
  double get tightness => (1 - orb / transiting.orb).clamp(0.0, 1.0);

  /// Ranking score. Exactness first, then how much the body matters.
  double get significance =>
      tightness * transiting.weight * aspect.weight;

  /// Whether this is within half a degree of exact.
  bool get isExact => orb <= 0.5;

  /// "Mars presses on your Venus", in the language of [copy].
  ///
  /// ## Why the natal body has its own key
  ///
  /// English needs one word per planet and glues "your" on the front.
  /// Ukrainian and Russian cannot: the possessive agrees with the
  /// planet's gender (твій Марс, твоя Венера, твоє Сонце) *and* the
  /// verb governs a case, so "your Venus" is four different phrases
  /// depending on where it lands. The first draft of this template read
  /// "САТУРН ТИСНЕ НА ТВІЙ ВЕНЕРА", which is the kind of wrong that
  /// tells a reader immediately that nobody speaking their language
  /// looked at it.
  ///
  /// So `transit.natal.*` carries the whole phrase — possessive,
  /// gender and case already correct — and the verbs are chosen in
  /// every language to govern one single case, so six forms are enough
  /// instead of one per verb-and-planet pair.
  String headlineIn(CopyBook copy) => copy.format('transit.headline', {
    'transiting': copy.get('planet.${transiting.name}'),
    'verb': copy.get('transit.verb.${aspect.name}'),
    'natal': copy.get('transit.natal.${natal.name}'),
  });
}

/// Everything the home screen says about today.
///
/// Not persisted — it is recomputed from the birth date and the date, so
/// there is nothing to migrate and nothing that can go stale.
class DailyTransitReading {
  /// Creates a reading.
  const DailyTransitReading({
    required this.line,
    required this.headline,
    required this.retrogrades,
    this.transit,
    this.tomorrow,
    this.retrogradeNote,
  });

  /// The transit being described, or `null` on a quiet day.
  final Transit? transit;

  /// The reading itself.
  final String line;

  /// The transit as a phrase — "Mars presses on your Venus" — or the
  /// quiet-sky line when nothing is in orb.
  ///
  /// Composed here rather than built in the widget. Reaching for the
  /// copy book from a widget means reaching for it *asynchronously*,
  /// and the first frame renders before it arrives.
  final String headline;

  /// What arrives tomorrow, when it differs from today.
  ///
  /// The only honest open loop this app has. A daily card cannot promise
  /// anything about tomorrow because it is a hash; a transit can, because
  /// the sky is on rails.
  final String? tomorrow;

  /// Bodies currently retrograde.
  final List<Planet> retrogrades;

  /// The line about the most legible retrograde, if any.
  final String? retrogradeNote;

  /// Whether there is a real transit behind this reading.
  bool get isPersonal => transit != null;
}
