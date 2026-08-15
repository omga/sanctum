import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/services/quiz_flow.dart';

part 'quiz_view_model.g.dart';

/// Where the user is in the quiz.
class QuizUiState {
  /// Creates the state.
  const QuizUiState({
    required this.questions,
    required this.answers,
    required this.current,
    required this.progress,
    required this.canGoBack,
    required this.isComplete,
  });

  /// Every question in the catalogue, including hidden ones.
  final List<QuizQuestion> questions;

  /// What the user has answered so far.
  final QuizAnswers answers;

  /// The question on screen, or `null` when the quiz is finished.
  final QuizQuestion? current;

  /// Progress through the visible questions, `0.0`–`1.0`.
  final double progress;

  /// Whether there is an earlier question to return to.
  final bool canGoBack;

  /// Whether every visible question has been answered.
  final bool isComplete;
}

/// Drives the onboarding quiz.
///
/// Holds the answers and a cursor. The cursor exists because
/// [QuizFlow.next] only ever points at the first *unanswered* question,
/// which is the right answer going forwards and useless going back — a
/// user reviewing an earlier answer needs to sit on a question that is
/// already answered.
@riverpod
class QuizController extends _$QuizController {
  String? _cursorId;

  @override
  Future<QuizUiState> build() async {
    final catalog = await ref.watch(contentCatalogProvider.future);
    final loaded = await ref.watch(quizRepositoryProvider).load();

    // A corrupt blob must not brick onboarding, so a failure here starts
    // the user from an empty answer set rather than an error screen.
    final answers = loaded.getOrElse(const QuizAnswers());

    return _stateFor(catalog.quizQuestions, answers);
  }

  QuizUiState _stateFor(List<QuizQuestion> questions, QuizAnswers answers) {
    final visible = QuizFlow.visible(questions, answers);
    final next = QuizFlow.next(questions, answers);

    // Keep sitting on the cursor if it is still a visible question,
    // otherwise fall through to wherever the flow wants us.
    final cursor = _cursorId;
    final current = cursor != null
        ? visible.where((q) => q.id == cursor).firstOrNull ?? next
        : next;

    final index = current == null ? visible.length : visible.indexOf(current);

    return QuizUiState(
      questions: questions,
      answers: answers,
      current: current,
      progress: QuizFlow.progress(questions, answers),
      canGoBack: index > 0,
      isComplete: QuizFlow.isComplete(questions, answers),
    );
  }

  Future<void> _apply(QuizAnswers answers, {String? cursorId}) async {
    final current = state.value;
    if (current == null) return;

    _cursorId = cursorId;
    state = AsyncData(_stateFor(current.questions, answers));
    await ref.read(quizRepositoryProvider).save(answers);
  }

  /// Records a choice for [questionId] and advances.
  Future<void> choose(String questionId, List<String> optionIds) async {
    final current = state.value;
    if (current == null) return;

    // Re-answering an earlier question invalidates anything that
    // branched off it, so drop those rather than carrying stale replies
    // into the paywall.
    final base = current.answers.has(questionId)
        ? QuizFlow.clearFrom(current.questions, current.answers, questionId)
        : current.answers;

    await _apply(base.withSelection(questionId, optionIds));
  }

  /// Records a date for [questionId] and advances.
  Future<void> chooseDate(String questionId, DateTime date) async {
    final current = state.value;
    if (current == null) return;
    await _apply(current.answers.withDate(questionId, date));
  }

  /// Records free text for [questionId] and advances.
  Future<void> chooseText(String questionId, String value) async {
    final current = state.value;
    if (current == null) return;
    await _apply(current.answers.withText(questionId, value.trim()));
  }

  /// Acknowledges an interstitial.
  ///
  /// Interstitials have nothing to answer, so they are marked seen. Left
  /// unrecorded they would never satisfy [QuizFlow.next] and the flow
  /// would stall on them forever.
  Future<void> acknowledge(String questionId) =>
      choose(questionId, const ['seen']);

  /// Steps back to the previous visible question.
  Future<void> back() async {
    final current = state.value;
    if (current == null) return;

    final visible = QuizFlow.visible(current.questions, current.answers);
    final showing = current.current;
    final index = showing == null ? visible.length : visible.indexOf(showing);
    if (index <= 0) return;

    await _apply(current.answers, cursorId: visible[index - 1].id);
  }

  /// Marks the quiz finished.
  Future<void> finish() async {
    await ref.read(quizRepositoryProvider).markComplete();
  }
}
