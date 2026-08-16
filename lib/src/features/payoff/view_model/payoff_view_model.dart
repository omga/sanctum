import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/reading.dart';
import 'package:sanctum/src/domain/services/reading_composer.dart';

part 'payoff_view_model.g.dart';

/// The reading built from the quiz answers.
@riverpod
Future<Reading> reading(Ref ref) async {
  final loaded = await ref.watch(quizRepositoryProvider).load();
  return ReadingComposer.compose(loaded.getOrElse(const QuizAnswers()));
}
