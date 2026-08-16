import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/logging/logger.dart';

/// Where events go.
///
/// An interface with three implementations and no vendor in sight. The
/// instrumentation — knowing *which* moments matter and where they fire
/// — is the durable half of analytics and outlives whichever product
/// gets picked; swapping PostHog for Amplitude should be one new class,
/// not a hunt through forty call sites.
abstract interface class AnalyticsService {
  /// Reports [event].
  ///
  /// Must never throw and never block the caller. A dropped event is a
  /// missing row in a dashboard; an event that breaks a tap is a bug the
  /// user experiences.
  void track(AnalyticsEvent event);
}

/// Sends events to the log. The default.
///
/// Deliberately the wired-in implementation for now: it makes the funnel
/// visible in a debug console today, adds no dependency, no platform
/// configuration and no privacy-policy obligation, and it means the
/// instrumentation can be reviewed and tested before a vendor is chosen.
/// See `handoff.md` for the swap.
final class LoggingAnalyticsService implements AnalyticsService {
  /// Creates a service writing to the given logger.
  const LoggingAnalyticsService(this._logger);

  final Logger _logger;

  @override
  void track(AnalyticsEvent event) => _logger.debug('analytics: $event');
}

/// Drops everything. For tests that do not care.
final class NoopAnalyticsService implements AnalyticsService {
  /// Creates a no-op service.
  const NoopAnalyticsService();

  @override
  void track(AnalyticsEvent event) {}
}

/// Keeps events in memory. For tests that do care.
final class RecordingAnalyticsService implements AnalyticsService {
  /// Everything tracked so far, in order.
  final List<AnalyticsEvent> events = [];

  /// The names tracked so far, which is usually what a test asserts on.
  List<String> get names => [for (final event in events) event.name];

  @override
  void track(AnalyticsEvent event) => events.add(event);
}
