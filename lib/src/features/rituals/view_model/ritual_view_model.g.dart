// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ritual_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Today's ritual, or the wait until the next one.

@ProviderFor(ritualState)
final ritualStateProvider = RitualStateProvider._();

/// Today's ritual, or the wait until the next one.

final class RitualStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<RitualUiState>,
          RitualUiState,
          FutureOr<RitualUiState>
        >
    with $FutureModifier<RitualUiState>, $FutureProvider<RitualUiState> {
  /// Today's ritual, or the wait until the next one.
  RitualStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ritualStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ritualStateHash();

  @$internal
  @override
  $FutureProviderElement<RitualUiState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RitualUiState> create(Ref ref) {
    return ritualState(ref);
  }
}

String _$ritualStateHash() => r'a350d803363a547171d36808308de938bd3ec27e';

/// Completing a ritual.

@ProviderFor(RitualController)
final ritualControllerProvider = RitualControllerProvider._();

/// Completing a ritual.
final class RitualControllerProvider
    extends $AsyncNotifierProvider<RitualController, void> {
  /// Completing a ritual.
  RitualControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ritualControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ritualControllerHash();

  @$internal
  @override
  RitualController create() => RitualController();
}

String _$ritualControllerHash() => r'090e16624d79dc764fb9497b60d44f1c7fc86e83';

/// Completing a ritual.

abstract class _$RitualController extends $AsyncNotifier<void> {
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
