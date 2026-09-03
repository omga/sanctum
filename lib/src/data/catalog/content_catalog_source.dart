import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/oracle_card.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/l10n/sanctum_locales.dart';

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
///
/// ## Content is per locale, and falls back per *file*
///
/// Every catalogue file lives under `assets/content/<language>/`. A
/// locale that is missing one file gets the English one for that file
/// alone, rather than the whole catalogue failing or the whole app
/// dropping to English.
///
/// That granularity is deliberate. This app's copy is its product, and a
/// translation lands in pieces — the quiz first, then the readings, then
/// two hundred oracle cards. Falling back per file means a locale can
/// ship the moment its important content is ready, with the long tail
/// still in English, instead of waiting for the last card to be
/// translated before anybody sees anything.
class AssetContentCatalogSource implements ContentCatalogSource {
  /// Creates a source reading [locale] from [bundle].
  const AssetContentCatalogSource({this.locale, this.bundle});

  /// Which locale to load. `null` means [SanctumLocales.fallback].
  final Locale? locale;

  /// The bundle to read from. `null` means [rootBundle], resolved lazily
  /// so this constructor can stay `const`.
  final AssetBundle? bundle;

  AssetBundle get _assets => bundle ?? rootBundle;

  Locale get _locale => locale ?? SanctumLocales.fallback;

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
        final copy = await _readMap('copy.json');
        final famous = await _readList(
          'celebrities.json',
          'celebrities',
        );

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
          celebrities: [
            for (final entry in famous)
              CelebrityMapper.fromMap(entry! as Map<String, dynamic>),
          ],
          copy: CopyBook(copy),
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

  /// Reads [file] for the active locale, falling back to English.
  ///
  /// The fallback is driven by the *absence* of an asset rather than by
  /// a list of which files a locale has translated. Such a list is a
  /// second source of truth, and the first thing to go stale the moment
  /// somebody adds a file.
  Future<String> _readString(String file) async {
    final dir = SanctumLocales.contentDirFor(_locale);
    try {
      return await _assets.loadString('$dir/$file');
      // A missing asset is signalled by Flutter as a `FlutterError`,
      // which is an `Error` rather than an `Exception` — so catching it
      // trips `avoid_catching_errors`, and the rule is right in general.
      // It is wrong here: this is not a bug being swallowed, it is the
      // only signal the asset API gives for "that file is not bundled",
      // which is the ordinary case for a partially translated locale.
      // ignore: avoid_catching_errors
    } on FlutterError {
      // Only a missing asset is recoverable. A file that exists and is
      // malformed must keep throwing, or a typo in a translated file
      // silently serves English forever and nobody finds out.
      if (_locale == SanctumLocales.fallback) rethrow;
      final fallbackDir = SanctumLocales.contentDirFor(
        SanctumLocales.fallback,
      );
      return _assets.loadString('$fallbackDir/$file');
    }
  }

  /// Reads a flat `{"key": "line"}` file, e.g. the reading copy.
  Future<Map<String, String>> _readMap(String file) async {
    final decoded = jsonDecode(await _readString(file)) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        if (!entry.key.startsWith('@')) entry.key: entry.value! as String,
    };
  }

  Future<List<Object?>> _readList(String file, String key) async {
    final raw = await _readString(file);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded[key];
    if (list is! List) {
      throw FormatException("'$key' missing or not a list in $file");
    }
    return list;
  }
}
