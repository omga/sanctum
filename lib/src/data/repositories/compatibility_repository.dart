import 'dart:convert';

import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores matches and what the user has unlocked.
abstract interface class CompatibilityRepository {
  /// The saved state, empty on first run.
  Future<Result<CompatibilityState>> load();

  /// Records that an invite was sent. Unlocks the first reveal.
  Future<Result<void>> recordInviteSent();

  /// Saves [match] and marks it revealed.
  Future<Result<void>> reveal(CompatibilityMatch match);
}

/// [CompatibilityRepository] backed by shared_preferences.
class PreferencesCompatibilityRepository
    implements CompatibilityRepository {
  /// Creates a repository.
  const PreferencesCompatibilityRepository();

  static const _key = 'sanctum.compatibility';

  @override
  Future<Result<CompatibilityState>> load() {
    return Result.guard(
      _read,
      // Losing this blob costs the user their match history, which is
      // annoying; refusing to open the tab because of it would be worse.
      onError: (error, stackTrace) => StorageFailure(
        'Could not read your matches',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> recordInviteSent() => _update(
    (state) => state.copyWith(hasSharedInvite: true),
  );

  @override
  Future<Result<void>> reveal(CompatibilityMatch match) => _update((state) {
    // Re-revealing is a no-op rather than a duplicate: the id set is what
    // the gate counts, and counting the same match twice would spend a
    // free reveal the user already spent.
    final matches = [
      match,
      ...state.matches.where((one) => one.id != match.id),
    ];
    final revealed = {...state.revealedIds, match.id}.toList();
    return state.copyWith(matches: matches, revealedIds: revealed);
  });

  /// Reads the blob, treating anything unreadable as an empty history.
  ///
  /// Swallowing the parse error is deliberate. This blob's shape changes
  /// whenever the reading model does, and a stored match written by an
  /// older build will not deserialise. If that propagated, every future
  /// *write* would fail too — the read happens first — and the tab would
  /// be permanently unable to save anything. Losing old matches on an
  /// upgrade is a small cost; a feature that silently stops working
  /// forever is not.
  Future<CompatibilityState> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const CompatibilityState();

    try {
      return CompatibilityStateMapper.fromMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return const CompatibilityState();
    }
  }

  Future<Result<void>> _update(
    CompatibilityState Function(CompatibilityState) change,
  ) {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final next = change(await _read());
        await prefs.setString(_key, jsonEncode(next.toMap()));
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save your match',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
