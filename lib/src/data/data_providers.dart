import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/catalog/content_catalog_source.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/data/repositories/compatibility_repository.dart';
import 'package:sanctum/src/data/repositories/conversation_repository.dart';
import 'package:sanctum/src/data/repositories/energy_repository.dart';
import 'package:sanctum/src/data/repositories/entitlement_repository.dart';
import 'package:sanctum/src/data/repositories/journal_repository.dart';
import 'package:sanctum/src/data/repositories/message_balance_repository.dart';
import 'package:sanctum/src/data/repositories/oracle_repository.dart';
import 'package:sanctum/src/data/repositories/practice_repository.dart';
import 'package:sanctum/src/data/repositories/quiz_repository.dart';
import 'package:sanctum/src/data/repositories/report_repository.dart';
import 'package:sanctum/src/data/repositories/revenuecat_subscription_repository.dart';
import 'package:sanctum/src/data/repositories/settings_repository.dart';
import 'package:sanctum/src/data/repositories/subscription_repository.dart';
import 'package:sanctum/src/data/services/audio/sanctum_audio_service.dart';
import 'package:sanctum/src/data/services/reminders/reminder_service.dart';
import 'package:sanctum/src/l10n/sanctum_locales.dart';

part 'data_providers.g.dart';

/// The database. One per app, closed when the container is disposed.
@Riverpod(keepAlive: true)
SanctumDatabase sanctumDatabase(Ref ref) {
  final database = SanctumDatabase();
  ref.onDispose(database.close);
  return database;
}

/// The language the user picked, or null to follow the device.
///
/// Read once at startup — `app.dart` holds the first frame until it
/// lands, alongside the onboarding answer — so nothing renders in one
/// language and then swaps to another.
@Riverpod(keepAlive: true)
Future<String?> languagePreference(Ref ref) async {
  final result = await ref.watch(settingsRepositoryProvider)
      .preferredLanguage();
  // A preference we cannot read is the same as not having one: follow
  // the device, which is what an unconfigured install does anyway.
  return result.getOrElse(null);
}

/// The locale the content catalogue is loaded in.
///
/// Resolved through [SanctumLocales], which is the same function
/// `MaterialApp` is given for the widget tree — so the JSON and the ARB
/// strings can never disagree about which language the user is being
/// shown. This is the seam the in-app language picker uses; the picker
/// stores a code, and both trees resolve it here.
///
/// Reading `.value` collapses "still loading" and "no preference" into
/// the same branch, and that is correct: both mean follow the device.
/// The first frame is held until the preference has landed, so the
/// loading case is not one a user can see.
@Riverpod(keepAlive: true)
Locale contentLocale(Ref ref) {
  final chosen = ref.watch(languagePreferenceProvider).value;
  return SanctumLocales.resolve(
    chosen == null
        ? PlatformDispatcher.instance.locales
        : [Locale(chosen)],
  );
}

/// Where bundled content is read from.
@Riverpod(keepAlive: true)
ContentCatalogSource contentCatalogSource(Ref ref) =>
    AssetContentCatalogSource(locale: ref.watch(contentLocaleProvider));

/// The parsed content catalogue.
///
/// ## Where `Result` stops and `AsyncValue` starts
///
/// The data layer returns [Result] so failure is in the type and cannot
/// be forgotten. Riverpod already models loading/data/error as
/// `AsyncValue`, so re-wrapping a `Result` inside one would give the UI
/// two error channels to handle for the same failure.
///
/// This provider is the boundary: it unwraps the [Result] and rethrows
/// the failure, letting `AsyncValue.error` carry it from here on. That is
/// why `AppFailure` implements `Exception`.
@Riverpod(keepAlive: true)
Future<ContentCatalog> contentCatalog(Ref ref) async {
  final result = await ref.watch(contentCatalogSourceProvider).load();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// Stable per-install salt for daily content selection.
@Riverpod(keepAlive: true)
Future<String> installSalt(Ref ref) async {
  final result = await ref.watch(settingsRepositoryProvider).installSalt();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// A stable id for the advisor proxy's rate limiter.
///
/// Separate from [installSalt] on purpose — see
/// `SettingsRepository.advisorInstallId`.
@Riverpod(keepAlive: true)
Future<String> advisorInstallId(Ref ref) async {
  final result = await ref.watch(settingsRepositoryProvider)
      .advisorInstallId();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// Schedules the daily reading notification.
@Riverpod(keepAlive: true)
ReminderService reminderService(Ref ref) =>
    LocalNotificationReminderService(FlutterLocalNotificationsPlugin());

/// Compatibility matches and what the user has unlocked.
@Riverpod(keepAlive: true)
CompatibilityRepository compatibilityRepository(Ref ref) =>
    const PreferencesCompatibilityRepository();

/// Which relationship reports have been bought.
///
/// Its own repository rather than a field on the compatibility blob —
/// see [ReportRepository] for why receipts must not share a store with
/// data that is deliberately discarded when it fails to decode.
@Riverpod(keepAlive: true)
ReportRepository reportRepository(Ref ref) =>
    const PreferencesReportRepository();

/// Onboarding quiz answers.
@Riverpod(keepAlive: true)
QuizRepository quizRepository(Ref ref) => const PreferencesQuizRepository();

/// App settings store.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    const PreferencesSettingsRepository();

/// Practice log and streaks.
@Riverpod(keepAlive: true)
PracticeRepository practiceRepository(Ref ref) =>
    DriftPracticeRepository(ref.watch(sanctumDatabaseProvider));

/// Journal entries.
@Riverpod(keepAlive: true)
JournalRepository journalRepository(Ref ref) =>
    DriftJournalRepository(ref.watch(sanctumDatabaseProvider));

/// Advisor conversations and their transcripts.
@Riverpod(keepAlive: true)
ConversationRepository conversationRepository(Ref ref) =>
    DriftConversationRepository(ref.watch(sanctumDatabaseProvider));

/// What the user has left to spend on advisor messages.
///
/// Preferences rather than the database: it is a receipt, and it has to
/// survive a wipe of the content that a transcript does not.
@Riverpod(keepAlive: true)
MessageBalanceRepository messageBalanceRepository(Ref ref) =>
    const PreferencesMessageBalanceRepository();

/// Energy check-ins.
@Riverpod(keepAlive: true)
EnergyRepository energyRepository(Ref ref) =>
    DriftEnergyRepository(ref.watch(sanctumDatabaseProvider));

/// Oracle draws.
@Riverpod(keepAlive: true)
OracleRepository oracleRepository(Ref ref) =>
    DriftOracleRepository(ref.watch(sanctumDatabaseProvider));

/// The local stand-in for a real store.
///
/// One object serves both interfaces below, exactly as RevenueCat's
/// `Purchases` does. Replacing it means changing these three providers
/// and nothing else in the app.
///
/// `LocalSubscriptionRepository` is still here and still works — set
/// `SANCTUM_LOCAL_BILLING=true` to get it back. It is the only way to
/// exercise the paywall on a machine with no store account, and its
/// `resetForTesting` is the only way to see the paywall twice on one
/// device; RevenueCat has no equivalent short of clearing app data.
@Riverpod(keepAlive: true)
BillingRepository subscriptionStore(Ref ref) =>
    const bool.fromEnvironment('SANCTUM_LOCAL_BILLING')
    ? LocalSubscriptionRepository()
    : RevenueCatSubscriptionRepository();

/// What the user has access to. Most features depend only on this.
@Riverpod(keepAlive: true)
EntitlementRepository entitlementRepository(Ref ref) =>
    ref.watch(subscriptionStoreProvider);

/// Buying a subscription. Only the paywall depends on this.
@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) =>
    ref.watch(subscriptionStoreProvider);

/// The live entitlement, as a stream.
@Riverpod(keepAlive: true)
Stream<SanctumEntitlement> entitlement(Ref ref) =>
    ref.watch(entitlementRepositoryProvider).watch();

/// Whether the user is premium right now.
@Riverpod(keepAlive: true)
bool isPremium(Ref ref) =>
    ref.watch(entitlementProvider).value?.isPremium ?? false;

/// The audio engine.
///
/// Overridden in `bootstrap()` with the handler returned by
/// `AudioService.init()`. It cannot be constructed lazily here because
/// initialising the background service is async and must happen exactly
/// once, before the first frame — so this throws rather than silently
/// handing out a second, non-background player.
@Riverpod(keepAlive: true)
SanctumAudioService audioService(Ref ref) => throw UnimplementedError(
  'audioServiceProvider must be overridden in bootstrap()',
);

/// Live session progress.
@Riverpod(keepAlive: true)
Stream<SessionPlaybackState> sessionPlayback(Ref ref) =>
    ref.watch(audioServiceProvider).sessionState;
