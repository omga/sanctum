import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/element_palette.dart';

/// The headline score, as a ring that fills and a number that counts.
///
/// ## Why it animates rather than appearing
///
/// This is the shot. Everything else on the screen is text, and text is
/// a screenshot; a ring closing while a number climbs is three seconds
/// of watchable video, which is the format the whole acquisition plan
/// depends on. The curve decelerates hard at the end so the last few
/// points crawl — the number arriving is the beat people cut to.
///
/// The ring is a sweep of *both* people's element colours, so the graphic
/// is literally made of the two of them rather than being generic chrome.
class ScoreDial extends StatelessWidget {
  /// Creates a dial.
  const ScoreDial({
    required this.score,
    required this.verdict,
    required this.yours,
    required this.theirs,
    this.size = 220,
    this.animate = true,
    super.key,
  });

  /// The score to show, 0–100.
  final int score;

  /// One word for the band, drawn under the number.
  final String verdict;

  /// The user's element, the first colour of the sweep.
  final ZodiacElement yours;

  /// Their element, the second.
  final ZodiacElement theirs;

  /// Diameter.
  final double size;

  /// Whether to run the count-up. Off when capturing to an image.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? 0 : score.toDouble(), end: score * 1.0),
        duration: animate
            ? const Duration(milliseconds: 1400)
            : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _DialPainter(
            progress: value / 100,
            track: colors.glassBorder,
            from: ElementPalette.lead(yours, colors),
            to: ElementPalette.lead(theirs, colors),
            glow: colors.glow,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.round()}',
                      style: type.displayLarge.copyWith(
                        fontSize: size * 0.30,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: SanctumSpacing.sm),
                      child: Text(
                        '%',
                        style: type.title.copyWith(color: colors.gold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SanctumSpacing.xs),
                Text(
                  verdict.toUpperCase(),
                  style: type.caption.copyWith(
                    color: colors.gold,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.progress,
    required this.track,
    required this.from,
    required this.to,
    required this.glow,
  });

  final double progress;
  final Color track;
  final Color from;
  final Color to;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    // Start at the top and sweep clockwise, which is the direction every
    // ring gauge on every phone already turns.
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = track,
    );

    if (progress <= 0) return;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + 2 * math.pi,
        colors: [from, to, from],
      ).createShader(rect);

    canvas
      // A soft pass under the arc so the ring glows rather than just
      // being a coloured line on a dark background.
      ..drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round
          ..color = glow.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      )
      ..drawArc(rect, start, sweep, false, stroke);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.from != from || old.to != to;
}
