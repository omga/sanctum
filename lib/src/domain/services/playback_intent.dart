/// What tapping the play/pause button should actually do.
enum PlaybackAction {
  /// Load the session and begin from the start.
  start,

  /// Continue a session that is loaded but paused.
  resume,

  /// Pause the session that is currently sounding.
  pause,
}

/// Decides what the transport button means right now.
///
/// ## Why this is not just `playing ? pause : resume`
///
/// That was the bug. Stopping from the lock screen unloads the session
/// entirely, so the handler holds no session at all — and `resume()` on
/// nothing is a no-op. The button then looked enabled and did nothing,
/// permanently, until the user backed out and re-entered the screen.
///
/// The missing case is "the screen is showing a session the player is not
/// holding", which happens after any stop, after the session runs to its
/// end, and whenever another session was started in between. All three
/// mean *start*, not *resume*.
abstract final class PlaybackIntent {
  /// Resolves the action for a tap.
  ///
  /// [loadedSessionId] is what the audio handler currently holds, which
  /// is `null` once stopped. [screenSessionId] is the session the user is
  /// looking at.
  static PlaybackAction forToggle({
    required bool isPlaying,
    required String? loadedSessionId,
    required String screenSessionId,
  }) {
    // A different session — or none at all — always means start.
    if (loadedSessionId != screenSessionId) return PlaybackAction.start;
    return isPlaying ? PlaybackAction.pause : PlaybackAction.resume;
  }
}
