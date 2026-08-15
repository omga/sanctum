import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/services/audio/sanctum_audio_service.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/services/playback_intent.dart';
import 'package:sanctum/src/features/sessions/view/widgets/breathing_halo.dart';

/// Plays one sound-bath session.
class SessionPlayerScreen extends ConsumerStatefulWidget {
  /// Creates the player for [sessionId].
  const SessionPlayerScreen({required this.sessionId, super.key});

  /// Catalogue id of the session.
  final String sessionId;

  @override
  ConsumerState<SessionPlayerScreen> createState() =>
      _SessionPlayerScreenState();
}

class _SessionPlayerScreenState extends ConsumerState<SessionPlayerScreen> {
  SoundSession? _session;
  DateTime? _startedAt;
  SanctumAudioService? _audio;

  /// The session a load has already been requested for.
  ///
  /// Distinct from [_session], which is only set once the load finishes.
  String? _requestedSessionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Captured here rather than read in dispose(): by the time
    // State.dispose runs, `ref` is already disposed and reading it is an
    // error (riverpod_lint's avoid_ref_inside_state_dispose). The service
    // itself is keepAlive, so it long outlives this widget.
    _audio ??= ref.read(audioServiceProvider);
  }

  @override
  void dispose() {
    // Deliberately does NOT stop playback.
    //
    // A meditation is the archetypal thing you start and then put the
    // phone down for. Audio now runs in a background service with
    // lock-screen controls, so navigating away leaves the session
    // running and the notification is how you stop it.
    super.dispose();
  }

  Future<void> _start(SoundSession session) async {
    _session = session;
    _startedAt = ref.read(clockProvider).now();
    await ref.read(audioServiceProvider).start(session);
  }

  /// Records a completion once enough of the session has been heard.
  ///
  /// The bar is 60% rather than 100%: someone who sits for twelve minutes
  /// of a twenty-minute session practised, and breaking their streak on a
  /// technicality is a good way to lose them.
  Future<void> _maybeRecord(SessionPlaybackState state) async {
    final session = _session;
    final started = _startedAt;
    if (session == null || started == null) return;
    if (state.progress < 0.6) return;

    _startedAt = null; // record at most once per visit
    await ref
        .read(practiceRepositoryProvider)
        .recordCompletion(
          sessionId: session.id,
          completedAt: ref.read(clockProvider).now(),
          listened: state.position,
        );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(contentCatalogProvider);
    final playback =
        ref.watch(sessionPlaybackProvider).value ?? SessionPlaybackState.idle;

    ref.listen(sessionPlaybackProvider, (_, next) {
      final value = next.value;
      if (value != null) unawaited(_maybeRecord(value));
    });

    return Scaffold(
      body: AuroraBackground(
        intensity: 1.25,
        child: Starfield(
          child: SafeArea(
            child: catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (data) {
                final session = data.sessionById(widget.sessionId);
                if (session == null) {
                  return const Center(child: Text('Session not found'));
                }
                // The guard is set HERE, synchronously, not inside
                // _start.
                //
                // build() re-runs on every position tick — roughly ten
                // times a second. _start is async, so if the flag were
                // only set once it completed, every rebuild in that
                // window would schedule another load. Each load calls
                // setAudioSource and begins synthesising a fresh
                // session, so re-entering this screen spawned several
                // concurrent generators at once. That is what turned a
                // slow first open into a frozen second one.
                // Re-entering the screen for a session that is already
                // running must not restart it from zero — which is
                // exactly what would happen now that leaving no longer
                // stops playback.
                final alreadyRunning = _audio?.currentSession?.id == session.id;
                if (_requestedSessionId != session.id && !alreadyRunning) {
                  _requestedSessionId = session.id;
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => unawaited(_start(session)),
                  );
                } else if (alreadyRunning) {
                  _requestedSessionId = session.id;
                  _session ??= session;
                }
                return _PlayerBody(
                  session: session,
                  playback: playback,
                  onStart: () => unawaited(_start(session)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerBody extends ConsumerWidget {
  const _PlayerBody({
    required this.session,
    required this.playback,
    required this.onStart,
  });

  final SoundSession session;
  final SessionPlaybackState playback;

  /// Routed back through the State rather than calling the service
  /// directly, so a restart still records when it began — otherwise a
  /// session resumed after a stop would never count toward the streak.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final type = context.type;
    final audio = ref.read(audioServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(SanctumSpacing.xl),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              color: colors.textSecondary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const Spacer(),
          BreathingHalo(active: playback.playing),
          const SizedBox(height: SanctumSpacing.xxl),
          Text(session.title, style: type.displayMedium),
          const SizedBox(height: SanctumSpacing.xs),
          Text(
            '${session.frequencyLabel}  ·  ${session.chakra.displayName}',
            style: type.caption.copyWith(color: colors.gold),
          ),
          const SizedBox(height: SanctumSpacing.lg),
          Text(
            session.intention,
            textAlign: TextAlign.center,
            style: type.bodyMedium,
          ),
          const Spacer(),
          _Progress(playback: playback),
          const SizedBox(height: SanctumSpacing.xl),
          _PlayButton(
            playing: playback.playing,
            onToggle: () {
              // Ask what the tap means rather than assuming it is always
              // resume. After a stop from the notification the handler
              // holds no session, and resuming nothing did nothing — the
              // button looked alive and was dead.
              final action = PlaybackIntent.forToggle(
                isPlaying: playback.playing,
                loadedSessionId: audio.currentSession?.id,
                screenSessionId: session.id,
              );

              switch (action) {
                case PlaybackAction.start:
                  onStart();
                case PlaybackAction.resume:
                  unawaited(audio.resume());
                case PlaybackAction.pause:
                  unawaited(audio.pauseSession());
              }
            },
          ),
          const SizedBox(height: SanctumSpacing.xl),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.playback});

  final SessionPlaybackState playback;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: playback.progress,
            minHeight: 3,
            backgroundColor: colors.glassBorder,
            valueColor: AlwaysStoppedAnimation(colors.gold),
          ),
        ),
        const SizedBox(height: SanctumSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_format(playback.position), style: context.type.caption),
            Text(_format(playback.total), style: context.type.caption),
          ],
        ),
      ],
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onToggle});

  final bool playing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [colors.accentSecondary, colors.accent],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.4),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: SanctumMotion.quick,
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(playing),
            size: 34,
            color: colors.textOnAccent,
          ),
        ),
      ),
    );
  }
}
