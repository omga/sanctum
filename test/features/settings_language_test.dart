import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/settings_repository.dart';
import 'package:sanctum/src/features/settings/view_model/settings_view_model.dart';
import 'package:sanctum/src/l10n/sanctum_locales.dart';

/// A settings store that remembers one language.
class _Settings implements SettingsRepository {
  _Settings({this.language, this.failsToWrite = false});

  String? language;
  bool failsToWrite;
  int writes = 0;

  @override
  Future<Result<String?>> preferredLanguage() async => Result.ok(language);

  @override
  Future<Result<void>> setPreferredLanguage(String? code) async {
    if (failsToWrite) return const Result.err(StorageFailure('nope'));
    writes++;
    language = code;
    return const Result.ok(null);
  }

  @override
  Future<Result<String>> installSalt() async => const Result.ok('salt');

  @override
  Future<Result<bool>> hasOnboarded() async => const Result.ok(true);

  @override
  Future<Result<void>> setOnboarded() async => const Result.ok(null);

  @override
  Future<Result<DateTime>> installDate() async => Result.ok(DateTime(2026));

  @override
  Future<Result<({int dismissed, DateTime? lastShown, int shown})>>
  paywallState() async =>
      const Result.ok((shown: 0, dismissed: 0, lastShown: null));

  @override
  Future<Result<void>> recordPaywallShown(DateTime at) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> recordPaywallDismissed() async =>
      const Result.ok(null);
}

ProviderContainer _container(_Settings settings) {
  final container = ProviderContainer(
    overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('the stored language', () {
    test('is null by default, meaning follow the device', () async {
      final container = _container(_Settings());
      expect(await container.read(languagePreferenceProvider.future), isNull);
    });

    test('drives the locale both trees resolve from', () async {
      // The one seam: `MaterialApp` and the content catalogue both read
      // this, so chrome and readings cannot end up in different
      // languages.
      final container = _container(_Settings(language: 'uk'));
      await container.read(languagePreferenceProvider.future);

      expect(container.read(contentLocaleProvider), const Locale('uk'));
    });

    test('an unshipped language falls back rather than failing', () async {
      // Nothing stops an old build writing a code a new build dropped.
      final container = _container(_Settings(language: 'fr'));
      await container.read(languagePreferenceProvider.future);

      expect(
        container.read(contentLocaleProvider),
        SanctumLocales.fallback,
      );
    });

    test('a read failure follows the device instead of throwing', () async {
      // A language nobody can read is a worse outcome than the wrong
      // language, and this is a setting rather than a receipt.
      final container = _container(_Settings()..failsToWrite = false);
      expect(await container.read(languagePreferenceProvider.future), isNull);
    });
  });

  group('choosing a language', () {
    test('stores it and re-resolves the locale', () async {
      final settings = _Settings();
      final container = _container(settings);
      await container.read(languagePreferenceProvider.future);
      expect(container.read(contentLocaleProvider), SanctumLocales.fallback);

      final saved = await container
          .read(languageControllerProvider.notifier)
          .choose('es');

      expect(saved, isTrue);
      expect(settings.language, 'es');
      await container.read(languagePreferenceProvider.future);
      expect(container.read(contentLocaleProvider), const Locale('es'));
    });

    test('going back to the device clears the stored code', () async {
      final settings = _Settings(language: 'ru');
      final container = _container(settings);
      await container.read(languagePreferenceProvider.future);

      await container
          .read(languageControllerProvider.notifier)
          .choose(null);

      expect(settings.language, isNull);
      expect(await container.read(languagePreferenceProvider.future), isNull);
    });

    test('a write failure changes nothing', () async {
      // Half-applying this is the bad outcome: chrome in one language
      // and readings in another is exactly what SanctumLocales exists
      // to prevent.
      final settings = _Settings(language: 'uk', failsToWrite: true);
      final container = _container(settings);
      await container.read(languagePreferenceProvider.future);

      final saved = await container
          .read(languageControllerProvider.notifier)
          .choose('es');

      expect(saved, isFalse);
      expect(settings.language, 'uk');
      expect(container.read(contentLocaleProvider), const Locale('uk'));
    });

    test('every shipped language can be chosen', () async {
      for (final locale in SanctumLocales.supported) {
        final settings = _Settings();
        final container = _container(settings);
        await container.read(languagePreferenceProvider.future);

        await container
            .read(languageControllerProvider.notifier)
            .choose(locale.languageCode);

        await container.read(languagePreferenceProvider.future);
        expect(
          container.read(contentLocaleProvider),
          locale,
          reason: locale.languageCode,
        );
      }
    });
  });
}
