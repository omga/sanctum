import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/quiz.dart';

/// What a stored blob looked like before birth times existed.
///
/// Written out by hand rather than generated, because the whole point is
/// to decode something this build did not produce. If [QuizAnswers]
/// gains a required field, this is the test that fails — and the failure
/// it is standing in for is severe: `PreferencesQuizRepository.load`
/// falls back to an empty answer set on a decode error, so a user who
/// updated the app would be handed onboarding again, with their name,
/// birth date and every answer gone.
const _legacyAnswers = '''
{
  "selections": {"goals": ["love", "calm"], "rhythm": ["morning"]},
  "dates": {"birth_date": "1994-07-03T00:00:00.000"},
  "texts": {"name": "Ada"}
}
''';

const _legacyPerson = '''
{"name": "Ben", "birthDate": "1991-11-20T00:00:00.000"}
''';

void main() {
  _calendarDates();

  group('quiz answers survive the upgrade', () {
    test('a blob written before birth times still decodes', () {
      final answers = QuizAnswersMapper.fromMap(
        jsonDecode(_legacyAnswers) as Map<String, dynamic>,
      );

      expect(answers.name, 'Ada');
      // The legacy blob holds local midnight shifted into UTC. The
      // hook undoes that shift, so the calendar date survives.
      expect(answers.dates['birth_date'], DateTime(1994, 7, 3));
      expect(answers.optionsFor('goals'), ['love', 'calm']);
      expect(answers.times, isEmpty);
      expect(answers.birthTime.isKnown, isFalse);
      // And the question is unanswered, so the flow will ask it once.
      expect(answers.has('birth_time'), isFalse);
    });

    test('a known time round-trips', () {
      final saved = const QuizAnswers()
          .withTime('birth_time', const BirthTime.at(7, 45));
      final restored = QuizAnswersMapper.fromMap(
        jsonDecode(jsonEncode(saved.toMap())) as Map<String, dynamic>,
      );

      expect(restored.birthTime.isKnown, isTrue);
      expect(restored.birthTime.minuteOfDay, 465);
    });

    test('an unknown time round-trips as answered, not as absent', () {
      // The state that a nullable int would have lost. If this decodes
      // back to "no answer", the quiz re-asks the question on every
      // single launch for everyone who said they did not know.
      final saved = const QuizAnswers()
          .withTime('birth_time', BirthTime.unknown);
      final restored = QuizAnswersMapper.fromMap(
        jsonDecode(jsonEncode(saved.toMap())) as Map<String, dynamic>,
      );

      expect(restored.has('birth_time'), isTrue);
      expect(restored.birthTime.isKnown, isFalse);
    });
  });

  group('saved matches survive the upgrade', () {
    test('a person written before birth times still decodes', () {
      // A decode failure here costs a paying user their unlocked
      // readings, so it is worth a test of its own.
      final person = MatchPersonMapper.fromMap(
        jsonDecode(_legacyPerson) as Map<String, dynamic>,
      );

      expect(person.name, 'Ben');
      expect(person.birthTime.isKnown, isFalse);
      expect(person.moon, isNull);
      expect(person.key, 'person:ben:1991-11-20');
    });

    test('a person with a time round-trips, key included', () {
      final saved = MatchPerson(
        name: 'Ada',
        birthDate: DateTime(1994, 7, 3),
        birthTime: const BirthTime.at(9, 0),
      );
      final restored = MatchPersonMapper.fromMap(
        jsonDecode(jsonEncode(saved.toMap())) as Map<String, dynamic>,
      );

      expect(restored.birthTime.minuteOfDay, 540);
      expect(restored.key, saved.key);
      expect(restored.moon, saved.moon);
    });
  });
}

/// Birth dates are calendar dates, and used to lose a day in storage.
///
/// The bug was silent and only visible east of Greenwich, which is where
/// this app's first market is. See `CalendarDateHook`.
void _calendarDates() {
  group('birth dates keep their calendar day', () {
    test('a birth date survives a save and load', () {
      final saved = const QuizAnswers()
          .withDate('birth_date', DateTime(1996, 6, 15));
      final restored = QuizAnswersMapper.fromMap(
        jsonDecode(jsonEncode(saved.toMap())) as Map<String, dynamic>,
      );

      expect(restored.dates['birth_date'], DateTime(1996, 6, 15));
    });

    test('it survives being saved and loaded repeatedly', () {
      // The original bug moved the date by a day on *every* read, so a
      // single round trip understates it. Ten launches, ten days.
      var answers = const QuizAnswers()
          .withDate('birth_date', DateTime(1996, 6, 15));

      for (var i = 0; i < 10; i++) {
        answers = QuizAnswersMapper.fromMap(
          jsonDecode(jsonEncode(answers.toMap())) as Map<String, dynamic>,
        );
      }

      expect(answers.dates['birth_date'], DateTime(1996, 6, 15));
    });

    test('a stored date is written as UTC midnight, not a local instant', () {
      // What makes the stored value independent of where the phone was
      // when it was written.
      final map = const QuizAnswers()
          .withDate('birth_date', DateTime(1996, 6, 15))
          .toMap();
      final dates = map['dates'] as Map<String, dynamic>;

      expect(dates['birth_date'], startsWith('1996-06-15T00:00:00.000'));
    });

    test('a match person keeps its key across a save and load', () {
      // A changed key is a reading the user already unlocked being
      // treated as a new one.
      final saved = MatchPerson(
        name: 'Ada',
        birthDate: DateTime(1994, 7, 3),
        birthTime: const BirthTime.at(9, 0),
      );
      final restored = MatchPersonMapper.fromMap(
        jsonDecode(jsonEncode(saved.toMap())) as Map<String, dynamic>,
      );

      expect(restored.birthDate, saved.birthDate);
      expect(restored.key, saved.key);
      expect(restored.sign, saved.sign);
      expect(restored.moon, saved.moon);
    });

    test('a cusp birthday keeps its sun sign', () {
      // The user-visible face of the bug: 23 August is Virgo, 22 August
      // is Leo, and the app used to change its mind on the second
      // launch.
      final saved = MatchPerson(name: 'Cusp', birthDate: DateTime(1994, 8, 23));
      final restored = MatchPersonMapper.fromMap(
        jsonDecode(jsonEncode(saved.toMap())) as Map<String, dynamic>,
      );

      expect(restored.sign, saved.sign);
    });
  });
}
