import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/playback_intent.dart';

PlaybackAction action({
  required bool playing,
  String? loaded,
  String screen = 'grounding',
}) => PlaybackIntent.forToggle(
  isPlaying: playing,
  loadedSessionId: loaded,
  screenSessionId: screen,
);

void main() {
  group('PlaybackIntent', () {
    test('pauses the session that is currently sounding', () {
      expect(
        action(playing: true, loaded: 'grounding'),
        PlaybackAction.pause,
      );
    });

    test('resumes a loaded session that is paused', () {
      expect(
        action(playing: false, loaded: 'grounding'),
        PlaybackAction.resume,
      );
    });

    test('starts again after the session was stopped', () {
      // THE REGRESSION. Stopping from the notification unloads the
      // session, so the handler holds nothing. Treating this as "resume"
      // is a no-op and the play button dies silently.
      expect(
        action(playing: false, loaded: null),
        PlaybackAction.start,
      );
    });

    test('starts when a different session is loaded', () {
      expect(
        action(playing: true, loaded: 'heart-tone'),
        PlaybackAction.start,
      );
      expect(
        action(playing: false, loaded: 'heart-tone'),
        PlaybackAction.start,
      );
    });

    test('never resolves to resume when nothing is loaded', () {
      for (final playing in [true, false]) {
        expect(
          action(playing: playing, loaded: null),
          isNot(PlaybackAction.resume),
          reason: 'resume on an unloaded handler does nothing',
        );
      }
    });
  });
}
