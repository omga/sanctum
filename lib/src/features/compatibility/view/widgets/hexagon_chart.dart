import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';

/// The six facets, as a radar.
///
/// ## Why a hexagon instead of six bars
///
/// Bars are read one at a time; a radar is read as a *shape*. The
/// interesting thing about a pairing is rarely one number, it is the
/// silhouette — a spike on Spark with a dent on Future looks like
/// something, and it looks different from the next couple's. Shapes are
/// what people compare, and comparing is what gets posted.
///
/// ## Label sizing is a localisation decision
///
/// Each label sits in a fixed-width box and is allowed to wrap to two
/// lines. That is not cosmetic: this app is going to Spanish, Russian
/// and French, where "Trust" becomes "Confianza" and "Доверие", and a
/// label laid out to fit English will overlap its neighbour the first
/// time it is translated. Reserving the space now costs nothing; finding
/// out later means redrawing the chart.
class HexagonChart extends StatelessWidget {
  /// Creates a chart.
  const HexagonChart({
    required this.facets,
    this.size = 280,
    this.animate = true,
    super.key,
  });

  /// The six scores, in axis order.
  final List<FacetScore> facets;

  /// Width and height of the whole widget, labels included.
  final double size;

  /// Whether to grow the shape on first build.
  final bool animate;

  /// Width reserved for each label. Two lines of a long translation.
  static const double labelWidth = 84;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // The web has to leave room for a label ring outside it.
    final radius = (size - labelWidth) / 2;
    final centre = Offset(size / 2, size / 2);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: animate ? 0 : 1, end: 1),
              duration: animate
                  ? const Duration(milliseconds: 900)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              builder: (context, growth, _) => CustomPaint(
                painter: _RadarPainter(
                  values: [
                    for (final facet in facets) facet.score / 100 * growth,
                  ],
                  radius: radius,
                  web: colors.glassBorder,
                  fill: colors.accent,
                  edge: colors.gold,
                ),
              ),
            ),
          ),
          for (final (index, facet) in facets.indexed)
            _label(context, index, facets.length, centre, radius, facet),
        ],
      ),
    );
  }

  Widget _label(
    BuildContext context,
    int index,
    int count,
    Offset centre,
    double radius,
    FacetScore facet,
  ) {
    final colors = context.colors;
    final type = context.type;

    // First axis straight up, then clockwise.
    final angle = -math.pi / 2 + index * 2 * math.pi / count;
    final point = Offset(
      centre.dx + (radius + SanctumSpacing.xl) * math.cos(angle),
      centre.dy + (radius + SanctumSpacing.xl) * math.sin(angle),
    );

    return Positioned(
      left: point.dx - labelWidth / 2,
      top: point.dy - 18,
      width: labelWidth,
      child: Column(
        children: [
          Text(
            facet.facet.displayName,
            textAlign: TextAlign.center,
            style: type.caption.copyWith(color: colors.textSecondary),
          ),
          Text(
            '${facet.score}',
            textAlign: TextAlign.center,
            style: type.label.copyWith(color: colors.gold),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.values,
    required this.radius,
    required this.web,
    required this.fill,
    required this.edge,
  });

  final List<double> values;
  final double radius;
  final Color web;
  final Color fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final count = values.length;
    if (count < 3) return;

    Offset vertex(int index, double scale) {
      final angle = -math.pi / 2 + index * 2 * math.pi / count;
      return Offset(
        centre.dx + radius * scale * math.cos(angle),
        centre.dy + radius * scale * math.sin(angle),
      );
    }

    Path ring(double scale) {
      final path = Path()..moveTo(vertex(0, scale).dx, vertex(0, scale).dy);
      for (var i = 1; i < count; i++) {
        path.lineTo(vertex(i, scale).dx, vertex(i, scale).dy);
      }
      return path..close();
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = web;

    // Three rings and the spokes. Any more reads as graph paper.
    for (final scale in [0.4, 0.7, 1.0]) {
      canvas.drawPath(ring(scale), grid);
    }
    for (var i = 0; i < count; i++) {
      canvas.drawLine(centre, vertex(i, 1), grid);
    }

    final shape = Path()
      ..moveTo(vertex(0, values[0]).dx, vertex(0, values[0]).dy);
    for (var i = 1; i < count; i++) {
      shape.lineTo(vertex(i, values[i]).dx, vertex(i, values[i]).dy);
    }
    shape.close();

    canvas
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = RadialGradient(
            colors: [
              fill.withValues(alpha: 0.55),
              fill.withValues(alpha: 0.20),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      )
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = edge,
      );

    // A dot on each vertex, so a low score still reads as a point on the
    // axis rather than as a dent in an abstract blob.
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        vertex(i, values[i]),
        3,
        Paint()..color = edge,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      !listEquals(old.values, values) || old.radius != radius;

  static bool listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
