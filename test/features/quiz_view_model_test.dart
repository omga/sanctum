import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/analytics/analytics_service.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/quiz_repository.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/oracle_card.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/features/quiz/view_model/quiz_view_model.dart';

class _Quiz implements QuizRepository {
  QuizAnswers saved = const QuizAnswers();
  bool completed = false;

  @override
  Future<Result<QuizAnswers>> load() async => Result.ok(saved);

  @override
  Future<Result<void>> save(QuizAnswers answers) async {
    saved = answers;
    return const Result.ok(null);
  }

  @override
  Future<Result<bool>> isComplete() async => Result.ok(completed);

  @override
  Future<Result<void>> markComplete() async {
    completed = true;
    return const Result.ok(null);
  }
}

/// The shape that matters: a multi-select that opens a branch, followed
/// by questions the flow must not jump to on the first tick.
const _questions = <QuizQuestion>[
  QuizQuestion(
    id: 'goals',
    kind: QuizQuestionKind.multi,
    title: 'What are you here for?',
    options: [
      QuizOption(id: 'love', label: 'Love and relationships'),
      QuizOption(id: 'calm', label: 'Quiet in my own head'),
      QuizOption(id: 'purpose', label: 'Where my life is going'),
    ],
  ),
  QuizQuestion(
    id: 'love_status',
    kind: QuizQuestionKind.single,
    title: 'Where are you with it?',
    showIf: QuizCondition(questionId: 'goals', anyOf: ['love']),
    options: [
      QuizOption(id: 'single', label: 'On my own'),
      QuizOption(id: 'together', label: 'With someone'),
    ],
  ),
  QuizQuestion(
    id: 'weight',
    kind: QuizQuestionKind.multi,
    title: 'What is heaviest right now?',
    options: [
      QuizOption(id: 'racing', label: 'My mind will not slow down'),
      QuizOption(id: 'stuck', label: 'I freeze and do nothing'),
    ],
  ),
  QuizQuestion(
    id: 'birth_date',
    kind: QuizQuestionKind.date,
    title: 'When were you born?',
  ),
];

ContentCatalog _catalog() => const ContentCatalog(
  oracleCards: <OracleCard>[],
  sessions: <SoundSession>[],
  affirmations: <String>[],
  rituals: <Ritual>[],
  quizQuestions: _questions,
  celebrities: <Celebrity>[],
);

void main() {
  late _Quiz repository;
  late RecordingAnalyticsService analytics;

  ProviderContainer makeContainer() {
    repository = _Quiz();
    analytics = RecordingAnalyticsService();
    final container = ProviderContainer(
      overrides: [
        contentCatalogProvider.overrideWith((ref) async => _catalog()),
        quizRepositoryProvider.overrideWithValue(repository),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
    // The controller is auto-dispose: without a listener it is thrown
    // away between reads and the next action throws.
    container.listen(quizControllerProvider, (_, _) {});
    return container;
  }

  Future<QuizController> controllerFor(ProviderContainer container) async {
    await container.read(quizControllerProvider.future);
    return container.read(quizControllerProvider.notifier);
  }

  QuizUiState stateOf(ProviderContainer container) =>
      container.read(quizControllerProvider).requireValue;

  group('multi-select', () {
    test('ticking one option does not advance', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');

      expect(
        stateOf(container).current?.id,
        'goals',
        reason: 'a multi-select question is not finished by its first tick',
      );
      expect(stateOf(container).answers.optionsFor('goals'), ['love']);
    });

    test('ticks accumulate', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.toggle('goals', 'calm');
      await controller.toggle('goals', 'purpose');

      expect(stateOf(container).current?.id, 'goals');
      expect(stateOf(container).answers.optionsFor('goals'), [
        'love',
        'calm',
        'purpose',
      ]);
    });

    test('ticking twice unticks', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.toggle('goals', 'calm');
      await controller.toggle('goals', 'love');

      expect(stateOf(container).answers.optionsFor('goals'), ['calm']);
      expect(stateOf(container).current?.id, 'goals');
    });

    test('Continue is what moves the flow on', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.advance();

      expect(stateOf(container).current?.id, 'love_status');
    });

    test('the later multi-select behaves the same way', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'calm');
      await controller.advance();
      expect(stateOf(container).current?.id, 'weight');

      await controller.toggle('weight', 'racing');
      expect(stateOf(container).current?.id, 'weight');

      await controller.advance();
      expect(stateOf(container).current?.id, 'birth_date');
    });

    test('every tick is persisted', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.toggle('goals', 'calm');

      expect(repository.saved.optionsFor('goals'), ['love', 'calm']);
    });

    test('unticking closes the branch it opened', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.advance();
      await controller.choose('love_status', ['together']);

      // Back to the goals question, and love comes off.
      await controller.back();
      await controller.back();
      await controller.toggle('goals', 'love');

      expect(stateOf(container).current?.id, 'goals');
      expect(
        stateOf(container).answers.has('love_status'),
        isFalse,
        reason: 'an answer to a question no longer asked must not survive',
      );
    });

    test('confirming an unchanged selection keeps the branch answer', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.advance();
      await controller.choose('love_status', ['together']);

      await controller.back();
      await controller.back();
      await controller.advance();

      expect(
        stateOf(container).answers.optionsFor('love_status'),
        ['together'],
        reason: 'passing back through a question unchanged must not wipe it',
      );
    });
  });

  group('single select', () {
    test('still answers and advances on the tap', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.advance();
      await controller.choose('love_status', ['single']);

      expect(stateOf(container).current?.id, 'weight');
      expect(stateOf(container).answers.optionsFor('love_status'), ['single']);
    });
  });

  group('analytics', () {
    test('reports each question once as it appears', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.toggle('goals', 'calm');
      await controller.toggle('goals', 'purpose');

      // Three ticks on one question is one question, not three views.
      // Reporting per rebuild would inflate the denominator of the only
      // funnel anybody wants to read.
      final shown = analytics.events
          .where((e) => e.name == 'quiz_question_shown')
          .toList();
      expect(shown, hasLength(1));
      expect(shown.single.properties['question_id'], 'goals');
      expect(shown.single.properties['index'], 0);
    });

    test('reports the next question when the flow moves on', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.advance();

      expect(
        analytics.events
            .where((e) => e.name == 'quiz_question_shown')
            .map((e) => e.properties['question_id']),
        ['goals', 'love_status'],
      );
    });

    test('pairs an answered event with each question', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');
      await controller.advance();
      await controller.choose('love_status', ['single']);

      expect(
        analytics.events
            .where((e) => e.name == 'quiz_question_answered')
            .map((e) => e.properties['question_id']),
        ['goals', 'love_status'],
      );
    });

    test('does not report an answer for a mere tick', () async {
      // Ticking is not finishing. If a tick counted as answered, every
      // multi-select would look like it converted perfectly.
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'love');

      expect(analytics.names, isNot(contains('quiz_question_answered')));
    });

    test('never sends the free-text answer, only its question id', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.chooseText('name', 'Omar');

      for (final event in analytics.events) {
        for (final value in event.properties.values) {
          expect(value, isNot('Omar'));
        }
      }
      expect(
        analytics.events
            .where((e) => e.name == 'quiz_question_answered')
            .map((e) => e.properties['question_id']),
        contains('name'),
      );
    });

    test('reports completion with the number of visible questions', () async {
      final container = makeContainer();
      final controller = await controllerFor(container);

      await controller.toggle('goals', 'calm');
      await controller.advance();
      await controller.toggle('weight', 'racing');
      await controller.advance();
      await controller.chooseDate('birth_date', DateTime(1996, 6, 15));
      await controller.finish();

      final completed = analytics.events
          .where((e) => e.name == 'quiz_completed')
          .single;
      // 'calm' does not open the love branch, so three of the four.
      expect(completed.properties['answered'], 3);
    });
  });
}
