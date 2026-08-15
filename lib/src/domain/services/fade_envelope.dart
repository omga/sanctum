/// The volume shape of a session, from silence to silence.
///
/// ## Why this is not decoration
///
/// A sustained sine wave that begins or ends abruptly is a step
/// discontinuity, and a step discontinuity is a click. Users do not hear
/// "the tone stopped"; they hear a tick, and a tick sounds like a bug.
///
/// The envelope is pure arithmetic over positions, so it lives here and
/// is tested exhaustively, rather than being buried in the audio service
/// where it could only be verified by ear.
abstract final class FadeEnvelope {
  /// Volume multiplier in `[0, 1]` at [position] through [total].
  ///
  /// Ramps up over [fade] at the start and back down over [fade] at the
  /// end. Sessions shorter than two fades never reach full volume, which
  /// is correct: better quiet than clipped.
  static double volumeAt({
    required Duration position,
    required Duration total,
    required Duration fade,
  }) {
    if (total <= Duration.zero) return 0;
    if (fade <= Duration.zero) return 1;

    final fadeMs = fade.inMilliseconds;
    final positionMs = position.inMilliseconds;
    final remainingMs = total.inMilliseconds - positionMs;

    if (positionMs <= 0 || remainingMs <= 0) return 0;

    // Whichever ramp is lower wins, so a very short session simply
    // peaks lower rather than fading up and down past each other.
    final rising = positionMs / fadeMs;
    final falling = remainingMs / fadeMs;
    final value = rising < falling ? rising : falling;

    return value.clamp(0.0, 1.0);
  }
}
