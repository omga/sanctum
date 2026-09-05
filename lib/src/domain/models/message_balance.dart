/// What the user has left to spend on advisor messages.
///
/// ## Why one balance and not a cap per conversation
///
/// The unit sold is a message, and the allowance is shared: somebody
/// with twenty saved matches has the same five free messages a week as
/// somebody with one. A per-conversation cap would make the cost of a
/// subscriber unbounded in the number of pairings they happen to have
/// checked, which is exactly the number this app encourages them to
/// grow.
///
/// ## Why this is not a credit ledger
///
/// `roadmap.md` §1 rejects a ledger, and this is deliberately less than
/// one: three fields, no expiry on what was bought, no packs, no
/// transaction history, nothing to reconcile. The weekly grant is a
/// period string and a counter rather than a balance that accrues — an
/// unspent week is gone, not banked, which is what keeps this from
/// becoming an economy that needs one.
class MessageBalance {
  /// Creates a balance.
  const MessageBalance({
    this.freeWeek,
    this.freeUsed = 0,
    this.purchased = 0,
  });

  /// Nothing spent, nothing bought.
  static const MessageBalance empty = MessageBalance();

  /// The week [freeUsed] counts against, or null if none has been spent.
  ///
  /// Stored rather than derived so that a week rolling over is detected
  /// by comparison instead of by a timer, and so the app can be closed
  /// for a month without losing track of which week the count belongs
  /// to.
  final String? freeWeek;

  /// Free messages spent inside [freeWeek].
  final int freeUsed;

  /// Bought messages remaining.
  ///
  /// No expiry, deliberately. A message somebody paid for that quietly
  /// evaporates on a Sunday is a refund request, and the weekly reset
  /// only makes sense for the ones that were free.
  final int purchased;

  /// A copy with the given fields replaced.
  MessageBalance copyWith({
    String? freeWeek,
    int? freeUsed,
    int? purchased,
  }) => MessageBalance(
    freeWeek: freeWeek ?? this.freeWeek,
    freeUsed: freeUsed ?? this.freeUsed,
    purchased: purchased ?? this.purchased,
  );
}
