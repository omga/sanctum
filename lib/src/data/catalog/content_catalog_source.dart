import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/domain/models/oracle_card.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';

/// Where bundled content comes from.
///
/// An interface, even though there is exactly one real implementation,
/// because tests want a catalogue without a Flutter asset bundle and
/// because a future remote catalogue should drop in here rather than
/// anywhere a widget can see.
abstract interface class ContentCatalogSource {
  /// Loads the whole catalogue.
  Future<Result<ContentCatalog>> load();
}

/// Loads content from the app's asset bundle.
class AssetContentCatalogSource implements ContentCatalogSource {
  /// Creates a source reading from [bundle], defaulting to [rootBundle].
  const AssetContentCatalogSource({this.bundle});

  /// The bundle to read from. `null` means [rootBundle], resolved lazily
  /// so this constructor can stay `const`.
  final AssetBundle? bundle;

  AssetBundle get _assets => bundle ?? rootBundle;

  @override
  Future<Result<ContentCatalog>> load() {
    return Result.guard(
      () async {
        final cards = await _readList('oracle_cards.json', 'cards');
        final sessions = await _readList('sessions.json', 'sessions');
        final rituals = await _readList('rituals.json', 'rituals');
        final affirmations = await _readList(
          'affirmations.json',
          'affirmations',
        );
        final quiz = await _readList('onboarding_quiz.json', 'questions');

        return ContentCatalog(
          oracleCards: [
            for (final entry in cards)
              OracleCardMapper.fromMap(entry! as Map<String, dynamic>),
          ],
          sessions: [
            for (final entry in sessions)
              SoundSessionMapper.fromMap(entry! as Map<String, dynamic>),
          ],
          rituals: [
            for (final entry in rituals)
              RitualMapper.fromMap(entry! as Map<String, dynamic>),
          ],
          affirmations: [for (final entry in affirmations) entry! as String],
          quizQuestions: [
            for (final entry in quiz)
              QuizQuestionMapper.fromMap(entry! as Map<String, dynamic>),
          ],
        );
      },
      // Malformed bundled content is a build mistake, not a user-facing
      // condition — but it must still surface as a typed failure rather
      // than an exception escaping into a widget build.
      onError: (error, stackTrace) => ContentFailure(
        'Bundled content could not be read',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  Future<List<Object?>> _readList(String file, String key) async {
    final raw = await _assets.loadString('assets/content/$file');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded[key];
    if (list is! List) {
      throw FormatException("'$key' missing or not a list in $file");
    }
    return list;
  }
}
