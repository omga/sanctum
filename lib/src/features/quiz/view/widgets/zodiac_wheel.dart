import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_typography.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';

/// An arc of the twelve signs that turns to the user's own sign.
///
/// This is the best beat in the whole flow: the user scrolls a date and
/// the wheel answers *before* they have committed to anything. It is the
/// first moment the app demonstrably knows something about them, and it
/// costs nothing because the sign is computed locally.
///
/// The rotation is animated rather than snapped — the wheel turning to
/// find you reads as the app thinking, where an instant jump reads as a
/// lookup table.
class ZodiacWheel extends StatelessWidget {
  /// Creates a wheel highlighting [sign].
  const ZodiacWheel({required this.sign, this.size = 260, super.key});

  /// The sign to point at.
  final ZodiacSign sign;

  /// Width of the arc.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = ZodiacSign.values.indexOf(sign);

    // Rotate so the active sign lands under the pointer at the top of
    // the arc. Glyph i sits at `pi + slice/2 + i*slice`, and the top of
    // the circle is `3*pi/2`, so the offset is the difference — not
    // simply `-index * slice`, which leaves the wheel short by a quarter
    // turn and points at a gap.
    const slice = math.pi / 12;
    final target = math.pi / 2 - slice / 2 - index * slice;

    return SizedBox(
      width: size,
      height: size * 0.62,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: target, end: target),
        duration: SanctumMotion.calm,
        curve: SanctumMotion.ease,
        builder: (context, rotation, _) {
          return CustomPaint(
            painter: _WheelPainter(
              rotation: rotation,
              activeIndex: index,
              arc: colors.accent,
              glow: colors.accentSecondary,
              ink: colors.textPrimary,
              dim: colors.textTertiary,
              gold: colors.gold,
            ),
          );
        },
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({
    required this.rotation,
    required this.activeIndex,
    required this.arc,
    required this.glow,
    required this.ink,
    required this.dim,
    required this.gold,
  });

  final double rotation;
  final int activeIndex;
  final Color arc;
  final Color glow;
  final Color ink;
  final Color dim;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height);
    final outer = size.width / 2;
    final inner = outer * 0.62;
    final mid = (outer + inner) / 2;

    // The band the glyphs sit on.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: mid),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outer - inner
        ..shader = SweepGradient(
          colors: [arc.withValues(alpha: 0.25), glow.withValues(alpha: 0.55)],
        ).createShader(Rect.fromCircle(center: centre, radius: outer)),
    );

    // The wedge marking the selected sign, at the top of the arc.
    const slice = math.pi / 12;
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..drawPath(
        Path()
          ..moveTo(0, 0)
          ..arcTo(
            Rect.fromCircle(center: Offset.zero, radius: outer),
            -math.pi / 2 - slice / 2,
            slice,
            false,
          )
          ..close(),
        Paint()..color = gold.withValues(alpha: 0.22),
      )
      ..restore();

    // Glyphs, laid around the arc and turned so the active one is on top.
    for (var i = 0; i < ZodiacSign.values.length; i++) {
      final angle = math.pi + slice / 2 + i * slice + rotation;

      // Signs that have turned past either end of the half-arc must not
      // be drawn: they would float outside the band with nothing behind
      // them, which is what the first version did.
      if (angle < math.pi || angle > 2 * math.pi) continue;
      final position = Offset(
        centre.dx + mid * math.cos(angle),
        centre.dy + mid * math.sin(angle),
      );

      final active = i == activeIndex;
      final painter = TextPainter(
        text: TextSpan(
          text: ZodiacSign.values[i].glyph,
          style: SanctumTypography.symbol(
            active ? 26 : 18,
            active ? ink : dim.withValues(alpha: 0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        position - Offset(painter.width / 2, painter.height / 2),
      );
    }

    // The hub, and a pointer at the top.
    canvas
      ..drawCircle(
        centre,
        inner * 0.55,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  glow.withValues(alpha: 0.5),
                  arc.withValues(alpha: 0.05),
                ],
              ).createShader(
                Rect.fromCircle(center: centre, radius: inner * 0.55),
              ),
      )
      ..drawPath(
        Path()
          ..moveTo(centre.dx, centre.dy - outer + 4)
          ..lineTo(centre.dx - 7, centre.dy - outer - 10)
          ..lineTo(centre.dx + 7, centre.dy - outer - 10)
          ..close(),
        Paint()..color = gold,
      );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.rotation != rotation || old.activeIndex != activeIndex;
}
