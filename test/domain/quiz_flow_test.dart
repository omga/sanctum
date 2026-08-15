import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/services/quiz_flow.dart';

const _questions = <QuizQuestion>[
  QuizQuestion(
    id: 'focus',
    kind: QuizQuestionKind.single,
    title: 'What brought you here?',
    options: [
      QuizOption(id: 'love', label: 'Love'),
      QuizOption(id: 'calm', label: 'Calm'),
    ],
  ),
  QuizQuestion(
    id: 'status',
    kind: QuizQuestionKind.single,
    title: 'Where are you with it?',
    showIf: QuizCondition(questionId: 'focus', anyOf: ['love']),
    options: [
      QuizOption(id: 'single', label: 'Single'),
      QuizOption(id: 'together', label: 'With someone'),
    ],
  ),
  QuizQuestion(
    id: 'together_since',
    kind: QuizQuestionKind.date,
    title: 'Since when?',
    showIf: QuizCondition(questionId: 'status', anyOf: ['together']),
  ),
  QuizQuestion(
    id: 'birth',
    kind: QuizQuestionKind.date,
    title: 'When were you born?',
  ),
];

List<String> visibleIds(QuizAnswers answers) =>
    QuizFlow.visible(_questions, answers).map((q) => q.id).toList();

void main() {
  group('visibility', () {
    test('unconditional questions are always shown', () {
      expect(visibleIds(const QuizAnswers()), ['focus', 'birth']);
    });

    test('a branch opens when its condition is met', () {
      final answers = const QuizAnswers().withSelection('focus', ['love']);
      expect(visibleIds(answers), ['focus', 'status', 'birth']);
    });

    test('a branch stays closed when it is not', () {
      final answers = const QuizAnswers().withSelection('focus', ['calm']);
      expect(visibleIds(answers), ['focus', 'birth']);
    });

    test('nested branches need their whole chain', () {
      final answers = const QuizAnswers()
          .withSelection('focus', ['love'])
          .withSelection('status', ['together']);
      expect(visibleIds(answers), [
        'focus',
        'status',
        'together_since',
        'birth',
      ]);
    });

    test('a branch cannot resurrect through a hidden parent', () {
      // 'status' is hidden because focus=calm, so 'together_since' must
      // stay hidden even though a stale answer to 'status' survives.
      final answers = const QuizAnswers()
          .withSelection('focus', ['calm'])
          .withSelection('status', ['together']);
      expect(visibleIds(answers), ['focus', 'birth']);
    });
  });

  group('next question', () {
    test('walks visible questions in order', () {
      var answers = const QuizAnswers();
      expect(QuizFlow.next(_questions, answers)?.id, 'focus');

      answers = answers.withSelection('focus', ['love']);
      expect(QuizFlow.next(_questions, answers)?.id, 'status');

      answers = answers.withSelection('status', ['single']);
      expect(QuizFlow.next(_questions, answers)?.id, 'birth');
    });

    test('skipping a closed branch does not skip the question after it', () {
      // The bug an index++ implementation makes: hiding 'status' must
      // advance to 'birth', not past it.
      final answers = const QuizAnswers().withSelection('focus', ['calm']);
      expect(QuizFlow.next(_questions, answers)?.id, 'birth');
    });

    test('returns null and reports complete once all are answered', () {
      final answers = const QuizAnswers()
          .withSelection('focus', ['calm'])
          .withDate('birth', DateTime(1996, 4, 2));

      expect(QuizFlow.next(_questions, answers), isNull);
      expect(QuizFlow.isComplete(_questions, answers), isTrue);
    });

    test('opening a branch makes a complete quiz incomplete again', () {
      var answers = const QuizAnswers()
          .withSelection('focus', ['calm'])
          .withDate('birth', DateTime(1996, 4, 2));
      expect(QuizFlow.isComplete(_questions, answers), isTrue);

      answers = answers.withSelection('focus', ['love']);
      expect(QuizFlow.isComplete(_questions, answers), isFalse);
      expect(QuizFlow.next(_questions, answers)?.id, 'status');
    });
  });

  group('progress', () {
    test('runs from zero to one', () {
      expect(QuizFlow.progress(_questions, const QuizAnswers()), 0);

      final done = const QuizAnswers()
          .withSelection('focus', ['calm'])
          .withDate('birth', DateTime(1996, 4, 2));
      expect(QuizFlow.progress(_questions, done), 1);
    });

    test('never exceeds one when a branch closes', () {
      // Answer into a branch, then close it. Stale answers must not push
      // progress above 100%.
      var answers = const QuizAnswers()
          .withSelection('focus', ['love'])
          .withSelection('status', ['together'])
          .withDate('together_since', DateTime(2024))
          .withDate('birth', DateTime(1996, 4, 2));
      expect(QuizFlow.progress(_questions, answers), 1);

      answers = answers.withSelection('focus', ['calm']);
      expect(QuizFlow.progress(_questions, answers), lessThanOrEqualTo(1));
    });
  });

  group('changing an earlier answer', () {
    test('clears the answer and everything downstream of it', () {
      final answers = const QuizAnswers()
          .withSelection('focus', ['love'])
          .withSelection('status', ['together'])
          .withDate('together_since', DateTime(2024))
          .withDate('birth', DateTime(1996, 4, 2));

      final cleared = QuizFlow.clearFrom(_questions, answers, 'focus');

      expect(cleared.has('focus'), isFalse);
      expect(
        cleared.has('status'),
        isFalse,
        reason: 'orphaned branch answer must go',
      );
      expect(
        cleared.has('together_since'),
        isFalse,
        reason: 'nested orphan must go too',
      );
      expect(
        cleared.has('birth'),
        isTrue,
        reason: 'unrelated answers are kept',
      );
    });

    test('a cleared quiz is no longer complete', () {
      final answers = const QuizAnswers()
          .withSelection('focus', ['calm'])
          .withDate('birth', DateTime(1996, 4, 2));

      final cleared = QuizFlow.clearFrom(_questions, answers, 'focus');
      expect(QuizFlow.isComplete(_questions, cleared), isFalse);
    });
  });
}
