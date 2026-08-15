import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';

part 'journal_view_model.g.dart';

/// Every entry, newest first.
@riverpod
Stream<List<JournalEntry>> journalEntries(Ref ref) =>
    ref.watch(journalRepositoryProvider).watchEntries();

/// Writes to the journal.
@riverpod
class JournalController extends _$JournalController {
  @override
  FutureOr<void> build() {}

  /// Saves a new entry.
  Future<void> add({
    required JournalKind kind,
    required String body,
    String? prompt,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(journalRepositoryProvider)
        .add(
          kind: kind,
          body: body,
          createdAt: ref.read(clockProvider).now(),
          prompt: prompt,
        );
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  /// Removes an entry.
  Future<void> delete(int id) async {
    state = const AsyncLoading();
    final result = await ref.read(journalRepositoryProvider).delete(id);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
