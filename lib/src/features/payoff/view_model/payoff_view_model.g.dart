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
