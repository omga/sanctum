import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/analytics/analytics_service.dart';

/// Sends events to PostHog.
///
/// ## Configured from Dart, not from the manifest
///
/// PostHog's setup guide has you paste the project token into
/// `AndroidManifest.xml` *and* `Info.plist`. Doing it here instead keeps
/// the token in one place, lets [PostHogAnalyticsService.configure] pick
/// the host and the debug flag from build configuration, and stops
/// `debug: true` — which their snippet hardcodes — from shipping to
/// production. Native auto-init is switched off on both platforms with
/// `com.posthog.posthog.AUTO_INIT`.
///
/// ## What is switched off, and why
///
/// - **Session replay.** This app's screens carry journal entries, the
///   user's name, their birth date and their partner's birth date, and
///   the onboarding copy promises those stay on the phone. Replay
///   records the screen. Masking is on by default and would probably
///   hold, but "probably" is not the standard for the one claim the
///   product is differentiated on.
/// - **`PosthogObserver`.** The navigator observer that auto-captures
///   screen views is deliberately *not* installed. Route names here are
///   not safe to send: `MatchResultRoute` carries `name` and `birth` as
///   query parameters, so autocapturing routes would post a partner's
///   name and birth date to a third party. Screens are reported through
///   the typed taxonomy or not at all.
/// - **Person profiles**, set to `identifiedOnly`. Nothing ever calls
///   `identify`, so no profiles are created — events stay anonymous,
///   which is both cheaper and the point.
///
/// Application lifecycle events stay on: they carry no personal data and
/// they cover app-open for free.
final class PostHogAnalyticsService implements AnalyticsService {
  /// Creates a service. Call [configure] once before using it.
  const PostHogAnalyticsService();

  /// Project token. Overridable so debug builds can use a separate
  /// project rather than polluting production funnels.
  ///
  /// Not a secret: a `phc_` token is write-only ingestion and is
  /// extractable from any shipped binary. The worst it allows is someone
  /// sending junk events, which is why it is safe to default here.
  static const String projectToken = String.fromEnvironment(
    'POSTHOG_KEY',
    defaultValue: 'phc_qmERDuPKqJGN2c5gqfLygVhXYCvcWxExicNBXRSmfHtq',
  );

  /// Ingestion host. US cloud, matching the project's region.
  static const String host = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );

  /// Initialises the SDK. Safe to call once at startup.
  static Future<void> configure() async {
    if (projectToken.isEmpty) return;

    final config = PostHogConfig(projectToken)
      ..host = host
      ..debug = kDebugMode
      ..captureApplicationLifecycleEvents = true
      ..sessionReplay = false
      ..surveys = false
      ..personProfiles = PostHogPersonProfiles.identifiedOnly;

    await Posthog().setup(config);
  }

  @override
  void track(AnalyticsEvent event) => unawaited(_send(event));

  /// Fire-and-forget, and deliberately swallowing.
  ///
  /// A dropped event is a missing row in a dashboard. An event that
  /// throws is a bug the user experiences — analytics must never be able
  /// to break a tap handler.
  Future<void> _send(AnalyticsEvent event) async {
    try {
      await Posthog().capture(
        eventName: event.name,
        properties: event.properties.isEmpty ? null : event.properties,
      );
    } on Object {
      // Intentionally ignored.
    }
  }
}
