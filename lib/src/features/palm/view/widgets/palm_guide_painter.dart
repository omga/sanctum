import 'package:flutter/widgets.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';

/// The viewfinder: where to put a hand, and where one currently is.
///
/// ## Two outlines, and the difference between them is the instruction
///
/// A static target sits in the middle of the frame at the proportions of
/// a palm. When a hand is found, its own outline is drawn over the
/// target — same shape, actual position — so the gap between the two
/// *is* the correction, without a sentence having to describe it.
///
/// The live outline appears as soon as there is a pose, including for
/// frames the geometry has refused. A hand that is merely too far away
/// still has an outline worth drawing, and drawing it while the copy
/// asks for more is the difference between an app that is guiding
/// somebody and one that has apparently stopped working.
class PalmGuidePainter extends CustomPainter {
  /// Creates a painter.
  const PalmGuidePainter({
    required this.colors,
    required this.hold,
    this.frame,
    this.isReady = false,
  });

  /// Resolved colours.
  final SanctumColors colors;

  /// How close the shutter is to firing, `[0, 1]`.
  final double hold;

  /// The live warp, when there is a hand.
  final PalmFrame? frame;

  /// Whether this frame would be captured.
  final bool isReady;

  /// The palm's outline in canonical space, as a closed loop.
  ///
  /// Traced round the anchors rather than a rectangle, so the target has
  /// the shape of a hand — including the way the knuckle line arches and
  /// the little finger sits lower than the index.
  static const List<PalmPoint> _outline = [
    PalmPoint(0.10, 0.22),
    PalmPoint(0.19, 0.10),
    PalmPoint(0.44, 0.02),
    PalmPoint(0.68, 0.06),
    PalmPoint(0.94, 0.18),
    PalmPoint(0.98, 0.46),
    PalmPoint(0.86, 0.82),
    PalmPoint(0.62, 1.02),
    PalmPoint(0.36, 1.02),
    PalmPoint(0.14, 0.80),
    PalmPoint(0.04, 0.50),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _paintTarget(canvas, size);

    if (frame case final frame?) {
      _paintLive(canvas, size, frame);
    }
    if (hold > 0) {
      _paintHold(canvas, size);
    }
  }

  /// Where the hand is wanted: centred, at about two thirds of the
  /// frame's width, which is roughly what the size check will accept.
  void _paintTarget(Canvas canvas, Size size) {
    final width = size.width * 0.66;
    final origin = Offset(
      (size.width - width) / 2,
      size.height * 0.5 - width * 0.55,
    );

    canvas.drawPath(
      _pathFrom(
        [
          for (final point in _outline)
            origin + Offset(point.x, point.y) * width,
        ],
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = colors.textPrimary.withValues(
          alpha: frame == null ? 0.28 : 0.1,
        ),
    );
  }

  void _paintLive(Canvas canvas, Size size, PalmFrame frame) {
    // Canonical → frame → canvas. `PalmSpace.image` normalises both axes
    // to the frame's *width*, so both scale by width here; scaling y by
    // height would draw an outline that tracks the hand almost exactly,
    // which is the worst kind of wrong.
    final path = _pathFrom([
      for (final point in _outline)
        () {
          final placed = frame.toImage.apply(point);
          return Offset(placed.x, placed.y) * size.width;
        }(),
    ]);

    final colour = isReady ? colors.gold : colors.accentCool;
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = colour.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colour.withValues(alpha: 0.9),
      );
  }

  /// The steadiness ring.
  ///
  /// Drawn because the shutter fires itself: without it the capture
  /// arrives unannounced, which reads as the app taking a photograph
  /// rather than the user taking one.
  void _paintHold(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height * 0.86);
    const radius = 26.0;

    canvas
      ..drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = colors.textPrimary.withValues(alpha: 0.18),
      )
      ..drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        -1.5708,
        6.2832 * hold.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3
          ..color = colors.gold,
      );
  }

  Path _pathFrom(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(PalmGuidePainter old) =>
      old.hold != hold || old.frame != frame || old.isReady != isReady;
}
