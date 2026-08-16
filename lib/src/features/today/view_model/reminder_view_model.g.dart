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
  ReminderControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderControllerProvider',
        isAutoDispose: true,
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
    r'3e1d3b4dfbe376f95b6e51316c10572bdf22e0e1';

/// Keeps the queue of daily readings fresh.
///
/// ## Why this runs on every launch
///
/// Nothing of ours executes when a notification fires, so each day's
/// line has to be composed in advance and shipped with the scheduled
/// notification. That makes the queue a snapshot, and a snapshot goes
/// stale — so it is thrown away and rebuilt whenever the app opens,
/// which is cheap and means the copy is never more than one session old.

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
