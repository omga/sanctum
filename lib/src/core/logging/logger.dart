import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// How noisy a log line is.
enum LogLevel {
  /// Fine-grained tracing, stripped in release.
  debug,

  /// Notable lifecycle events.
  info,

  /// Something recoverable looks wrong.
  warning,

  /// Something failed.
  error,
}

/// Where log lines go.
///
/// An interface rather than direct `print` calls so that adding Sentry or
/// Crashlytics later is one new implementation and one provider override,
/// with no edits anywhere else in the app.
abstract interface class Logger {
  /// Writes a single log line.
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}

/// Logs to the Dart developer console. Silent in release builds.
final class ConsoleLogger implements Logger {
  /// Creates a console logger.
  const ConsoleLogger();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode && level == LogLevel.debug) return;
    developer.log(
      message,
      name: 'sanctum.${level.name}',
      error: error,
      stackTrace: stackTrace,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
    );
  }
}

/// Convenience wrappers so call sites read as prose.
extension LoggerX on Logger {
  /// Logs at [LogLevel.debug].
  void debug(String message) => log(LogLevel.debug, message);

  /// Logs at [LogLevel.info].
  void info(String message) => log(LogLevel.info, message);

  /// Logs at [LogLevel.warning].
  void warning(String message, {Object? error}) =>
      log(LogLevel.warning, message, error: error);

  /// Logs at [LogLevel.error].
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}
