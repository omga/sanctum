// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compatibility_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the compatibility tab.

@ProviderFor(CompatibilityController)
final compatibilityControllerProvider = CompatibilityControllerProvider._();

/// Drives the compatibility tab.
final class CompatibilityControllerProvider
    extends
        $AsyncNotifierProvider<CompatibilityController, CompatibilityUiState> {
  /// Drives the compatibility tab.
  CompatibilityControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compatibilityControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compatibilityControllerHash();

  @$internal
  @override
  CompatibilityController create() => CompatibilityController();
}

String _$compatibilityControllerHash() =>
    r'f7b181b0990f10f5ea73390f5aa35f15b1b5d011';

/// Drives the compatibility tab.

abstract class _$CompatibilityController
    extends $AsyncNotifier<CompatibilityUiState> {
  FutureOr<CompatibilityUiState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<CompatibilityUiState>, CompatibilityUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CompatibilityUiState>,
                CompatibilityUiState
              >,
              AsyncValue<CompatibilityUiState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
