import 'package:dart_mappable/dart_mappable.dart';

part 'quiz.mapper.dart';

/// How a question is answered.
@MappableEnum()
enum QuizQuestionKind {
  /// Pick exactly one option.
  single,

  /// Pick any number of options.
  multi,

  /// Supply a date, e.g. a birth date.
  date,

  /// Type a short free-text answer, e.g. a first name.
  text,

  /// Not a question at all — a beat between them that reflects earlier
  /// answers back. Nebula uses these well: they cost nothing, break up
  /// the interrogation, and are where the user starts believing the flow
  /// is about them.
  interstitial,
}

/// One selectable answer.
@MappableClass()
class QuizOption with QuizOptionMappable {
  /// Creates an option.
  const QuizOption({required this.id, required this.label, this.detail});

  /// Stable id. Stored in answers, so never reuse one for new copy.
  final String id;

  /// What the user reads.
  final String label;

  /// Optional supporting line.
  final String? detail;
}

/// A condition gating whether a question is shown.
///
/// Deliberately tiny — one question, a set of option ids, any-of. Richer
/// rule engines in onboarding are where these flows go to die: they get
/// unreadable, untestable, and nobody dares change the copy.
@MappableClass()
class QuizCondition with QuizConditionMappable {
  /// Creates a condition.
  const QuizCondition({required this.questionId, required this.anyOf});

  /// The earlier question this depends on.
  final String questionId;

  /// Shown when the answer includes any of these option ids.
  final List<String> anyOf;
}

/// A single step of the onboarding quiz.
@MappableClass()
class QuizQuestion with QuizQuestionMappable {
  /// Creates a question.
  const QuizQuestion({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.options = const [],
    this.showIf,
  });

  /// Stable id, used as the answer key.
  final String id;

  /// How it is answered.
  final QuizQuestionKind kind;

  /// The question itself.
  final String title;

  /// Optional supporting line.
  final String? subtitle;

  /// Choices, for [QuizQuestionKind.single] and
  /// [QuizQuestionKind.multi].
  final List<QuizOption> options;

  /// When present, the question only appears if this holds.
  final QuizCondition? showIf;
}

/// Everything the user has told us.
///
/// Option ids by question id, plus any dates. Kept as plain data so it
/// can be persisted, replayed, and read by the paywall without the quiz
/// UI existing.
@MappableClass()
class QuizAnswers with QuizAnswersMappable {
  /// Creates an answer set.
  const QuizAnswers({
    this.selections = const {},
    this.dates = const {},
    this.texts = const {},
  });

  /// Chosen option ids, keyed by question id.
  final Map<String, List<String>> selections;

  /// Supplied dates, keyed by question id.
  final Map<String, DateTime> dates;

  /// Free-text answers, keyed by question id.
  final Map<String, String> texts;

  /// Whether [questionId] has been answered.
  bool has(String questionId) =>
      (selections[questionId]?.isNotEmpty ?? false) ||
      dates.containsKey(questionId) ||
      (texts[questionId]?.trim().isNotEmpty ?? false);

  /// The option ids chosen for [questionId].
  List<String> optionsFor(String questionId) =>
      selections[questionId] ?? const [];

  /// Whether [optionId] was chosen for [questionId].
  bool chose(String questionId, String optionId) =>
      optionsFor(questionId).contains(optionId);

  /// A copy with [optionIds] recorded against [questionId].
  QuizAnswers withSelection(String questionId, List<String> optionIds) =>
      copyWith(
        selections: {...selections, questionId: optionIds},
      );

  /// A copy with [date] recorded against [questionId].
  QuizAnswers withDate(String questionId, DateTime date) => copyWith(
    dates: {...dates, questionId: date},
  );

  /// A copy with [value] recorded against [questionId].
  QuizAnswers withText(String questionId, String value) => copyWith(
    texts: {...texts, questionId: value},
  );

  /// The name the user gave, if any.
  ///
  /// Addressing someone by name is the cheapest personalisation there
  /// is, and it never leaves the device — there is no account to attach
  /// it to.
  String? get name {
    final value = texts['name']?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }
}
