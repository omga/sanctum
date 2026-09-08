import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_composer.dart';
import 'package:sanctum/src/domain/services/palm_detector.dart';
import 'package:sanctum/src/features/palm/view/palm_reveal_timeline.dart';
import 'package:sanctum/src/features/palm/view/widgets/palm_guide_painter.dart';
import 'package:sanctum/src/features/palm/view/widgets/palm_reveal_painter.dart';
import 'package:sanctum/src/features/palm/view_model/palm_reading_view_model.dart';
import 'package:sanctum/src/features/palm/view_model/palm_scan_view_model.dart';
import 'package:sanctum/src/features/sharing/view_model/share_controller.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// The scan, from viewfinder to reveal.
///
/// ## Why this is one screen and not three
///
/// Aligning, capturing and revealing are stages of a single object that
/// exists only in memory. Nothing about a palm scan is persisted — that
/// is a deliberate answer to it being biometric data, not an oversight —
/// so a route that could be reached without going through the camera
/// would have nothing to show. Splitting them would invent a navigation
/// problem the feature does not have.
///
/// The reading *is* a separate route, because it is a separate product
/// with a price on it.
class PalmScanScreen extends ConsumerStatefulWidget {
  /// Creates the scan screen.
  const PalmScanScreen({super.key});

  @override
  ConsumerState<PalmScanScreen> createState() => _PalmScanScreenState();
}

class _PalmScanScreenState extends ConsumerState<PalmScanScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _revealKey = GlobalKey();

  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  ui.Image? _still;
  Object? _decodingFor;

  @override
  void initState() {
    super.initState();
    // Driven by real elapsed time rather than an AnimationController,
    // for the reason `PalmRevealTimeline` documents: the same
    // choreography has to run under the exporter's fixed step, and a
    // controller would couple it to this one.
    _ticker = createTicker((elapsed) {
      if (elapsed > PalmRevealTimeline.total) {
        _ticker.stop();
        setState(() => _elapsed = PalmRevealTimeline.total);
        return;
      }
      setState(() => _elapsed = elapsed);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(palmScanViewModelProvider.notifier).start());
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _still?.dispose();
    super.dispose();
  }

  /// Decodes the captured still once, when it arrives.
  ///
  /// Kept out of the view model so that layer never touches `dart:ui`
  /// and stays testable without a binding — the state carries bytes, and
  /// turning bytes into something paintable is a presentation job.
  Future<void> _decode(PalmFrameImage image) async {
    if (identical(_decodingFor, image)) return;
    _decodingFor = image;
    final decoded = await decodeImageFromList(image.bytes);
    if (!mounted) {
      decoded.dispose();
      return;
    }
    setState(() {
      _still?.dispose();
      _still = decoded;
    });
  }

  Future<void> _share(PalmReading reading) async {
    await ref
        .read(shareControllerProvider.notifier)
        .share(
          _revealKey,
          text: context.l10n.palmEntryHint,
        );
    // Recorded whatever the sheet reported. The platform only ever says
    // an app was picked, and withholding the reading from somebody who
    // did share is the worse of the two failures — see PalmGate.
    await ref.read(palmUnlockControllerProvider.notifier).recordShare();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(palmScanViewModelProvider);

    if (state.still case final still? when state.reading != null) {
      unawaited(_decode(still));
    }

    ref.listen(palmScanViewModelProvider, (previous, next) {
      if (previous?.stage != next.stage &&
          next.stage == PalmScanStage.revealed) {
        _elapsed = Duration.zero;
        _ticker.start();
      }
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n.palmTitle),
      ),
      extendBodyBehindAppBar: true,
      body: switch (state.stage) {
        PalmScanStage.revealed => _Reveal(
          reading: state.reading!,
          still: _still,
          elapsed: _elapsed,
          revealKey: _revealKey,
          onShare: () => unawaited(_share(state.reading!)),
          onRetake: () => unawaited(
            ref.read(palmScanViewModelProvider.notifier).retake(),
          ),
        ),
        PalmScanStage.failed => _Failed(
          message: state.failure?.message ?? '',
          onRetake: () => unawaited(
            ref.read(palmScanViewModelProvider.notifier).retake(),
          ),
        ),
        _ => _Viewfinder(state: state),
      },
    );
  }
}

/// The live camera stage.
class _Viewfinder extends ConsumerWidget {
  const _Viewfinder({required this.state});

  final PalmScanState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(palmPreviewBuilderProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (preview != null)
          preview(context)
        else
          // The developer-facing hole where a camera will go. It says so
          // rather than showing a plausible dark rectangle, because a
          // viewfinder that looks like it is working and is not is the
          // single most confusing thing this screen could do.
          Center(
            child: Padding(
              padding: const EdgeInsets.all(SanctumSpacing.xl),
              child: Text(
                context.l10n.palmCameraUnavailable,
                textAlign: TextAlign.center,
                style: context.type.bodyMedium.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
            ),
          ),
        // Legibility, not decoration. Everything on this screen is white
        // text and a thin outline over whatever the lens happens to be
        // pointing at; against a bright wall the app bar, the back
        // arrow and the instruction all vanish, and a viewfinder with
        // nothing readable on it reads as an app that has failed to
        // load rather than one waiting for a hand.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99000000),
                Color(0x00000000),
                Color(0x00000000),
                Color(0xB3000000),
              ],
              stops: [0, 0.22, 0.55, 1],
            ),
          ),
          child: SizedBox.expand(),
        ),
        CustomPaint(
          painter: PalmGuidePainter(
            colors: context.colors,
            hold: state.holdProgress,
            frame: state.preview,
            isReady: state.readiness.isReady,
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.62),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SanctumSpacing.xl,
            ),
            child: Text(
              state.stage == PalmScanStage.capturing
                  ? context.l10n.palmCapturing
                  : _hintFor(context, state.readiness),
              textAlign: TextAlign.center,
              style: context.type.title.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The instruction for [readiness].
///
/// Exhaustive on purpose: a new readiness case must not be able to
/// compile into a blank viewfinder.
String _hintFor(BuildContext context, PalmReadiness readiness) =>
    switch (readiness) {
      PalmReadiness.ready => context.l10n.palmHintReady,
      PalmReadiness.noHand => context.l10n.palmHintNoHand,
      PalmReadiness.lowConfidence => context.l10n.palmHintLowConfidence,
      PalmReadiness.tooSmall => context.l10n.palmHintTooSmall,
      PalmReadiness.offCentre => context.l10n.palmHintOffCentre,
      PalmReadiness.backOfHand => context.l10n.palmHintBackOfHand,
      PalmReadiness.fingersClosed => context.l10n.palmHintFingersClosed,
      PalmReadiness.tooOblique => context.l10n.palmHintTooOblique,
    };

/// The reveal, and what to do once it has played.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.reading,
    required this.still,
    required this.elapsed,
    required this.revealKey,
    required this.onShare,
    required this.onRetake,
  });

  final PalmReading reading;
  final ui.Image? still;
  final Duration elapsed;
  final GlobalKey revealKey;
  final VoidCallback onShare;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final frame = PalmRevealTimeline.at(elapsed, lines: reading.claimed);
    final isFinished = elapsed >= PalmRevealTimeline.total;

    return Column(
      children: [
        Expanded(
          // The boundary the share captures. It works here and would not
          // over a live camera: a preview is a platform view and comes
          // back as a blank hole, which is the whole reason the reveal is
          // rendered from a still.
          child: RepaintBoundary(
            key: revealKey,
            child: CustomPaint(
              size: Size.infinite,
              painter: PalmRevealPainter(
                frame: frame,
                curves: reading.curves,
                colors: context.colors,
                photo: still,
                labelStyle: context.type.label.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 1.4,
                ),
                verdictStyle: context.type.displaySmall.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: isFinished ? 1 : 0,
          duration: const Duration(milliseconds: 320),
          child: Padding(
            padding: const EdgeInsets.all(SanctumSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.palmDisclaimer,
                  style: context.type.caption.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
                const SizedBox(height: SanctumSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: SanctumButton(
                        label: context.l10n.palmShare,
                        onPressed: isFinished ? onShare : null,
                        variant: SanctumButtonVariant.ghost,
                        expand: true,
                      ),
                    ),
                    const SizedBox(width: SanctumSpacing.sm),
                    Expanded(
                      child: SanctumButton(
                        label: context.l10n.palmSeeReading,
                        onPressed: isFinished
                            ? () =>
                                  PalmReadingRoute(scanId: reading.id)
                                      .push<void>(context)
                            : null,
                        expand: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SanctumSpacing.sm),
                SanctumButton(
                  label: context.l10n.palmRetake,
                  onPressed: onRetake,
                  variant: SanctumButtonVariant.quiet,
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Anything that went wrong, and the one thing to do about it.
class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetake});

  final String message;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) => AuroraBackground(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(SanctumSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.type.title.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: SanctumSpacing.lg),
            SanctumButton(
              label: context.l10n.palmRetake,
              onPressed: onRetake,
            ),
          ],
        ),
      ),
    ),
  );
}
