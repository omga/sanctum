// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every entry, newest first.

@ProviderFor(journalEntries)
final journalEntriesProvider = JournalEntriesProvider._();

/// Every entry, newest first.

final class JournalEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JournalEntry>>,
          List<JournalEntry>,
          Stream<List<JournalEntry>>
        >
    with
        $FutureModifier<List<JournalEntry>>,
        $StreamProvider<List<JournalEntry>> {
  /// Every entry, newest first.
  JournalEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<JournalEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<JournalEntry>> create(Ref ref) {
    return journalEntries(ref);
  }
}

String _$journalEntriesHash() => r'8afe472ced217f103b85becb4eba7c1fbc607b0c';

/// Writes to the journal.

@ProviderFor(JournalController)
final journalControllerProvider = JournalControllerProvider._();

/// Writes to the journal.
final class JournalControllerProvider
    extends $AsyncNotifierProvider<JournalController, void> {
  /// Writes to the journal.
  JournalControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalControllerHash();

  @$internal
  @override
  JournalController create() => JournalController();
}

String _$journalControllerHash() => r'9d44820e2aef80e637311eb0a232e732b9658f09';

/// Writes to the journal.

abstract class _$JournalController extends $AsyncNotifier<void> {
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
