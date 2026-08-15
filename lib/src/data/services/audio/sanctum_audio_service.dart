import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/services/audio/tone_audio_source.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/services/fade_envelope.dart';

/// A snapshot of the current session's progress.
///
/// Named to avoid colliding with `audio_service`'s own [PlaybackState],
/// which describes the *transport* (buffering, controls, system actions).
/// This one is about the session: how far through a twenty-minute sit the
/// user is, which the transport knows nothing about because the audio
/// underneath is a one-second loop.
class SessionPlaybackState {
  /// Creates a session playback state.
  const SessionPlaybackState({
    required this.playing,
    required this.position,
    required this.total,
    this.sessionId,
  });

  /// Nothing loaded.
  static const SessionPlaybackState idle = SessionPlaybackState(
    playing: false,
    position: Duration.zero,
    total: Duration.zero,
  );

  /// Whether audio is currently sounding.
  final bool playing;

  /// How far through the session.
  final Duration position;

  /// Total session length.
  final Duration total;

  /// Catalogue id of the loaded session, if any.
  final String? sessionId;

  /// Progress in `[0, 1]`.
  double get progress => total.inMilliseconds == 0
      ? 0
      : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
}

/// Plays sound-bath sessions.
///
/// Method names deliberately avoid `play`/`stop`/`seek`: the
/// implementation is a [BaseAudioHandler], which already defines those
/// with different signatures for the system transport controls.
abstract interface class SanctumAudioService {
  /// Live session progress.
  Stream<SessionPlaybackState> get sessionState;

  /// The session currently loaded, if any.
  SoundSession? get currentSession;

  /// Loads and begins [session].
  Future<Result<void>> start(SoundSession session);

  /// Resumes after a pause.
  Future<void> resume();

  /// Pauses, keeping the session loaded.
  Future<void> pauseSession();

  /// Fades out and unloads.
  Future<void> stopSession();

  /// Moves the reported progress.
  Future<void> seekTo(Duration position);
}

/// The one audio owner: a background-capable handler.
///
/// ## Why a handler rather than a plain player
///
/// A meditation is the archetypal thing you start and then put your
/// phone down for. Audio that dies the moment the screen locks — or the
/// moment you navigate back — is not a meditation player.
///
/// [BaseAudioHandler] puts playback in a foreground service on Android
/// and an audio background mode on iOS, which keeps it alive, and gets
/// lock-screen and notification controls for free.
///
/// ## What it owns
///
/// [ToneAudioSource] supplies one seamless cycle-aligned loop and the
/// player repeats it with `LoopMode.one`, so the audio layer has no idea
/// how long a session is. Session length therefore lives here as a clock,
/// and the fade lives here as a volume ramp.
class SanctumAudioHandler extends BaseAudioHandler
    with SeekHandler
    implements SanctumAudioService {
  /// Creates a handler, optionally over an existing [player].
  SanctumAudioHandler({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  /// How often session progress is published.
  static const Duration _tick = Duration(milliseconds: 250);

  /// Fade in at the start of a session and out at its end.
  static const Duration _fade = Duration(seconds: 4);

  /// Fade applied before a manual stop.
  ///
  /// Short enough to feel instant, long enough to remove the click. A
  /// sine cut mid-cycle is a step discontinuity, and a step is a click —
  /// which is exactly the tick you hear when leaving a session.
  static const Duration _stopFade = Duration(milliseconds: 220);

  final AudioPlayer _player;
  final _sessionState = StreamController<SessionPlaybackState>.broadcast();

  final _elapsed = Stopwatch();
  Duration _seekOffset = Duration.zero;

  Timer? _ticker;
  SoundSession? _session;
  double _volume = 0;
  bool _stopping = false;

  @override
  Stream<SessionPlaybackState> get sessionState => _sessionState.stream;

  @override
  SoundSession? get currentSession => _session;

  Duration get _position => _elapsed.elapsed + _seekOffset;

  @override
  Future<Result<void>> start(SoundSession session) {
    return Result.guard(
      () async {
        await _teardown(fade: false);
        _session = session;
        _stopping = false;

        await _player.setAudioSource(
          ToneAudioSource(frequencyHz: session.frequencyHz),
        );
        await _player.setLoopMode(LoopMode.one);
        await _setVolume(0);

        _seekOffset = Duration.zero;
        _elapsed
          ..reset()
          ..start();

        // Publishing a MediaItem is what puts the title, the frequency
        // and the duration on the lock screen.
        mediaItem.add(
          MediaItem(
            id: session.id,
            title: session.title,
            artist: 'Sanctum · ${session.frequencyLabel}',
            duration: session.duration,
          ),
        );

        await _player.play();
        _startTicker();
        _broadcast();
      },
      onError: (error, stackTrace) => AudioFailure(
        'Could not start ${session.title}',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  // ── Transport, driven by the UI *and* by the lock screen ──────────

  @override
  Future<void> play() => resume();

  @override
  Future<void> pause() => pauseSession();

  @override
  Future<void> stop() => stopSession();

  @override
  Future<void> seek(Duration position) => seekTo(position);

  @override
  Future<void> resume() async {
    final session = _session;
    if (session == null) return;

    _elapsed.start();
    await _player.play();

    // Fade back up rather than letting the next tick snap the volume
    // from 0 to full. pauseSession() ramps down to silence, so without
    // this the resume is a step discontinuity — the same click the
    // ramp-down exists to avoid, just in the other direction.
    _startTicker();
    await _fadeTo(_envelopeAt(_position, session.duration), _stopFade);
    _broadcast();
  }

  @override
  Future<void> pauseSession() async {
    _elapsed.stop();
    _ticker?.cancel();
    // Even a pause gets a short ramp. Pausing a pure tone at full
    // amplitude clicks just as a stop does.
    await _fadeTo(0, _stopFade);
    await _player.pause();
    _broadcast();
  }

  @override
  Future<void> stopSession() async {
    if (_stopping) return;
    _stopping = true;
    await _teardown(fade: true);
    mediaItem.add(null);
    _broadcast();
    _stopping = false;
  }

  @override
  Future<void> seekTo(Duration position) async {
    // The audio is a constant tone, so there is nothing to seek *to* —
    // only the reported progress moves.
    _seekOffset = position;
    _elapsed
      ..reset()
      ..start();
    _broadcast();
  }

  /// Releases the player. Called when the app is being torn down.
  Future<void> dispose() async {
    _ticker?.cancel();
    await _sessionState.close();
    await _player.dispose();
  }

  // ── Internals ─────────────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tick, (_) => unawaited(_onTick()));
  }

  Future<void> _onTick() async {
    final session = _session;
    if (session == null || _stopping) return;

    if (_position >= session.duration) {
      await stopSession();
      return;
    }

    await _setVolume(_envelopeAt(_position, session.duration));
    _broadcast();
  }

  Future<void> _teardown({required bool fade}) async {
    _ticker?.cancel();
    _ticker = null;

    if (fade && _player.playing) {
      await _fadeTo(0, _stopFade);
    }

    _elapsed
      ..stop()
      ..reset();
    _seekOffset = Duration.zero;
    _session = null;
    await _player.stop();
  }

  /// Ramps the volume to [target] over [duration].
  ///
  /// Stepped rather than instant, because neither ExoPlayer nor
  /// AVPlayer exposes a volume ramp through just_audio, and an abrupt
  /// change to a sustained sine is audible as a click.
  Future<void> _fadeTo(double target, Duration duration) async {
    const steps = 11;
    final from = _volume;
    final stepDelay = Duration(
      microseconds: duration.inMicroseconds ~/ steps,
    );

    for (var i = 1; i <= steps; i++) {
      await _setVolume(from + (target - from) * (i / steps));
      await Future<void>.delayed(stepDelay);
    }
  }

  Future<void> _setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if ((clamped - _volume).abs() < 0.001) return;
    _volume = clamped;
    await _player.setVolume(clamped);
  }

  /// The session fade envelope, delegated to pure domain logic.
  double _envelopeAt(Duration position, Duration total) =>
      FadeEnvelope.volumeAt(position: position, total: total, fade: _fade);

  void _broadcast() {
    final session = _session;
    final playing = _player.playing && session != null;

    _sessionState.add(
      SessionPlaybackState(
        playing: playing,
        position: session == null ? Duration.zero : _position,
        total: session?.duration ?? Duration.zero,
        sessionId: session?.id,
      ),
    );

    // The transport state the OS renders on the lock screen.
    playbackState.add(
      PlaybackState(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1],
        processingState: session == null
            ? AudioProcessingState.idle
            : AudioProcessingState.ready,
        playing: playing,
        updatePosition: session == null ? Duration.zero : _position,
      ),
    );
  }
}
