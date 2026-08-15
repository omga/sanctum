// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app-wide clock.
///
/// Override this in tests with a [FixedClock] to make anything
/// time-dependent deterministic:
///
/// ```dart
/// ProviderContainer(
///   overrides: [clockProvider.overrideWithValue(FixedClock(someDate))],
/// );
/// ```

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// The app-wide clock.
///
/// Override this in tests with a [FixedClock] to make anything
/// time-dependent deterministic:
///
/// ```dart
/// ProviderContainer(
///   overrides: [clockProvider.overrideWithValue(FixedClock(someDate))],
/// );
/// ```

final class ClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  /// The app-wide clock.
  ///
  /// Override this in tests with a [FixedClock] to make anything
  /// time-dependent deterministic:
  ///
  /// ```dart
  /// ProviderContainer(
  ///   overrides: [clockProvider.overrideWithValue(FixedClock(someDate))],
  /// );
  /// ```
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$clockHash() => r'dba0ee8ab939f6591c52073ac83178580c4dd322';

/// The app-wide logger.

@ProviderFor(logger)
final loggerProvider = LoggerProvider._();

/// The app-wide logger.

final class LoggerProvider extends $FunctionalProvider<Logger, Logger, Logger>
    with $Provider<Logger> {
  /// The app-wide logger.
  LoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggerHash();

  @$internal
  @override
  $ProviderElement<Logger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Logger create(Ref ref) {
    return logger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Logger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Logger>(value),
    );
  }
}

String _$loggerHash() => r'cbb336cf8ebaaf2681c308342045c568462de849';
