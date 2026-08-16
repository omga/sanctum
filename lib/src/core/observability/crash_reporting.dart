import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash and error reporting, via Sentry.
///
/// ## Why not the setup wizard
///
/// `sentry-wizard` rewrites the app entry point to wrap `runApp` in
/// `SentryFlutter.init(appRunner: …)` and reintroduces
/// `runZonedGuarded`. `bootstrap` deliberately does not use a custom
/// zone — `PlatformDispatcher.instance.onError` has caught async errors
/// since Flutter 3.3 and does not fight the test binding's zone. So this
/// is wired by hand instead, *after* the app's own handlers are
/// installed: Sentry's integrations keep a reference to whatever
/// `FlutterError.onError` was already set and call it after reporting,
/// so the existing logging still happens.
///
/// ## What is deliberately switched off
///
/// - **Screenshots and view hierarchy.** Both would capture the contents
///   of the screen — journal entries, a name, two birth dates — which is
///   precisely what the app promises never leaves the device. Set
///   explicitly rather than relying on the defaults, so an SDK upgrade
///   that flips them cannot quietly opt us in.
/// - **`SentryNavigatorObserver`.** Same reasoning as PostHog's
///   observer, and the same specific hazard: `MatchResultRoute` carries
///   `name` and `birth` as query parameters, so route breadcrumbs would
///   ship a partner's name and birth date inside a crash report.
///   [_scrub] is a second line of defence in case a route reaches an
///   event by some other path.
/// - **Performance tracing.** Nothing here needs it, and the free tier
///   is 5k events a month — better spent on errors.
abstract final class CrashReporting {
  /// Ingestion endpoint. EU region, matching the project.
  ///
  /// Overridable so a debug build can report to a different project, or
  /// to none at all by passing an empty string.
  static const String dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://36f71bc39f70c0eafaa182420e16f202@o4511922575441920'
        '.ingest.de.sentry.io/4511922579308624',
  );

  /// Query parameters that must never appear in a reported URL.
  static const _sensitiveParams = {'name', 'birth', 'celebrityId'};

  /// Starts reporting. Safe to call once, at startup.
  static Future<void> start() async {
    if (dsn.isEmpty) return;

    await SentryFlutter.init((options) {
      options
        ..dsn = dsn
        ..environment = kReleaseMode ? 'production' : 'development'
        // Verbose, but only in development — it is how you confirm the
        // SDK is actually sending rather than silently dropping.
        ..debug = kDebugMode
        // Privacy-critical. See the class comment. `attachViewHierarchy`
        // is marked experimental by the SDK; it is set anyway because
        // relying on an experimental *default* is the riskier of the
        // two options when the payload is the text on screen.
        ..attachScreenshot = false
        // Deliberate: see the note above. Reverting to the SDK default
        // would mean trusting an experimental default with the text on
        // the user's screen.
        // ignore: experimental_member_use
        ..attachViewHierarchy = false
        ..sendDefaultPii = false
        // Errors only; no performance transactions.
        ..tracesSampleRate = 0.0
        ..beforeSend = _scrub;
    });

    // Handled failures are most of this app's failure surface, and a
    // crash reporter cannot see them by definition.
    ResultReporting.onFailure = _reportFailure;
  }

  /// Reports an [AppFailure] as a warning.
  ///
  /// Warning rather than error so that genuine crashes stay
  /// distinguishable in the inbox: these are failures the app handled
  /// and recovered from, which is useful signal but not an outage.
  static void _reportFailure(AppFailure failure) {
    unawaited(_send(failure));
  }

  static Future<void> _send(AppFailure failure) async {
    await Sentry.captureMessage(
      // The label and message only. `AppFailure.message` is documented
      // as safe to log; the cause is attached separately and never
      // interpolated into user-facing copy.
      '${failure.label}: ${failure.message}',
      level: SentryLevel.warning,
      withScope: (scope) async {
        await scope.setTag('failure', failure.label);
      },
    );
  }

  /// Strips anything identifying before an event leaves the device.
  ///
  /// Sentry 9 wants the event mutated in place rather than copied.
  static SentryEvent? _scrub(SentryEvent event, Hint hint) {
    event.breadcrumbs?.forEach(_scrubCrumb);
    return event;
  }

  static void _scrubCrumb(Breadcrumb crumb) {
    final data = crumb.data;
    if (data == null) return;

    for (final key in data.keys.toList()) {
      if (_sensitiveParams.contains(key)) {
        data[key] = '[redacted]';
        continue;
      }
      final value = data[key];
      if (value is String && _looksSensitive(value)) {
        data[key] = _redactQuery(value);
      }
    }
  }

  static bool _looksSensitive(String value) =>
      _sensitiveParams.any((param) => value.contains('$param='));

  /// Drops the query string, keeping the path so the crumb stays useful.
  static String _redactQuery(String value) {
    final cut = value.indexOf('?');
    return cut == -1 ? value : '${value.substring(0, cut)}?[redacted]';
  }
}
