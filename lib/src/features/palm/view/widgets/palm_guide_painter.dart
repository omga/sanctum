import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';
import 'package:sanctum/src/domain/services/palm_silhouette.dart';

/// The viewfinder: where to put a hand, and where one currently is.
///
/// ## Two outlines, and the difference between them is the instruction
///
/// A faint target sits in the middle of the frame. When a hand is found,
/// its own outline is drawn over it, so the gap between the two *is* the
/// correction, without a sentence having to describe it.
///
/// ## The live outline is the user's hand, not the template's
///
/// It used to be the canonical hand pushed through the warp fitted to
/// the knuckles — which lined the palm up and left every finger and the
/// thumb at the canonical angle, whatever the user's were doing. It is
/// drawn from the detected landmarks now, so a splayed thumb is drawn
/// splayed. The warp is still what places the *lines*; the outline no
/// longer needs it.
///
/// Both outlines come from `PalmSilhouette`, which traces one smooth
/// line round the hand. See there for why the two versions built from
/// parts did not look like hands.
class PalmGuidePainter extends CustomPainter {
  /// Creates a painter.
  const PalmGuidePainter({
    required this.colors,
    required this.hold,
    this.landmarks,
    this.isReady = false,
    this.frameAspect = 4 / 3,
  });

  /// Resolved colours.
  final SanctumColors colors;

  /// How close the shutter is to firing, `[0, 1]`.
  final double hold;

  /// The detected hand in `PalmSpace.image`, or null when there is none.
  final List<PalmPoint>? landmarks;

  /// Whether this frame would be captured.
  final bool isReady;

  /// The camera frame's height over its width.
  ///
  /// Needed because the preview is cover-fitted: on a tall phone a 3:4
  /// frame fills the height and overflows the width by half, so a third
  /// of what the camera sees is off screen. Everything here is in frame
  /// coordinates, and without the crop it lands at about two thirds
  /// scale, up and to the left.
  final double frameAspect;

  static final List<PalmPoint> _canonical = [
    for (final landmark in PalmLandmark.values)
      PalmGeometry.canonicalHand[landmark]!,
  ];

  static final List<PalmPoint> _canonicalOutline = PalmSilhouette.outline(
    _canonical,
  );

  static final Rect _canonicalBounds = _boundsOf(
    PalmSilhouette.sample(_canonicalOutline),
  );

  static final double _canonicalKnuckleSpan =
      _canonical[PalmLandmark.indexMcp.index].distanceTo(
        _canonical[PalmLandmark.pinkyMcp.index],
      );

  static Rect _boundsOf(List<PalmPoint> points) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;
    for (final point in points) {
      left = math.min(left, point.x);
      top = math.min(top, point.y);
      right = math.max(right, point.x);
      bottom = math.max(bottom, point.y);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Where the camera frame lands on the canvas under `BoxFit.cover` —
  /// the same fit `PalmRevealPainter` applies to the still.
  static Rect _coverRect(Size size, double aspect) {
    final width = math.max(size.width, size.height / aspect);
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: width * aspect,
    );
  }

  /// Canonical units onto the canvas, for the target.
  ///
  /// Sized *from* [PalmGeometry.minKnuckleSpan], a quarter above it, so
  /// a hand placed on the outline passes the check rather than being
  /// told to come closer. Clamped so no fingertip leaves the screen; if
  /// the clamp ever binds, the copy keeps asking — better than an
  /// outline with its fingers cut off.
  static Offset Function(PalmPoint) _targetPlacement(Size size, Rect rect) {
    final bounds = _canonicalBounds;
    final wanted =
        PalmGeometry.minKnuckleSpan * 1.25 * rect.width / _canonicalKnuckleSpan;
    final scale = math.min(
      wanted,
      math.min(
        size.width * 0.88 / bounds.width,
        size.height * 0.64 / bounds.height,
      ),
    );
    final dx = size.width / 2 - bounds.center.dx * scale;
    final dy = size.height * 0.47 - bounds.center.dy * scale;
    return (point) => Offset(point.x * scale + dx, point.y * scale + dy);
  }

  /// The canonical hand as the target draws it, in frame coordinates.
  ///
  /// Exists so a test can hand these to `PalmGeometry.evaluate` and prove
  /// that a hand matching the target is a hand the checks accept — which
  /// is the promise the target makes, and the one it used to break.
  @visibleForTesting
  static List<PalmPoint> targetLandmarks(Size size, double frameAspect) {
    final rect = _coverRect(size, frameAspect);
    final place = _targetPlacement(size, rect);
    return [
      for (final point in _canonical)
        () {
          final onCanvas = place(point);
          return PalmPoint(
            (onCanvas.dx - rect.left) / rect.width,
            (onCanvas.dy - rect.top) / rect.width,
          );
        }(),
    ];
  }

  static Path _pathOf(
    List<PalmPoint> chain,
    Offset Function(PalmPoint) place,
  ) {
    final path = Path();
    if (chain.length < 4) return path;
    final start = place(chain.first);
    path.moveTo(start.dx, start.dy);
    for (var s = 0; s + 3 < chain.length; s += 3) {
      final c1 = place(chain[s + 1]);
      final c2 = place(chain[s + 2]);
      final end = place(chain[s + 3]);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = _coverRect(size, frameAspect);
    _paintTarget(canvas, size, rect);

    if (landmarks case final live?) {
      _paintLive(canvas, rect, live);
    }
    if (hold > 0) {
      _paintHold(canvas, size);
    }
  }

  void _paintTarget(Canvas canvas, Size size, Rect rect) {
    canvas.drawPath(
      _pathOf(_canonicalOutline, _targetPlacement(size, rect)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = colors.textPrimary.withValues(
          alpha: landmarks == null ? 0.34 : 0.12,
        ),
    );
  }

  void _paintLive(Canvas canvas, Rect rect, List<PalmPoint> points) {
    final chain = PalmSilhouette.outline(points);
    if (chain.isEmpty) return;

    // Frame coordinates onto the canvas: both axes scale by the cover
    // rect's *width*, because that is how `PalmSpace.image` normalises.
    final path = _pathOf(
      chain,
      (point) => rect.topLeft + Offset(point.x, point.y) * rect.width,
    );

    final colour = isReady ? colors.gold : colors.accentCool;
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = colour.withValues(alpha: 0.24)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = colour.withValues(alpha: 0.92),
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
        -math.pi / 2,
        math.pi * 2 * hold.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3
          ..color = colors.gold,
      );
  }

  @override
  bool shouldRepaint(PalmGuidePainter old) =>
      old.hold != hold ||
      old.isReady != isReady ||
      old.frameAspect != frameAspect ||
      !identical(old.landmarks, landmarks);
}
