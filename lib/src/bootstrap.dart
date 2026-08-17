import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/app.dart';
import 'package:sanctum/src/core/analytics/posthog_analytics_service.dart';
import 'package:sanctum/src/core/logging/logger.dart';
import 'package:sanctum/src/core/observability/crash_reporting.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/revenuecat_subscription_repository.dart';
import 'package:sanctum/src/data/services/audio/sanctum_audio_service.dart';

/// Starts Sanctum.
///
/// Everything that must happen before the first frame lives here, and
/// nowhere else. Keeping `main.dart` to a single call means the startup
/// sequence is one readable list instead of something spread across
/// widget constructors.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  const logger = ConsoleLogger();

  // Framework errors: failed builds, layout overflows, bad paints.
  FlutterError.onError = (details) {
    logger.error(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  // Everything else that escapes to the platform. This replaces the older
  // `runZonedGuarded` pattern — since Flutter 3.3 `PlatformDispatcher`
  // catches async errors that used to need a custom zone, and it does not
  // fight with the test binding's own zone the way the old approach did.
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.error('Uncaught', error: error, stackTrace: stackTrace);
    return true;
  };

  // Crash reporting goes last of the three error hooks, and that order
  // matters: Sentry's integrations capture whatever `FlutterError.onError`
  // and `PlatformDispatcher.onError` are already set to and call them
  // after reporting. Installing it before the handlers above would mean
  // Sentry chains to Flutter's defaults and the logging here is lost.
  try {
    await CrashReporting.start();
  } on Object catch (error) {
    logger.warning('Crash reporting setup failed', error: error);
  }

  // Analytics before runApp so the SDK is live for the very first
  // screen. Failure here must never stop the app starting — an app that
  // will not launch because a reporting endpoint is down is a far worse
  // outcome than a missing funnel.
  try {
    await PostHogAnalyticsService.configure();
  } on Object catch (error) {
    logger.warning('Analytics setup failed', error: error);
  }

  // Billing, on the same terms as the two above: a store that will not
  // answer must not stop the app opening. Everything Sanctum does is
  // computed on the device, so a failure here costs the user the paywall
  // and nothing else — `watch` reports free and the free tier works.
  try {
    await RevenueCatSubscriptionRepository.configure();
  } on Object catch (error) {
    logger.warning('Billing setup failed', error: error);
  }

  // Starts the background audio service and returns the one handler the
  // whole app shares. Must happen before runApp: the handler binds a
  // platform service, and a second instance would be a second player.
  final audioHandler = await AudioService.init(
    builder: SanctumAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.soulheals.sanctum.audio',
      androidNotificationChannelName: 'Sanctum sessions',

      // A white-on-transparent status-bar icon. Android tints notification
      // icons and discards their colour, so pointing this at the full
      // colour launcher icon (the default) yields a grey blob.
      androidNotificationIcon: 'drawable/ic_notification',
      notificationColor: Color(0xFF7C5CFF),

      // These two go together, and getting them wrong is what let a
      // session play on with no way to stop it.
      //
      // `androidNotificationOngoing: true` makes the notification
      // non-dismissible *while playing*, so the transport controls
      // cannot be swiped away mid-session. Since Android 13 the system
      // otherwise lets users swipe away a foreground-service
      // notification without stopping the service — audio keeps going,
      // and the only remaining control is gone.
      //
      // It requires `androidStopForegroundOnPause: true` (audio_service
      // asserts on the combination), which is also the behaviour we
      // want: on pause the service leaves the foreground and the
      // notification becomes dismissible, so swiping it then genuinely
      // ends the session.
      // Left explicit despite matching the default: the pairing above
      // is the whole point, and a future edit flipping it silently is
      // exactly the regression this comment exists to prevent.
      // ignore: avoid_redundant_argument_values
      androidStopForegroundOnPause: true,
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    ProviderScope(
      observers: const [_LoggingProviderObserver(logger)],
      overrides: [audioServiceProvider.overrideWithValue(audioHandler)],
      child: const SanctumApp(),
    ),
  );
}

/// Surfaces provider failures that would otherwise be swallowed.
///
/// A provider that throws during build leaves its consumers showing an
/// error state, but nothing reaches the console by default. This makes
/// those failures loud in debug and silent in release.
final class _LoggingProviderObserver extends ProviderObserver {
  const _LoggingProviderObserver(this._logger);

  final Logger _logger;

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    _logger.error(
      'Provider ${context.provider.name ?? context.provider.runtimeType} '
      'failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
