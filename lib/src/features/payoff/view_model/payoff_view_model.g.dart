// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payoff_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The reading built from the quiz answers.

@ProviderFor(reading)
final readingProvider = ReadingProvider._();

/// The reading built from the quiz answers.

final class ReadingProvider
    extends $FunctionalProvider<AsyncValue<Reading>, Reading, FutureOr<Reading>>
    with $FutureModifier<Reading>, $FutureProvider<Reading> {
  /// The reading built from the quiz answers.
  ReadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingHash();

  @$internal
  @override
  $FutureProviderElement<Reading> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Reading> create(Ref ref) {
    return reading(ref);
  }
}

String _$readingHash() => r'64731603b67c03dbe662e7fe809d7f28d1d75a4d';

/// Turns the card into an image and hands it to the share sheet.

@ProviderFor(ShareController)
final shareControllerProvider = ShareControllerProvider._();

/// Turns the card into an image and hands it to the share sheet.
final class ShareControllerProvider
    extends $AsyncNotifierProvider<ShareController, void> {
  /// Turns the card into an image and hands it to the share sheet.
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

String _$shareControllerHash() => r'f69c727f3cdb788dd134c3f79eb4377f408e62d8';

/// Turns the card into an image and hands it to the share sheet.

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
