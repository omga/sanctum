import 'package:sanctum/src/domain/models/quiz.dart';

/// Walks the user through the quiz.
///
/// ## Why this is pure
///
/// The onboarding quiz is the single biggest revenue lever in this
/// category, and it is also the surface most likely to be edited on a
/// whim — new question, reordered steps, a branch for a segment. Keeping
/// "which question comes next" as a pure function of the question set and
/// the answers so far means every one of those edits is covered by tests
/// instead of by tapping through the flow on a phone.
///
/// Branching also makes the naive `index++` wrong: skipping a hidden
/// question must not skip a visible one, and going back must land on the
/// question the user actually saw.
abstract final class QuizFlow {
  /// The questions currently visible, in order.
  ///
  /// A question with an unmet [QuizQuestion.showIf] is omitted, and so is
  /// one whose condition depends on a question that is itself hidden —
  /// otherwise a branch could resurrect itself through a dead parent.
  static List<QuizQuestion> visible(
    List<QuizQuestion> questions,
    QuizAnswers answers,
  ) {
    final shown = <QuizQuestion>[];
    final shownIds = <String>{};

    for (final question in questions) {
      final condition = question.showIf;
      if (condition == null) {
        shown.add(question);
        shownIds.add(question.id);
        continue;
      }

      if (!shownIds.contains(condition.questionId)) continue;

      final chosen = answers.optionsFor(condition.questionId);
      if (chosen.any(condition.anyOf.contains)) {
        shown.add(question);
        shownIds.add(question.id);
      }
    }

    return shown;
  }

  /// The next unanswered visible question, or `null` when complete.
  static QuizQuestion? next(
    List<QuizQuestion> questions,
    QuizAnswers answers,
  ) {
    for (final question in visible(questions, answers)) {
      if (!answers.has(question.id)) return question;
    }
    return null;
  }

  /// Whether every visible question has been answered.
  static bool isComplete(
    List<QuizQuestion> questions,
    QuizAnswers answers,
  ) => next(questions, answers) == null;

  /// Progress through the quiz, `0.0`–`1.0`.
  ///
  /// Measured against the *currently visible* set, which shifts as
  /// branches open and close. That is the honest number: a bar that
  /// pretends to know the length of a branching flow either lies or
  /// jumps backwards, and both read as broken.
  static double progress(
    List<QuizQuestion> questions,
    QuizAnswers answers,
  ) {
    final shown = visible(questions, answers);
    if (shown.isEmpty) return 1;

    final answered = shown.where((q) => answers.has(q.id)).length;
    return (answered / shown.length).clamp(0.0, 1.0);
  }

  /// Clears [questionId] and anything that branched off it.
  ///
  /// Needed when the user goes back and changes an answer: leaving the
  /// orphaned replies in place would send stale data to the paywall and,
  /// worse, could mark the quiz complete using answers to questions no
  /// longer being asked.
  static QuizAnswers clearFrom(
    List<QuizQuestion> questions,
    QuizAnswers answers,
    String questionId,
  ) => prune(
    questions,
    QuizAnswers(
      selections: {...answers.selections}..remove(questionId),
      dates: {...answers.dates}..remove(questionId),
      texts: {...answers.texts}..remove(questionId),
    ),
  );

  /// Drops answers to questions that are no longer visible.
  ///
  /// Unticking an option on a multi-select question can close a branch
  /// the user has already walked into: dropping "love" must take "where
  /// are you with it?" with it, or the payoff and the paywall read back
  /// a reply to a question the user is no longer being asked.
  static QuizAnswers prune(
    List<QuizQuestion> questions,
    QuizAnswers answers,
  ) {
    var result = answers;

    // Repeat until stable, since a dropped branch can orphan another.
    var changed = true;
    while (changed) {
      changed = false;
      final live = visible(questions, result).map((q) => q.id).toSet();

      final answered = {
        ...result.selections.keys,
        ...result.dates.keys,
        ...result.texts.keys,
      };
      for (final id in answered) {
        if (live.contains(id)) continue;
        result = QuizAnswers(
          selections: {...result.selections}..remove(id),
          dates: {...result.dates}..remove(id),
          texts: {...result.texts}..remove(id),
        );
        changed = true;
      }
    }

    return result;
  }
}
