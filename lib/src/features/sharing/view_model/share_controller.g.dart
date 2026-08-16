// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Puts a captured card, or an invite, into the system share sheet.
///
/// Shared by the payoff screen and the compatibility flow. It lives
/// outside both because the *only* growth surface this product has is
/// people posting its output, and a share path that quietly differs
/// between two screens is a growth bug nobody will ever file.

@ProviderFor(ShareController)
final shareControllerProvider = ShareControllerProvider._();

/// Puts a captured card, or an invite, into the system share sheet.
///
/// Shared by the payoff screen and the compatibility flow. It lives
/// outside both because the *only* growth surface this product has is
/// people posting its output, and a share path that quietly differs
/// between two screens is a growth bug nobody will ever file.
final class ShareControllerProvider
    extends $AsyncNotifierProvider<ShareController, void> {
  /// Puts a captured card, or an invite, into the system share sheet.
  ///
  /// Shared by the payoff screen and the compatibility flow. It lives
  /// outside both because the *only* growth surface this product has is
  /// people posting its output, and a share path that quietly differs
  /// between two screens is a growth bug nobody will ever file.
  ShareControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareControllerHash();

  @$internal
  @override
  ShareController create() => ShareController();
}

String _$shareControllerHash() => r'2f3a107e187358dd2091fe2d8724edbd9b4b3f9d';

/// Puts a captured card, or an invite, into the system share sheet.
///
/// Shared by the payoff screen and the compatibility flow. It lives
/// outside both because the *only* growth surface this product has is
/// people posting its output, and a share path that quietly differs
/// between two screens is a growth bug nobody will ever file.

abstract class _$ShareController extends $AsyncNotifier<void> {
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
