import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/element_palette.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/sign_avatar.dart';
import 'package:sanctum/src/l10n/l10n.dart';

/// The wait before a reading opens.
///
/// ## Why a product adds a delay on purpose
///
/// The reading is already computed — the ephemeris runs in under a
/// millisecond — so this is theatre, and worth being honest about that.
/// It earns its place twice over. A number that appears instantly reads
/// as a lookup; the same number after something visibly *works* for it
/// reads as a result, and this is the screen the whole acquisition plan
/// asks people to film. Three seconds of watchable build-up is the
/// difference between a screenshot and a clip.
///
/// ## The captions are true
///
/// Each line names something the engine genuinely does: it places the
/// planets from Keplerian elements, it reads Venus and Mars, it measures
/// the angles between them, it scores six facets. That matters in an app
/// whose credibility rests on not overclaiming — inventing steps here
/// would be the same lie as inventing a compatibility score, just
/// prettier. Do not add a caption for work that does not happen.
///
/// It only ever runs once per match. A reading being re-opened is not a
/// reveal, and making somebody wait to re-read their own result is
/// friction with no payoff.
class MatchComputing extends StatefulWidget {
  /// Creates the sequence.
  const MatchComputing({
    required this.match,
    required this.onDone,
    super.key,
  });

  /// The pairing being read, for the two discs and their colours.
  final CompatibilityMatch match;

  /// Called once, when the last step finishes.
  final VoidCallback onDone;

  /// How many steps the sequence has.
  ///
  /// A separate constant from the captions because [total] is used to
  /// time the transition and must stay computable without a context.
  static const int stepCount = 4;

  /// What the engine is doing, in the order it does it.
  static List<String> stepsFor(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.computingStep1,
      l10n.computingStep2,
      l10n.computingStep3,
      l10n.computingStep4,
    ];
  }

  /// How long each caption holds.
  static const Duration stepDuration = Duration(milliseconds: 720);

  /// Total time before the reading opens.
  static Duration get total => stepDuration * stepCount;

  @override
  State<MatchComputing> createState() => _MatchComputingState();
}

class _MatchComputingState extends State<MatchComputing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(MatchComputing.stepDuration, (timer) {
      if (!mounted) return;
      if (_step >= MatchComputing.stepCount - 1) {
        timer.cancel();
        widget.onDone();
        return;
      }
      setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final match = widget.match;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: AnimatedBuilder(
              animation: _orbit,
              builder: (context, child) => CustomPaint(
                painter: _OrbitPainter(
                  turns: _orbit.value,
                  yours: ElementPalette.lead(match.you.sign.element, colors),
                  theirs: ElementPalette.lead(match.them.sign.element, colors),
                  progress: (_step + 1) / MatchComputing.stepCount,
                  track: colors.glassBorder,
                ),
                child: child,
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SignAvatar(sign: match.you.sign, size: 62),
                    const SizedBox(width: SanctumSpacing.xs),
                    SignAvatar(sign: match.them.sign, size: 62),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: SanctumSpacing.xxl),

          // A fixed height, because the captions differ in length and a
          // column that resizes under them makes the discs above jump.
          SizedBox(
            height: 34,
            child: AnimatedSwitcher(
              duration: SanctumMotion.calm,
              child: Text(
                MatchComputing.stepsFor(context)[_step],
                key: ValueKey(_step),
                style: type.title.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two arcs chasing each other, and a ring that fills as steps complete.
class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.turns,
    required this.yours,
    required this.theirs,
    required this.progress,
    required this.track,
  });

  final double turns;
  final Color yours;
  final Color theirs;
  final double progress;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final sweep = turns * 2 * math.pi;

    canvas
      ..drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = track,
      )
      // Each person's arc runs in the opposite direction, so the two
      // meet and part rather than travelling as one.
      ..drawArc(
        rect,
        sweep,
        math.pi * 0.55,
        false,
        _arc(yours, radius),
      )
      ..drawArc(
        rect,
        -sweep + math.pi,
        math.pi * 0.55,
        false,
        _arc(theirs, radius),
      )
      // The honest part: a ring that tracks real progress through the
      // steps, so the wait has a visible end.
      ..drawArc(
        rect.deflate(8),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = yours.withValues(alpha: 0.5),
      );
  }

  Paint _arc(Color color, double radius) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..shader = SweepGradient(
      colors: [color.withValues(alpha: 0), color],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius))
    ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.turns != turns || old.progress != progress;
}
