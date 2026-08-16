// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the onboarding quiz.
///
/// Holds the answers and a cursor. The cursor exists because
/// [QuizFlow.next] only ever points at the first *unanswered* question,
/// which is the right answer going forwards and useless going back — a
/// user reviewing an earlier answer needs to sit on a question that is
/// already answered.

@ProviderFor(QuizController)
final quizControllerProvider = QuizControllerProvider._();

/// Drives the onboarding quiz.
///
/// Holds the answers and a cursor. The cursor exists because
/// [QuizFlow.next] only ever points at the first *unanswered* question,
/// which is the right answer going forwards and useless going back — a
/// user reviewing an earlier answer needs to sit on a question that is
/// already answered.
final class QuizControllerProvider
    extends $AsyncNotifierProvider<QuizController, QuizUiState> {
  /// Drives the onboarding quiz.
  ///
  /// Holds the answers and a cursor. The cursor exists because
  /// [QuizFlow.next] only ever points at the first *unanswered* question,
  /// which is the right answer going forwards and useless going back — a
  /// user reviewing an earlier answer needs to sit on a question that is
  /// already answered.
  QuizControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quizControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quizControllerHash();

  @$internal
  @override
  QuizController create() => QuizController();
}

String _$quizControllerHash() => r'14379f929f8785d3b69f577c35a4df220f740b48';

/// Drives the onboarding quiz.
///
/// Holds the answers and a cursor. The cursor exists because
/// [QuizFlow.next] only ever points at the first *unanswered* question,
/// which is the right answer going forwards and useless going back — a
/// user reviewing an earlier answer needs to sit on a question that is
/// already answered.

abstract class _$QuizController extends $AsyncNotifier<QuizUiState> {
  FutureOr<QuizUiState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<QuizUiState>, QuizUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<QuizUiState>, QuizUiState>,
              AsyncValue<QuizUiState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
