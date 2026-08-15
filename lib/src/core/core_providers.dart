import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/logging/logger.dart';
import 'package:sanctum/src/core/time/clock.dart';

part 'core_providers.g.dart';

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
@Riverpod(keepAlive: true)
Clock clock(Ref ref) {
  // Debug-only time travel.
  //
  // Nearly every surface in Sanctum is a function of the date — the
  // card, the affirmation, the moon, the streak, whether a ritual is
  // open. Waiting two weeks to look at the full-moon UI is not a
  // workflow, so:
  //
  //   flutter run --dart-define=SANCTUM_FAKE_DATE=2026-08-28
  //
  // Compiled out of release builds: String.fromEnvironment is a const,
  // so the kReleaseMode branch lets the tree-shaker drop it entirely.
  if (!kReleaseMode) {
    const fakeDate = String.fromEnvironment('SANCTUM_FAKE_DATE');
    if (fakeDate.isNotEmpty) {
      return FixedClock(DateTime.parse(fakeDate));
    }
  }
  return const SystemClock();
}

/// The app-wide logger.
@Riverpod(keepAlive: true)
Logger logger(Ref ref) => const ConsoleLogger();
