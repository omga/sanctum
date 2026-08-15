import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/reading_composer.dart';

QuizAnswers answers({
  String? name,
  DateTime? birth,
  List<String> goals = const ['love'],
  List<String> weight = const ['repeating'],
  List<String> commitment = const ['daily'],
}) {
  var result = const QuizAnswers()
      .withSelection('goals', goals)
      .withSelection('weight', weight)
      .withSelection('commitment', commitment);
  if (name != null) result = result.withText('name', name);
  if (birth != null) result = result.withDate('birth_date', birth);
  return result;
}

void main() {
  group('composition', () {
    test('every line is keyed to something the user answered', () {
      final reading = ReadingComposer.compose(
        answers(
          name: 'Andrii',
          birth: DateTime(1996, 6, 15),
          goals: ['clarity'],
          weight: ['drained'],
          commitment: ['most'],
        ),
      );

      expect(reading.name, 'Andrii');
      expect(reading.sign, ZodiacSign.gemini);
      expect(reading.opening, ReadingComposer.openings[ZodiacElement.air]);
      expect(reading.recognition, ReadingComposer.recognitions['drained']);
      expect(reading.intention, ReadingComposer.intentions['clarity']);
      expect(reading.closing, ReadingComposer.commitments['most']);
    });

    test('is deterministic — same answers, same reading', () {
      final a = ReadingComposer.compose(answers(birth: DateTime(1990, 8, 3)));
      final b = ReadingComposer.compose(answers(birth: DateTime(1990, 8, 3)));

      expect(a.headline, b.headline);
      expect(a.recognition, b.recognition);
      expect(a.opening, b.opening);
    });

    test('leads with the first admitted weight, not all of them', () {
      // Stacking every weight turns a reading into a list of grievances.
      final reading = ReadingComposer.compose(
        answers(weight: ['letting_go', 'racing', 'stuck']),
      );
      expect(reading.recognition, ReadingComposer.recognitions['letting_go']);
    });
  });

  group('headline', () {
    test('addresses them by name when given', () {
      final reading = ReadingComposer.compose(
        answers(name: 'Mia', birth: DateTime(1991)),
      );
      expect(reading.headline, startsWith('Mia, you are a Capricorn'));
    });

    test('still reads properly without a name', () {
      final reading = ReadingComposer.compose(answers(birth: DateTime(1991)));
      expect(reading.headline, 'You are a Capricorn.');
    });

    test('uses the right article for vowel signs', () {
      // "a Aries" is the kind of thing that undoes a premium feel.
      final aries = ReadingComposer.compose(
        answers(birth: DateTime(1990, 4, 1)),
      );
      final taurus = ReadingComposer.compose(
        answers(birth: DateTime(1990, 5, 1)),
      );

      expect(aries.headline, contains('an Aries'));
      expect(taurus.headline, contains('a Taurus'));
    });
  });

  group('robustness', () {
    test('survives a completely empty answer set', () {
      final reading = ReadingComposer.compose(const QuizAnswers());

      expect(reading.headline, isNotEmpty);
      expect(reading.opening, isNotEmpty);
      expect(reading.recognition, isNull);
      expect(reading.hasBirthDate, isFalse);
    });

    test('flags a fallback sign rather than passing it off as theirs', () {
      // Presenting a default sign as the user's own would make the whole
      // screen a lie, so the UI needs to know.
      expect(
        ReadingComposer.compose(const QuizAnswers()).hasBirthDate,
        isFalse,
      );
      expect(
        ReadingComposer.compose(answers(birth: DateTime(1996, 6, 15)))
            .hasBirthDate,
        isTrue,
      );
    });

    test('unknown option ids degrade to nothing, not to a crash', () {
      final reading = ReadingComposer.compose(
        answers(goals: ['nonsense'], weight: ['also_nonsense']),
      );
      expect(reading.recognition, isNull);
      expect(reading.intention, isNull);
    });
  });

  test('every option in the shipped quiz has copy written for it', () {
    // Content drift guard. Adding an option to the JSON without adding a
    // line here produces a reading with a silent hole in it, which is
    // invisible until a real user picks exactly that option.
    final raw = File('assets/content/onboarding_quiz.json').readAsStringSync();
    final questions =
        (jsonDecode(raw) as Map<String, dynamic>)['questions'] as List;

    final missing = <String>[];
    for (final question in questions.cast<Map<String, dynamic>>()) {
      final copy = switch (question['id'] as String) {
        'weight' => ReadingComposer.recognitions,
        'goals' => ReadingComposer.intentions,
        'commitment' => ReadingComposer.commitments,
        _ => null,
      };
      if (copy == null) continue;

      for (final option
          in (question['options'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
        final id = option['id'] as String;
        if (!copy.containsKey(id)) {
          missing.add('${question['id']}.$id');
        }
      }
    }

    expect(missing, isEmpty, reason: 'no reading copy for: $missing');
  });

  test('every element has an opening', () {
    for (final element in ZodiacElement.values) {
      expect(ReadingComposer.openings[element], isNotNull);
    }
  });
}
