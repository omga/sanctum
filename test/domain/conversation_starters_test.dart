import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/planet.dart';
import 'package:sanctum/src/domain/models/transit.dart';
import 'package:sanctum/src/domain/services/conversation_starters.dart';

CompatibilityMatch _match({
  required List<int> facetScores,
  int pullShare = 50,
  int powerShare = 50,
}) => CompatibilityMatch(
  you: MatchPerson(name: 'You', birthDate: DateTime(1996, 6, 15)),
  them: MatchPerson(name: 'Them', birthDate: DateTime(1994, 11, 2)),
  aspect: ZodiacAspect.trine,
  overall: 70,
  facets: [
    for (var i = 0; i < facetScores.length; i++)
      FacetScore(
        facet: CompatibilityFacet.values[i],
        score: facetScores[i],
      ),
  ],
  verdict: 'Strong',
  dynamicLine: '',
  elementLine: '',
  worksLine: '',
  watchLine: '',
  shareLine: '',
  pull: DirectionalReading(
    kind: DirectionKind.pull,
    yourShare: pullShare,
    line: '',
  ),
  power: DirectionalReading(
    kind: DirectionKind.power,
    yourShare: powerShare,
    line: '',
  ),
  createdAt: DateTime(2026, 9, 5),
);

List<StarterKind> _kinds(CompatibilityMatch match) =>
    ConversationStarters.forMatch(match).map((s) => s.kind).toList();

void main() {
  group('a low facet', () {
    test('is offered first, and names the weakest one', () {
      final starters = ConversationStarters.forMatch(
        _match(facetScores: [80, 41, 75, 60, 90, 70]),
      );
      expect(starters.first.kind, StarterKind.lowFacet);
      // The weakest, not merely a low one — the question is "why is
      // *this* number what it is".
      expect(starters.first.facet, CompatibilityFacet.values[1]);
    });

    test('is not offered when nothing is actually low', () {
      // On a strong pairing the lowest facet is still good, and asking
      // "why is Depth only 71" invents a worry the reading never raised.
      expect(
        _kinds(_match(facetScores: [88, 90, 84, 79, 92, 86])),
        isNot(contains(StarterKind.lowFacet)),
      );
    });
  });

  group('a lopsided split', () {
    test('is offered when it is strong enough to be the story', () {
      final kinds = _kinds(
        _match(facetScores: [80, 80, 80, 80, 80, 80], pullShare: 25),
      );
      expect(kinds, contains(StarterKind.pullThem));
    });

    test('names the right side', () {
      final yours = _kinds(
        _match(facetScores: [80, 80, 80, 80, 80, 80], pullShare: 75),
      );
      expect(yours, contains(StarterKind.pullYou));
      expect(yours, isNot(contains(StarterKind.pullThem)));
    });

    test('is ignored when the split is close to even', () {
      final kinds = _kinds(
        _match(facetScores: [80, 80, 80, 80, 80, 80], pullShare: 56),
      );
      expect(kinds, isNot(contains(StarterKind.pullThem)));
      expect(kinds, isNot(contains(StarterKind.pullYou)));
    });

    test('uses the same threshold as the card and the report', () {
      // One constant, so the three surfaces cannot describe the same
      // split differently.
      const atThreshold = 50 + DirectionalReading.strongTolerance;
      expect(
        _kinds(
          _match(facetScores: [80, 80, 80, 80, 80, 80],
              pullShare: atThreshold),
        ),
        contains(StarterKind.pullYou),
      );
      expect(
        _kinds(
          _match(facetScores: [80, 80, 80, 80, 80, 80],
              pullShare: atThreshold - 1),
        ),
        isNot(contains(StarterKind.pullYou)),
      );
    });
  });

  group('ordering and limit', () {
    test('is most-specific-first', () {
      // Specificity is the difference between this and a generic
      // wrapper, so the named number leads and "anything" trails.
      final kinds = _kinds(
        _match(facetScores: [80, 30, 80, 80, 80, 80], pullShare: 20),
      );
      expect(kinds, [
        StarterKind.lowFacet,
        StarterKind.pullThem,
        StarterKind.anything,
      ]);
    });

    test('never offers more than fits above a keyboard', () {
      final crowded = _kinds(
        _match(facetScores: [30, 30, 30, 30, 30, 30],
            pullShare: 20, powerShare: 80),
      );
      expect(crowded, hasLength(ConversationStarters.limit));
    });

    test('always offers a way out of the suggestions', () {
      // A user whose question is not on the list must still be able to
      // ask it, and the row is where they look first.
      expect(
        _kinds(_match(facetScores: [88, 90, 84, 79, 92, 86])),
        contains(StarterKind.anything),
      );
    });

    test('is deterministic', () {
      final match = _match(facetScores: [80, 41, 75, 60, 90, 70]);
      expect(_kinds(match), _kinds(match));
    });
  });

  group('today', () {
    test('asks about the transit when there is one', () {
      final kinds = ConversationStarters.forToday(
        const DailyTransitReading(
          transit: Transit(
            transiting: Planet.saturn,
            natal: Planet.venus,
            aspect: TransitAspect.square,
            orb: 1.4,
            retrograde: false,
          ),
          line: '',
          headline: '',
          retrogrades: [],
        ),
      ).map((s) => s.kind);
      expect(kinds, contains(StarterKind.transitToday));
    });

    test('has something to ask on a quiet day too', () {
      // The app admits quiet days. Offering no questions on one would
      // make that honesty read as the app having nothing to say.
      final kinds = ConversationStarters.forToday(
        const DailyTransitReading(line: '', headline: '', retrogrades: []),
      ).map((s) => s.kind);
      expect(kinds, contains(StarterKind.quietDay));
    });
  });

  group('copy keys', () {
    test('a starter has a display form and a neutral sent form', () {
      // The whole name-stays-local design: the user reads "Alex", the
      // model is told "them", and these are two written strings rather
      // than one string and a regex.
      const starter = ConversationStarter(StarterKind.pullThem);
      expect(starter.displayKey, 'advisor.starter.pullThem');
      expect(starter.promptKey, 'advisor.prompt.pullThem');
      expect(starter.displayKey, isNot(starter.promptKey));
    });

    test('every kind produces both', () {
      for (final kind in StarterKind.values) {
        final starter = ConversationStarter(kind);
        expect(starter.displayKey, endsWith(kind.name));
        expect(starter.promptKey, endsWith(kind.name));
      }
    });
  });
}
