// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the queue of daily readings fresh.
///
/// ## Why this runs on every launch
///
/// Nothing of ours executes when a notification fires, so each day's
/// line has to be composed in advance and shipped with the scheduled
/// notification. That makes the queue a snapshot, and a snapshot goes
/// stale — so it is thrown away and rebuilt whenever the app opens,
/// which is cheap and means the copy is never more than one session old.
/// Kept alive deliberately, and this is not a performance choice.
///
/// Both callers are fire-and-forget — the shell schedules on launch and
/// the payoff screen asks for permission — so neither ever *watches*
/// this provider. Under the generated default (auto-dispose) that means
/// `ref.read(...notifier)` builds a notifier with no listeners, Riverpod
/// disposes it on the spot, and the `ref.read` calls inside the async
/// body below then throw `UnmountedRefException`. Nothing is scheduled,
/// nothing is shown, and the error reaches `ConsoleLogger` — which goes
/// to the VM service and not to logcat, so a release build says nothing
/// at all.
///
/// That is the third time this exact pattern has bitten this codebase;
/// see the gotchas in `handoff.md`. Scheduling is an app-lifetime
/// concern, not a screen-scoped one, so keepAlive is also simply the
/// correct answer.

@ProviderFor(ReminderController)
final reminderControllerProvider = ReminderControllerProvider._();

/// Keeps the queue of daily readings fresh.
///
/// ## Why this runs on every launch
///
/// Nothing of ours executes when a notification fires, so each day's
/// line has to be composed in advance and shipped with the scheduled
/// notification. That makes the queue a snapshot, and a snapshot goes
/// stale — so it is thrown away and rebuilt whenever the app opens,
/// which is cheap and means the copy is never more than one session old.
/// Kept alive deliberately, and this is not a performance choice.
///
/// Both callers are fire-and-forget — the shell schedules on launch and
/// the payoff screen asks for permission — so neither ever *watches*
/// this provider. Under the generated default (auto-dispose) that means
/// `ref.read(...notifier)` builds a notifier with no listeners, Riverpod
/// disposes it on the spot, and the `ref.read` calls inside the async
/// body below then throw `UnmountedRefException`. Nothing is scheduled,
/// nothing is shown, and the error reaches `ConsoleLogger` — which goes
/// to the VM service and not to logcat, so a release build says nothing
/// at all.
///
/// That is the third time this exact pattern has bitten this codebase;
/// see the gotchas in `handoff.md`. Scheduling is an app-lifetime
/// concern, not a screen-scoped one, so keepAlive is also simply the
/// correct answer.
final class ReminderControllerProvider
    extends $AsyncNotifierProvider<ReminderController, void> {
  /// Keeps the queue of daily readings fresh.
  ///
  /// ## Why this runs on every launch
  ///
  /// Nothing of ours executes when a notification fires, so each day's
  /// line has to be composed in advance and shipped with the scheduled
  /// notification. That makes the queue a snapshot, and a snapshot goes
  /// stale — so it is thrown away and rebuilt whenever the app opens,
  /// which is cheap and means the copy is never more than one session old.
  /// Kept alive deliberately, and this is not a performance choice.
  ///
  /// Both callers are fire-and-forget — the shell schedules on launch and
  /// the payoff screen asks for permission — so neither ever *watches*
  /// this provider. Under the generated default (auto-dispose) that means
  /// `ref.read(...notifier)` builds a notifier with no listeners, Riverpod
  /// disposes it on the spot, and the `ref.read` calls inside the async
  /// body below then throw `UnmountedRefException`. Nothing is scheduled,
  /// nothing is shown, and the error reaches `ConsoleLogger` — which goes
  /// to the VM service and not to logcat, so a release build says nothing
  /// at all.
  ///
  /// That is the third time this exact pattern has bitten this codebase;
  /// see the gotchas in `handoff.md`. Scheduling is an app-lifetime
  /// concern, not a screen-scoped one, so keepAlive is also simply the
  /// correct answer.
  ReminderControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderControllerHash();

  @$internal
  @override
  ReminderController create() => ReminderController();
}

String _$reminderControllerHash() =>
    r'91eda468277d4af616b6d3cff943333a8e6da4c5';

/// Keeps the queue of daily readings fresh.
///
/// ## Why this runs on every launch
///
/// Nothing of ours executes when a notification fires, so each day's
/// line has to be composed in advance and shipped with the scheduled
/// notification. That makes the queue a snapshot, and a snapshot goes
/// stale — so it is thrown away and rebuilt whenever the app opens,
/// which is cheap and means the copy is never more than one session old.
/// Kept alive deliberately, and this is not a performance choice.
///
/// Both callers are fire-and-forget — the shell schedules on launch and
/// the payoff screen asks for permission — so neither ever *watches*
/// this provider. Under the generated default (auto-dispose) that means
/// `ref.read(...notifier)` builds a notifier with no listeners, Riverpod
/// disposes it on the spot, and the `ref.read` calls inside the async
/// body below then throw `UnmountedRefException`. Nothing is scheduled,
/// nothing is shown, and the error reaches `ConsoleLogger` — which goes
/// to the VM service and not to logcat, so a release build says nothing
/// at all.
///
/// That is the third time this exact pattern has bitten this codebase;
/// see the gotchas in `handoff.md`. Scheduling is an app-lifetime
/// concern, not a screen-scoped one, so keepAlive is also simply the
/// correct answer.

abstract class _$ReminderController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
