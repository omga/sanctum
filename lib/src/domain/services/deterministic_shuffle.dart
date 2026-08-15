/// A tiny, fully specified pseudo-random generator.
///
/// ## Why not `dart:math`'s Random(seed)?
///
/// Because `Random(seed)` guarantees *a* deterministic sequence, not a
/// *specific* one. Its algorithm is an implementation detail the SDK is
/// free to change. If it ever did, every user's daily card would silently
/// reshuffle on the day they upgraded — the one thing the daily card must
/// never do.
///
/// xorshift32 is eight lines, fully specified here, and therefore frozen
/// for as long as this file is. Quality is far beyond what picking a card
/// from a list requires; it is not, and must not be used as, a source of
/// cryptographic randomness.
final class Xorshift32 {
  /// Creates a generator seeded with [seed].
  Xorshift32(int seed)
    // A zero state is a fixed point for xorshift — it would emit zero
    // forever. Substitute the golden-ratio constant.
    : _state = (seed & 0xFFFFFFFF) == 0 ? 0x9E3779B9 : seed & 0xFFFFFFFF;

  int _state;

  /// The next 32-bit value in the sequence.
  int next() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    return _state = x & 0xFFFFFFFF;
  }

  /// A value in `[0, max)`.
  int nextInt(int max) {
    assert(max > 0, 'max must be positive');
    return next() % max;
  }
}

/// Deterministic hashing and shuffling used by daily content selection.
abstract final class DeterministicShuffle {
  /// FNV-1a, 32-bit.
  ///
  /// Used instead of [Object.hashCode] because Dart's string hash is not
  /// guaranteed stable across SDK versions or isolates — again, fine for
  /// a hash map, fatal for something that must produce the same answer
  /// on every device forever.
  static int hash(String input) {
    const prime = 0x01000193;
    var result = 0x811C9DC5;
    for (final unit in input.codeUnits) {
      result ^= unit;
      result = (result * prime) & 0xFFFFFFFF;
    }
    return result;
  }

  /// Returns a shuffled copy of [items] determined entirely by [seed].
  ///
  /// Fisher-Yates, walked backwards. Same seed, same order, every time.
  static List<T> shuffled<T>(List<T> items, int seed) {
    final result = List<T>.of(items);
    final random = Xorshift32(seed);
    for (var i = result.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result;
  }
}
