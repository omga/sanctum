import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/core_providers.dart';
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
  String? _reportedId;

  @override
  Future<QuizUiState> build() async {
    final catalog = await ref.watch(contentCatalogProvider.future);
    final loaded = await ref.watch(quizRepositoryProvider).load();

    // A corrupt blob must not brick onboarding, so a failure here starts
    // the user from an empty answer set rather than an error screen.
    final answers = loaded.getOrElse(const QuizAnswers());

    final state = _stateFor(catalog.quizQuestions, answers);
    _reportShown(state);
    return state;
  }

  /// Emits `quiz_question_shown` when the question on screen changes.
  ///
  /// Reported here rather than from the widget because the widget
  /// rebuilds for reasons that are not a new question — a toggle, a
  /// keyboard, a theme change — and each of those would inflate the
  /// denominator of the only funnel anybody actually wants to read.
  void _reportShown(QuizUiState state) {
    final question = state.current;
    if (question == null || question.id == _reportedId) return;
    _reportedId = question.id;

    final visible = QuizFlow.visible(state.questions, state.answers);
    ref
        .read(analyticsProvider)
        .track(
          AnalyticsEvent.quizQuestionShown(
            questionId: question.id,
            index: visible.indexOf(question),
          ),
        );
  }

  void _reportAnswered(String questionId) {
    final current = state.value;
    if (current == null) return;

    final visible = QuizFlow.visible(current.questions, current.answers);
    ref
        .read(analyticsProvider)
        .track(
          AnalyticsEvent.quizQuestionAnswered(
            questionId: questionId,
            index: visible.indexWhere((q) => q.id == questionId),
          ),
        );
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
    final next = _stateFor(current.questions, answers);
    state = AsyncData(next);
    _reportShown(next);
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

    _reportAnswered(questionId);
    await _apply(base.withSelection(questionId, optionIds));
  }

  /// Toggles [optionId] on a multi-select question, staying put.
  ///
  /// Ticking must not advance: a multi-select question is only finished
  /// when the user presses Continue. Pinning the cursor to [questionId]
  /// is what stops [QuizFlow.next] — which counts the question as
  /// answered the moment the first option lands — from sliding the user
  /// onto the next screen mid-answer.
  Future<void> toggle(String questionId, String optionId) async {
    final current = state.value;
    if (current == null) return;

    final chosen = [...current.answers.optionsFor(questionId)];
    chosen.contains(optionId)
        ? chosen.remove(optionId)
        : chosen.add(optionId);

    // Unticking can close a branch the user already answered, so drop
    // the orphans now rather than carrying them into the payoff.
    final answers = QuizFlow.prune(
      current.questions,
      current.answers.withSelection(questionId, chosen),
    );

    await _apply(answers, cursorId: questionId);
  }

  /// Leaves the question on screen for whatever comes next.
  ///
  /// Used by Continue on questions that record their answer as the user
  /// works — multi-select — where there is nothing left to write and the
  /// only job is to release the cursor.
  Future<void> advance() async {
    final current = state.value;
    if (current == null) return;

    final showing = current.current;
    if (showing != null) _reportAnswered(showing.id);

    await _apply(current.answers);
  }

  /// Records a date for [questionId] and advances.
  Future<void> chooseDate(String questionId, DateTime date) async {
    final current = state.value;
    if (current == null) return;
    _reportAnswered(questionId);
    await _apply(current.answers.withDate(questionId, date));
  }

  /// Records free text for [questionId] and advances.
  Future<void> chooseText(String questionId, String value) async {
    final current = state.value;
    if (current == null) return;
    // The id only. The answer itself is their name.
    _reportAnswered(questionId);
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
    final current = state.value;
    if (current != null) {
      ref
          .read(analyticsProvider)
          .track(
            AnalyticsEvent.quizCompleted(
              answered: QuizFlow.visible(
                current.questions,
                current.answers,
              ).length,
            ),
          );
    }
    await ref.read(quizRepositoryProvider).markComplete();
  }
}
