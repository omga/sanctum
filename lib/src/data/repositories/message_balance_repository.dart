import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/domain/models/message_balance.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores what the user has left to spend on advisor messages.
abstract interface class MessageBalanceRepository {
  /// The current balance.
  Future<Result<MessageBalance>> read();

  /// Replaces it.
  Future<Result<void>> write(MessageBalance balance);
}

/// [MessageBalanceRepository] backed by shared_preferences.
///
/// ## Why not Drift, when conversations are
///
/// Three integers read at gate time, and — the part that decides it —
/// **they must survive a database wipe**. Transcripts are content and
/// live with the rest of the content; a balance is a receipt, and it
/// belongs with the owned-report ids in preferences for exactly the
/// reason those are there: a user who clears storage, or a migration
/// that goes wrong, must not lose messages they paid for.
class PreferencesMessageBalanceRepository
    implements MessageBalanceRepository {
  /// Creates a repository.
  const PreferencesMessageBalanceRepository();

  static const _weekKey = 'sanctum.messages.free_week';
  static const _usedKey = 'sanctum.messages.free_used';
  static const _purchasedKey = 'sanctum.messages.purchased';

  @override
  Future<Result<MessageBalance>> read() {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        return MessageBalance(
          freeWeek: prefs.getString(_weekKey),
          freeUsed: prefs.getInt(_usedKey) ?? 0,
          purchased: prefs.getInt(_purchasedKey) ?? 0,
        );
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not read the message balance',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> write(MessageBalance balance) {
    return Result.guard(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final week = balance.freeWeek;
        if (week == null) {
          await prefs.remove(_weekKey);
        } else {
          await prefs.setString(_weekKey, week);
        }
        await prefs.setInt(_usedKey, balance.freeUsed);
        await prefs.setInt(_purchasedKey, balance.purchased);
      },
      onError: (error, stackTrace) => StorageFailure(
        'Could not save the message balance',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
