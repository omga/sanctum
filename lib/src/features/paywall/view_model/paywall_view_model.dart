import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/domain/models/subscription_plan.dart';
import 'package:sanctum/src/domain/services/paywall_trigger.dart';
import 'package:sanctum/src/features/today/view_model/today_view_model.dart';

part 'paywall_view_model.g.dart';

/// Gathers the real signals the trigger needs.
///
/// This is the only place that knows *where* each signal lives — the
/// database, preferences, the clock. [PaywallTrigger] stays a pure
/// function of the resulting value object, which is why its rules can be
/// tested across a simulated two-year journey in milliseconds.
///
/// **This waits on a stream that has not emitted yet.**
/// `streakProvider` is a Drift stream, so this future only completes
/// once the first row arrives. Anything reading it must therefore keep
/// it alive across the await — an auto-dispose provider with no
/// listener is collected before the row lands, and Riverpod completes
/// the future with `Bad state: ... was disposed during loading state`
/// instead. `paywall_presenter.dart` is where that is handled, and why.
@riverpod
Future<PaywallSignals> paywallSignals(
  Ref ref, {
  bool explicitIntent = false,
}) async {
  final clock = ref.watch(clockProvider);
  final today = clock.today();
  final settings = ref.watch(settingsRepositoryProvider);

  final isPremium = ref.watch(isPremiumProvider);
  final streak = await ref.watch(streakProvider(today).future);
  final sessions = await ref.watch(practiceRepositoryProvider).totalSessions();
  final installed = await settings.installDate();
  final paywall = await settings.paywallState();

  final installDate = installed.valueOrNull ?? clock.now();
  final state =
      paywall.valueOrNull ?? (shown: 0, dismissed: 0, lastShown: null);

  return PaywallSignals(
    isPremium: isPremium,
    daysSinceInstall: installDate.dateOnly.calendarDaysUntil(today),
    sessionsCompleted: sessions.getOrElse(0),
    currentStreak: streak.current,
    ritualsCompleted: await _ritualsCompleted(ref),
    timesShown: state.shown,
    timesDismissed: state.dismissed,
    daysSinceLastShown: state.lastShown?.dateOnly.calendarDaysUntil(today),
    explicitIntent: explicitIntent,
  );
}

Future<int> _ritualsCompleted(Ref ref) async {
  final entries = await ref
      .watch(journalRepositoryProvider)
      .watchEntries()
      .first;
  return entries.where((e) => e.kind.name == 'ritual').length;
}

/// Whether to show the paywall right now, and how to frame it.
@riverpod
Future<PaywallDecision> paywallDecision(
  Ref ref, {
  bool explicitIntent = false,
}) async {
  final signals = await ref.watch(
    paywallSignalsProvider(explicitIntent: explicitIntent).future,
  );
  return PaywallTrigger.decide(signals);
}

/// The purchasable plans.
@riverpod
Future<List<SubscriptionPlan>> subscriptionPlans(Ref ref) async {
  final result = await ref.watch(subscriptionRepositoryProvider).plans();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// Purchase, restore, and recording impressions.
@riverpod
class PaywallController extends _$PaywallController {
  @override
  FutureOr<void> build() {}

  /// Records that the paywall was displayed.
  ///
  /// The write is issued through objects captured up front so it lands
  /// even if the screen closes mid-flight — this feeds the cooldown, and
  /// an impression the trigger never hears about is one the user gets
  /// asked again for tomorrow.
  Future<void> recordShown() async {
    final settings = ref.read(settingsRepositoryProvider);
    final now = ref.read(clockProvider).now();

    await settings.recordPaywallShown(now);
    if (ref.mounted) ref.invalidate(paywallSignalsProvider);
  }

  /// Records a dismissal, which lengthens the next cooldown.
  Future<void> recordDismissed() async {
    final settings = ref.read(settingsRepositoryProvider);

    await settings.recordPaywallDismissed();
    if (ref.mounted) ref.invalidate(paywallSignalsProvider);
  }

  /// Buys [plan].
  ///
  /// Returns whether the purchase actually completed. `false` is a
  /// cancellation — not an error, and not a sale. The screen needs the
  /// difference: it decides whether to report a purchase, celebrate, and
  /// close, and doing any of those on a cancellation is what this
  /// method's `Future<void>` version caused.
  Future<bool> purchase(SubscriptionPlan plan) async {
    // Read before the await: this provider auto-disposes and a store
    // sheet can outlive the screen that opened it, so a `ref.read` on
    // the far side would throw on a disposed `Ref`. The writes to
    // `state` are guarded for the same reason — a screen that is gone
    // does not need a state update, and skipping one is harmless.
    final store = ref.read(subscriptionRepositoryProvider);

    state = const AsyncLoading();
    final result = await store.purchase(plan.id);

    if (ref.mounted) {
      state = switch (result) {
        Ok() => const AsyncData(null),
        Err(:final failure) => AsyncError(failure, StackTrace.current),
      };
    }
    return switch (result) {
      Ok(:final value) => value,
      Err() => false,
    };
  }

  /// Restores an existing subscription.
  ///
  /// Returns whether anything was found. The screen needs that to say
  /// something either way: a restore that legitimately finds nothing
  /// looks exactly like a broken button otherwise, which is how this
  /// shipped the first time.
  Future<bool> restore() async {
    final store = ref.read(subscriptionRepositoryProvider);

    state = const AsyncLoading();
    final result = await store.restore();

    if (ref.mounted) {
      state = switch (result) {
        Ok() => const AsyncData(null),
        Err(:final failure) => AsyncError(failure, StackTrace.current),
      };
    }
    return switch (result) {
      Ok(:final value) => value,
      Err() => false,
    };
  }
}
