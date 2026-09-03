import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/services/compatibility_calculator.dart';
import 'package:sanctum/src/domain/services/quiz_flow.dart';

MatchPerson person(String name, DateTime birth, {int? minute}) => MatchPerson(
  name: name,
  birthDate: birth,
  birthTime: BirthTime(minuteOfDay: minute),
);

void main() {
  final ada = DateTime(1994, 7, 3);
  final ben = DateTime(1991, 11, 20);

  group('BirthTime', () {
    test('tells three states apart', () {
      expect(BirthTime.unknown.isKnown, isFalse);
      expect(const BirthTime(minuteOfDay: 0).isKnown, isTrue);
      expect(const BirthTime.at(7, 45).minuteOfDay, 465);
    });

    test('midnight is a real answer, not an absent one', () {
      // The trap this guards: representing "unknown" as 0 minutes would
      // make everyone born just after midnight indistinguishable from
      // everyone who never answered.
      expect(const BirthTime.at(0, 0).isKnown, isTrue);
      expect(const BirthTime.at(0, 0).label, '00:00');
      expect(BirthTime.unknown.label, 'Unknown');
    });

    test('formats on a 24-hour clock', () {
      expect(const BirthTime.at(9, 5).label, '09:05');
      expect(const BirthTime.at(23, 59).label, '23:59');
    });
  });

  group('quiz answers', () {
    test('an unknown time still counts the question as answered', () {
      // Otherwise the flow stalls: "I do not know" would leave the
      // question unanswered forever and re-ask it on every launch.
      const answers = QuizAnswers();
      expect(answers.has('birth_time'), isFalse);

      final answered = answers.withTime('birth_time', BirthTime.unknown);
      expect(answered.has('birth_time'), isTrue);
      expect(answered.birthTime.isKnown, isFalse);
    });

    test('defaults to unknown for anyone who onboarded before it existed', () {
      expect(const QuizAnswers().birthTime.isKnown, isFalse);
    });

    test('clearFrom drops a stranded time with everything else', () {
      const questions = [
        QuizQuestion(
          id: 'birth_time',
          kind: QuizQuestionKind.time,
          title: 'When?',
        ),
      ];
      final answers = const QuizAnswers()
          .withTime('birth_time', const BirthTime.at(9, 0));

      final cleared = QuizFlow.clearFrom(questions, answers, 'birth_time');
      expect(cleared.has('birth_time'), isFalse);
    });

    test('prune drops a time whose question is no longer visible', () {
      const questions = [
        QuizQuestion(
          id: 'goals',
          kind: QuizQuestionKind.multi,
          title: 'Why?',
          options: [QuizOption(id: 'love', label: 'Love')],
        ),
        QuizQuestion(
          id: 'birth_time',
          kind: QuizQuestionKind.time,
          title: 'When?',
          showIf: QuizCondition(questionId: 'goals', anyOf: ['love']),
        ),
      ];

      final answers = const QuizAnswers()
          .withSelection('goals', const [])
          .withTime('birth_time', const BirthTime.at(9, 0));

      expect(QuizFlow.prune(questions, answers).has('birth_time'), isFalse);
    });
  });

  group('MatchPerson', () {
    test('has no Moon without a birth time', () {
      expect(person('Ada', ada).moon, isNull);
      expect(person('Ada', ada).moonSign, isNull);
    });

    test('has a Moon with one', () {
      final withTime = person('Ada', ada, minute: 9 * 60);
      expect(withTime.moon, isNotNull);
      expect(withTime.moonSign, isNotNull);
    });

    test('two birth times are two different charts', () {
      final morning = person('Ada', ada, minute: 2 * 60);
      final night = person('Ada', ada, minute: 22 * 60);
      expect(morning.moon, isNot(closeTo(night.moon!, 1)));
    });

    test('keeps its old key when the time is unknown', () {
      // Backwards compatibility, and it decides whether a user who
      // already paid for a reading still owns it. A changed key is a
      // reading they are asked to unlock a second time.
      expect(person('Ada', ada).key, 'person:ada:1994-7-3');
    });

    test('keys a known time separately', () {
      expect(person('Ada', ada, minute: 540).key, 'person:ada:1994-7-3:540');
      expect(
        person('Ada', ada, minute: 540).key,
        isNot(person('Ada', ada, minute: 541).key),
      );
    });

    test('defaults to unknown when the argument is omitted entirely', () {
      // The default is what every celebrity and every persisted person
      // from before this feature decodes to, so it has to be unknown
      // rather than "some time".
      final celeb = MatchPerson(
        name: 'Someone',
        birthDate: ada,
        celebrityId: 'someone',
      );
      expect(celeb.birthTime.isKnown, isFalse);
      expect(celeb.moon, isNull);
    });
  });

  group('a person survives being carried through a route', () {
    // `MatchResultRoute` rebuilds the second person from loose query
    // parameters, so every field feeding `key` has to make the trip.
    // This is a model-level stand-in for that screen: it is the shape
    // the navigation must preserve, and it caught a real regression
    // where the saved-match list carried the date but not the time.
    MatchPerson throughRoute(MatchPerson original) => MatchPerson(
      name: original.name,
      birthDate: DateTime.parse(
        '${original.birthDate.year.toString().padLeft(4, '0')}-'
        '${original.birthDate.month.toString().padLeft(2, '0')}-'
        '${original.birthDate.day.toString().padLeft(2, '0')}',
      ),
      birthTime: BirthTime(minuteOfDay: original.birthTime.minuteOfDay),
      celebrityId: original.celebrityId,
    );

    test('a known birth time survives the trip', () {
      final original = person('Juju', ben, minute: 805);
      expect(throughRoute(original).key, original.key);
    });

    test('dropping the time changes the key, which is the bug', () {
      // Pinning the failure itself, so the reason the parameter exists
      // cannot be quietly optimised away later.
      final withTime = person('Juju', ben, minute: 805);
      final withoutTime = person('Juju', ben);
      expect(withoutTime.key, isNot(withTime.key));
    });

    test('an unknown time survives too', () {
      final original = person('Juju', ben);
      expect(throughRoute(original).key, original.key);
    });
  });

  group('the Moon enters the model only when both sides have one', () {
    test('one-sided times change nothing at all', () {
      // The important guarantee. A real Moon measured against an
      // invented one would report the difference as a finding about the
      // couple, which is the same failure as inventing a score.
      final base = CompatibilityCalculator.facets(
        person('Ada', ada),
        person('Ben', ben),
      );
      final onlyYou = CompatibilityCalculator.facets(
        person('Ada', ada, minute: 540),
        person('Ben', ben),
      );
      final onlyThem = CompatibilityCalculator.facets(
        person('Ada', ada),
        person('Ben', ben, minute: 540),
      );

      expect(onlyYou.map((f) => f.score), base.map((f) => f.score));
      expect(onlyThem.map((f) => f.score), base.map((f) => f.score));
    });

    test('omitting the time reads the same as declaring it unknown', () {
      // Together with the test above, this is what says a reading
      // composed before the birth time existed still computes to the
      // number the user was originally shown.
      expect(
        CompatibilityCalculator.overall(
          MatchPerson(name: 'Ada', birthDate: ada),
          MatchPerson(name: 'Ben', birthDate: ben),
        ),
        CompatibilityCalculator.overall(
          person('Ada', ada),
          person('Ben', ben),
        ),
      );
    });

    test('two known times do move the reading', () {
      final without = CompatibilityCalculator.facets(
        person('Ada', ada),
        person('Ben', ben),
      );
      final with_ = CompatibilityCalculator.facets(
        person('Ada', ada, minute: 3 * 60),
        person('Ben', ben, minute: 21 * 60),
      );

      expect(with_.map((f) => f.score), isNot(without.map((f) => f.score)));
    });

    test('Spark and Future stay on their own planets', () {
      // Each facet is owned by one contact, and the Moon is not part of
      // desire or of commitment. If these ever move, a weight has been
      // added where the documentation says there is none.
      final without = CompatibilityCalculator.facets(
        person('Ada', ada),
        person('Ben', ben),
      );
      final with_ = CompatibilityCalculator.facets(
        person('Ada', ada, minute: 3 * 60),
        person('Ben', ben, minute: 21 * 60),
      );

      int scoreOf(List<FacetScore> all, CompatibilityFacet facet) =>
          all.firstWhere((f) => f.facet == facet).score;

      for (final facet in [
        CompatibilityFacet.spark,
        CompatibilityFacet.future,
      ]) {
        expect(
          scoreOf(with_, facet),
          scoreOf(without, facet),
          reason: facet.name,
        );
      }
    });

    test('every facet stays inside the published range', () {
      final facets = CompatibilityCalculator.facets(
        person('Ada', ada, minute: 3 * 60),
        person('Ben', ben, minute: 21 * 60),
      );

      for (final facet in facets) {
        expect(
          facet.score,
          inInclusiveRange(
            CompatibilityCalculator.floor,
            CompatibilityCalculator.ceiling,
          ),
          reason: facet.facet.name,
        );
      }
    });

    test('usesMoon reports what the reading actually did', () {
      expect(
        CompatibilityCalculator.usesMoon(
          person('Ada', ada),
          person('Ben', ben),
        ),
        isFalse,
      );
      expect(
        CompatibilityCalculator.usesMoon(
          person('Ada', ada, minute: 540),
          person('Ben', ben),
        ),
        isFalse,
      );
      expect(
        CompatibilityCalculator.usesMoon(
          person('Ada', ada, minute: 540),
          person('Ben', ben, minute: 100),
        ),
        isTrue,
      );
    });
  });
}
