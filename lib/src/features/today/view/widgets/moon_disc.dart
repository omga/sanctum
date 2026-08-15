import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';

/// Draws the moon at its actual illumination.
///
/// A real terminator rather than an icon from a set of eight: the lit
/// fraction is a continuous value, and drawing it continuously means the
/// disc is subtly different every single day. Users do not consciously
/// notice this. They notice the version that snaps between eight icons.
class MoonDisc extends StatelessWidget {
  /// Creates a moon disc for [reading].
  const MoonDisc({required this.reading, this.size = 44, super.key});

  /// The moon to draw.
  final MoonReading reading;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label:
          '${reading.phase.displayName}, '
          '${(reading.illumination * 100).round()} percent illuminated',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _MoonPainter(
            position: reading.cyclePosition,
            lit: colors.moonLit,
            shadow: colors.moonShadow,
            glow: colors.gold,
          ),
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter({
    required this.position,
    required this.lit,
    required this.shadow,
    required this.glow,
  });

  final double position;
  final Color lit;
  final Color shadow;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final centre = Offset(radius, radius);

    // Soft halo, brightest when full.
    final fullness = (1 - math.cos(2 * math.pi * position)) / 2;
    canvas
      ..drawCircle(
        centre,
        radius * 1.35,
        Paint()
          ..color = glow.withValues(alpha: 0.16 * fullness)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawCircle(centre, radius, Paint()..color = shadow);

    // The terminator is an ellipse whose width tracks the phase: full
    // circle at new/full, degenerate line at the quarters.
    final phaseAngle = 2 * math.pi * position;
    final terminator = -math.cos(phaseAngle);
    final litOnRight = position < 0.5;

    canvas
      ..save()
      ..clipPath(
        Path()..addOval(Rect.fromCircle(center: centre, radius: radius)),
      );

    final paint = Paint()..color = lit;
    final half = Path()
      ..addArc(
        Rect.fromCircle(center: centre, radius: radius),
        litOnRight ? -math.pi / 2 : math.pi / 2,
        math.pi,
      )
      ..close();
    canvas.drawPath(half, paint);

    // Then carve or extend with the terminator ellipse.
    final ellipse = Rect.fromCenter(
      center: centre,
      width: 2 * radius * terminator.abs(),
      height: 2 * radius,
    );
    final carve = Paint()
      ..color = (litOnRight == (terminator > 0)) ? lit : shadow;
    canvas
      ..drawOval(ellipse, carve)
      ..restore();
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.position != position || old.lit != lit;
}
