import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';

/// The viewfinder: where to put a hand, and where one currently is.
///
/// ## Two outlines, and the difference between them is the instruction
///
/// A static target sits in the middle of the frame in the shape of a
/// hand. When a hand is found, its own outline is drawn over the target
/// — same shape, actual position — so the gap between the two *is* the
/// correction, without a sentence having to describe it.
///
/// The live outline appears as soon as there is a pose, including for
/// frames the geometry has refused. A hand that is merely too far away
/// still has an outline worth drawing, and drawing it while the copy
/// asks for more is the difference between an app that is guiding
/// somebody and one that has apparently stopped working.
///
/// ## Why the shape is computed rather than drawn
///
/// The first version was a polygon of eleven authored points, and on a
/// phone it read as a lopsided circle: no fingers, roughly square, and
/// nothing about it said "hand". Points authored by eye cannot be
/// checked by the person authoring them.
///
/// So the outline is built instead — a capsule down each finger and
/// across the palm, taken from [PalmGeometry.canonicalHand], unioned
/// into one path and stroked. It is the same anatomy the warp is fitted
/// to, which means the target and the detected outline are necessarily
/// the same shape, and nudging the anatomy moves both.
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

  /// Half-width of a finger, in canonical units.
  static const double _fingerRadius = 0.062;

  /// Half-width of the palm's own capsules. Wider, so the five of them
  /// merge into one mass rather than reading as splayed bones.
  static const double _palmRadius = 0.15;

  /// The bones a capsule is laid along.
  static const List<List<PalmLandmark>> _bones = [
    // The palm: wrist to each knuckle, then across the knuckle line.
    [PalmLandmark.wrist, PalmLandmark.indexMcp],
    [PalmLandmark.wrist, PalmLandmark.middleMcp],
    [PalmLandmark.wrist, PalmLandmark.ringMcp],
    [PalmLandmark.wrist, PalmLandmark.pinkyMcp],
    [PalmLandmark.indexMcp, PalmLandmark.middleMcp],
    [PalmLandmark.middleMcp, PalmLandmark.ringMcp],
    [PalmLandmark.ringMcp, PalmLandmark.pinkyMcp],
    // The fingers.
    [PalmLandmark.indexMcp, PalmLandmark.indexPip, PalmLandmark.indexTip],
    [PalmLandmark.middleMcp, PalmLandmark.middlePip, PalmLandmark.middleTip],
    [PalmLandmark.ringMcp, PalmLandmark.ringPip, PalmLandmark.ringTip],
    [PalmLandmark.pinkyMcp, PalmLandmark.pinkyPip, PalmLandmark.pinkyTip],
    // The thumb, which leaves the palm at its own angle.
    [
      PalmLandmark.thumbCmc,
      PalmLandmark.thumbMcp,
      PalmLandmark.thumbIp,
      PalmLandmark.thumbTip,
    ],
  ];

  /// The hand, in canonical units. Built once per process.
  static final Path _hand = _buildHand();

  static Path _buildHand() {
    Path? combined;
    for (final bone in _bones) {
      final isPalm = bone.length == 2 && bone.first != PalmLandmark.thumbCmc;
      final radius = isPalm ? _palmRadius : _fingerRadius;
      for (var i = 0; i < bone.length - 1; i++) {
        final segment = _capsule(
          _offsetOf(bone[i]),
          _offsetOf(bone[i + 1]),
          radius,
        );
        combined = combined == null
            ? segment
            : Path.combine(PathOperation.union, combined, segment);
      }
    }
    return combined ?? Path();
  }

  static Offset _offsetOf(PalmLandmark landmark) {
    final point = PalmGeometry.canonicalHand[landmark]!;
    return Offset(point.x, point.y);
  }

  /// A capsule from [a] to [b].
  ///
  /// A rounded rectangle of height `2r` with radius `r` is exactly a
  /// capsule, so it is built on the x axis and rotated into place —
  /// which avoids two `arcToPoint` calls whose sweep direction is very
  /// easy to get backwards and impossible to notice until it is drawn.
  static Path _capsule(Offset a, Offset b, double radius) {
    final delta = b - a;
    final length = delta.distance;
    if (length < 1e-9) {
      return Path()..addOval(Rect.fromCircle(center: a, radius: radius));
    }

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-radius, -radius, length + radius * 2, radius * 2),
          Radius.circular(radius),
        ),
      );

    final transform = Matrix4.identity()
      ..translateByDouble(a.dx, a.dy, 0, 1)
      ..rotateZ(math.atan2(delta.dy, delta.dx));
    return path.transform(transform.storage);
  }

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

  /// Where the hand is wanted: centred, at roughly the size the
  /// readiness check will accept.
  ///
  /// Fitted from the path's own bounds rather than from a guessed
  /// scale, so changing the anatomy cannot push a fingertip off screen.
  void _paintTarget(Canvas canvas, Size size) {
    final bounds = _hand.getBounds();
    if (bounds.isEmpty) return;

    final scale = math.min(
      size.width * 0.62 / bounds.width,
      size.height * 0.56 / bounds.height,
    );
    final transform = Matrix4.identity()
      ..translateByDouble(
        size.width / 2 - bounds.center.dx * scale,
        size.height * 0.47 - bounds.center.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);

    canvas.drawPath(
      _hand.transform(transform.storage),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = colors.textPrimary.withValues(
          alpha: frame == null ? 0.34 : 0.12,
        ),
    );
  }

  void _paintLive(Canvas canvas, Size size, PalmFrame frame) {
    // Canonical → frame → canvas, as one matrix. `PalmSpace.image`
    // normalises both axes to the frame's *width*, so both scale by
    // width here; scaling y by height would draw an outline that tracks
    // the hand almost exactly, which is the worst kind of wrong.
    final warp = frame.toImage;
    final scale = size.width;
    final transform = Matrix4(
      warp.a * scale,
      warp.c * scale,
      0,
      0, //
      warp.b * scale,
      warp.d * scale,
      0,
      0, //
      0,
      0,
      1,
      0, //
      warp.tx * scale,
      warp.ty * scale,
      0,
      1, //
    );
    final path = _hand.transform(transform.storage);

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
      old.hold != hold || old.frame != frame || old.isReady != isReady;
}
