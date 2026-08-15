import 'dart:convert';

import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores what the user told us during onboarding.
///
/// In preferences rather than the database: these answers are read on the
/// very first frame to decide whether onboarding is done, and they are a
/// single small blob rather than a queryable set.
abstract interface class QuizRepository {
  /// The saved answers, empty if the quiz has not been taken.
  Future<Result<QuizAnswers>> load();

  /// Persists [answers].
  Future<Result<void>> save(QuizAnswers answers);

  /// Whether the quiz has been completed at least once.
  Future<Result<bool>> isComplete();

  /// Marks the quiz finished.
  Future<Result<void>> markComplete();
}

/// [QuizRepository] backed by shared_preferences.
class PreferencesQuizRepository implements QuizRepository {
  /// Creates a repository.
  const PreferencesQuizRepository();

  static const _answersKey = 'sanctum.quiz_answers';
  static const _completeKey = 'sanctum.quiz_complete';

  @override
  Future<Result<QuizAnswers>> load() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_answersKey);
        if (raw == null || raw.isEmpty) return const QuizAnswers();
        return QuizAnswersMapper.fromMap(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      },
      // A malformed blob must not brick onboarding forever, so this is
      // recoverable: the caller falls back to an empty answer set.
      onError: (error, stackTrace) => StorageFailure(
        'Could not read quiz answers',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> save(QuizAnswers answers) {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_answersKey, jsonEncode(answers.toMap()));
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save quiz answers',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<bool>> isComplete() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_completeKey) ?? false;
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read quiz state',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> markComplete() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_completeKey, true);
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save quiz state',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
