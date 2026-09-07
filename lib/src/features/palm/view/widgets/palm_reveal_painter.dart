import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/features/palm/view/palm_reveal_timeline.dart';

/// Draws one instant of the reveal.
///
/// ## One painter, two consumers
///
/// This runs on screen under a ticker and offscreen under a
/// `PictureRecorder` at a fixed step, and it must produce the same
/// picture from the same [PalmRevealFrame] either way. So it holds no
/// state, reads no `BuildContext`, and takes its colours and text styles
/// as arguments — the exporter has no element tree to resolve them from.
///
/// `ShareController` already carries the reasoning: a share path that
/// quietly differs between two screens is a growth bug nobody will ever
/// file. Here the two paths are the app and the video *of* the app,
/// which is worse.
///
/// ## Coordinates
///
/// [curves] arrive in [PalmSpace.image] — normalised to the frame's
/// width on both axes — and [photo] is drawn to cover the canvas. Both
/// go through [_place], so a line cannot land somewhere the photograph
/// is not.
class PalmRevealPainter extends CustomPainter {
  /// Creates a painter for one instant.
  const PalmRevealPainter({
    required this.frame,
    required this.curves,
    required this.colors,
    required this.labelStyle,
    this.photo,
    this.frameAspect = 16 / 9,
    this.verdictHeadline,
    this.verdictStyle,
  });

  /// The instant to draw.
  final PalmRevealFrame frame;

  /// The lines, already placed on the frame by `PalmFrame.place`.
  final List<PalmCurve> curves;

  /// Resolved colours. Passed rather than read from a theme so the
  /// exporter can paint without an element tree.
  final SanctumColors colors;

  /// How a line's name is set.
  final TextStyle labelStyle;

  /// The captured still. Null during [PalmRevealBeat.align], when there
  /// is a live preview behind this painter instead.
  final ui.Image? photo;

  /// The still's height over its width, for mapping normalised
  /// coordinates when [photo] has not loaded yet.
  final double frameAspect;

  /// The one claim the verdict card makes.
  final String? verdictHeadline;

  /// How that claim is set.
  final TextStyle? verdictStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final photoRect = _coverRect(size);

    _paintPhoto(canvas, size, photoRect);
    _paintVignette(canvas, size);
    if (frame.sweep case final sweep?) {
      _paintSweep(canvas, photoRect, sweep);
    }
    _paintLines(canvas, photoRect);
    if (frame.constellation > 0) {
      _paintConstellation(canvas, photoRect);
    }
    _paintLabels(canvas, photoRect);
    if (frame.captureFlash > 0) {
      _paintFlash(canvas, size);
    }
    if (frame.verdict > 0) {
      _paintVerdict(canvas, size);
    }
  }

  /// Where the still sits once fitted to [size] with `BoxFit.cover`.
  ///
  /// Returned rather than applied as a clip because the lines are
  /// mapped through it too: the palm has to stay under them when the
  /// photograph is cropped, which it will be on almost every phone.
  Rect _coverRect(Size size) {
    final aspect = photo == null ? frameAspect : photo!.height / photo!.width;
    final width = math.max(size.width, size.height / aspect);
    final height = width * aspect;
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: height,
    );
  }

  /// A point in [PalmSpace.image] onto the canvas.
  ///
  /// Both axes scale by the *width*, because that is how the landmarks
  /// were normalised — see [PalmSpace.image]. Scaling `y` by the height
  /// instead is the bug that makes every line look almost right.
  Offset _place(PalmPoint point, Rect rect) =>
      rect.topLeft + Offset(point.x, point.y) * rect.width;

  void _paintPhoto(Canvas canvas, Size size, Rect rect) {
    final image = photo;
    if (image == null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = colors.background,
      );
      return;
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      rect,
      Paint()..colorFilter = _inkFilter(frame.inkiness),
    );
  }

  /// Drains the photograph toward ink as the reveal proceeds.
  ///
  /// Saturation down to 0.18 rather than 0, and a slight lift in
  /// contrast. A fully grey hand reads as a broken camera; what this
  /// wants is a photograph that has stopped competing with the lines
  /// drawn on it.
  ColorFilter _inkFilter(double amount) {
    final saturation = 1 - amount * 0.82;
    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;
    final contrast = 1 + amount * 0.18;
    final shift = -0.5 * (contrast - 1) * 255;

    double term(double weight, {required bool onDiagonal}) =>
        (weight * (1 - saturation) + (onDiagonal ? saturation : 0)) * contrast;

    return ColorFilter.matrix(<double>[
      term(lr, onDiagonal: true), term(lg, onDiagonal: false),
      term(lb, onDiagonal: false), 0, shift, //
      term(lr, onDiagonal: false), term(lg, onDiagonal: true),
      term(lb, onDiagonal: false), 0, shift, //
      term(lr, onDiagonal: false), term(lg, onDiagonal: false),
      term(lb, onDiagonal: true), 0, shift, //
      0, 0, 0, 1, 0,
    ]);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          size.center(Offset.zero),
          size.longestSide * 0.62,
          [
            const Color(0x00000000),
            colors.background.withValues(alpha: 0.55 * frame.inkiness),
          ],
          const [0.55, 1],
        ),
    );
  }

  /// The scanning bar.
  ///
  /// Swept across the *palm*, not the screen: the band is built in the
  /// frame's own axis and follows the hand's rotation, so a hand held at
  /// an angle is scanned along itself. A screen-aligned bar over a
  /// tilted hand immediately reads as an overlay.
  void _paintSweep(Canvas canvas, Rect rect, double sweep) {
    if (curves.isEmpty) return;

    final along = _palmAxis();
    final centre = _palmCentre();
    final span = _palmSpan(along, centre);
    final position = centre + along * (span * (sweep - 0.5) * 2);
    final across = along.normal;
    final width = rect.width;

    final origin = _place(position, rect);
    final direction = Offset(along.x, along.y) * (width * 0.06);
    final edge = Offset(across.x, across.y) * width;

    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: width * 2,
          height: width * 0.12,
        ),
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.linear(
            -direction,
            direction,
            [
              colors.accent.withValues(alpha: 0),
              colors.gold.withValues(alpha: 0.55),
              colors.accent.withValues(alpha: 0),
            ],
            const [0, 0.5, 1],
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.012),
      )
      ..drawLine(
        -edge,
        edge,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = colors.gold.withValues(alpha: 0.35)
          ..strokeWidth = width * 0.003,
      )
      ..restore();
  }

  void _paintLines(Canvas canvas, Rect rect) {
    final width = rect.width;
    for (final curve in curves) {
      final progress = frame.progressOf(curve.line);
      if (progress <= 0) continue;

      final drawn = _drawn(curve, rect, progress);
      if (drawn == null) continue;

      final colour = _colourOf(curve.line);

      canvas
        ..drawPath(
          drawn.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = width * 0.016
            ..color = colour.withValues(alpha: 0.30)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.014),
        )
        ..drawPath(
          drawn.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = width * 0.0045
            ..color = colors.textPrimary.withValues(alpha: 0.92),
        );

      if (progress < 1) {
        canvas.drawCircle(
          drawn.tip,
          width * 0.012,
          Paint()
            ..blendMode = BlendMode.plus
            ..color = colors.gold
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.014),
        );
      }
    }
  }

  /// The stroke width scales with the palm, never with the screen.
  ///
  /// A constant pixel width makes a small hand look scrawled on and a
  /// large one look underlined.
  ({Path path, Offset tip})? _drawn(
    PalmCurve curve,
    Rect rect,
    double progress,
  ) {
    final path = Path()
      ..moveTo(
        _place(curve.controlPoints.first, rect).dx,
        _place(curve.controlPoints.first, rect).dy,
      );
    for (var s = 0; s < curve.segmentCount; s++) {
      final c1 = _place(curve.controlPoints[s * 3 + 1], rect);
      final c2 = _place(curve.controlPoints[s * 3 + 2], rect);
      final end = _place(curve.controlPoints[s * 3 + 3], rect);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return null;
    final metric = metrics.first;
    final length = metric.length * progress.clamp(0.0, 1.0);
    if (length <= 0) return null;

    return (
      path: metric.extractPath(0, length),
      tip: metric.getTangentForOffset(length)?.position ?? Offset.zero,
    );
  }

  void _paintLabels(Canvas canvas, Rect rect) {
    for (final curve in curves) {
      final opacity = frame.labelOpacity[curve.line] ?? 0;
      if (opacity <= 0) continue;

      final painter = TextPainter(
        text: TextSpan(
          text: curve.line.displayName.toUpperCase(),
          style: labelStyle.copyWith(
            color: labelStyle.color?.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Positioned by the geometry, drawn upright. A label mapped
      // through the warp comes out mirrored on one hand of the two.
      final anchor = _place(curve.controlPoints.last, rect);
      painter.paint(
        canvas,
        anchor + Offset(rect.width * 0.02, -painter.height / 2),
      );
    }
  }

  void _paintConstellation(Canvas canvas, Rect rect) {
    final width = rect.width;
    final nodes = <Offset>[
      for (final curve in curves)
        if (frame.progressOf(curve.line) >= 1) ...[
          _place(curve.controlPoints.first, rect),
          _place(curve.controlPoints.last, rect),
        ],
    ];
    if (nodes.length < 2) return;

    final reach = frame.constellation;
    final hairline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.0012
      ..color = colors.accentCool.withValues(alpha: 0.28 * reach);

    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        canvas.drawLine(
          nodes[i],
          Offset.lerp(nodes[i], nodes[j], reach)!,
          hairline,
        );
      }
    }

    for (final node in nodes) {
      canvas.drawCircle(
        node,
        width * 0.006 * reach,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = colors.gold.withValues(alpha: 0.8 * reach),
      );
    }
  }

  void _paintFlash(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = colors.textPrimary.withValues(
          alpha: 0.5 * frame.captureFlash,
        ),
    );
  }

  void _paintVerdict(Canvas canvas, Size size) {
    final headline = verdictHeadline;
    final style = verdictStyle;
    if (headline == null || style == null) return;

    final painter = TextPainter(
      text: TextSpan(
        text: headline,
        style: style.copyWith(
          color: style.color?.withValues(alpha: frame.verdict),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * _contentWidth);

    // The gutters TikTok actually takes, measured on a posted video and
    // pinned in `story_slide_test.dart`. Reserved on both sides so the
    // composition stays centred when the same file goes to Instagram,
    // where the overlays sit somewhere else entirely.
    final bottom = size.height * (1 - _captionGutter);
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        bottom - painter.height - size.height * 0.04 * frame.verdict,
      ),
    );
  }

  PalmPoint _palmCentre() {
    var sum = const PalmPoint(0, 0);
    var count = 0;
    for (final curve in curves) {
      for (final point in curve.anchors) {
        sum += point;
        count++;
      }
    }
    return count == 0 ? const PalmPoint(0.5, 0.5) : sum * (1 / count);
  }

  /// The knuckles-to-wrist direction, taken from the life line, which is
  /// the only template curve that spans the palm's length.
  PalmPoint _palmAxis() {
    final life = curves.where((curve) => curve.line == PalmLine.life);
    final curve = life.isNotEmpty ? life.first : curves.first;
    return (curve.controlPoints.last - curve.controlPoints.first).normalized;
  }

  double _palmSpan(PalmPoint along, PalmPoint centre) {
    var extent = 0.0;
    for (final curve in curves) {
      for (final point in curve.anchors) {
        final offset = point - centre;
        final projected = (offset.x * along.x + offset.y * along.y).abs();
        extent = math.max(extent, projected);
      }
    }
    return extent * 1.35;
  }

  Color _colourOf(PalmLine line) => switch (line) {
    PalmLine.heart => colors.accentTertiary,
    PalmLine.head => colors.accentCool,
    PalmLine.life => colors.gold,
    PalmLine.fate => colors.accentSecondary,
  };

  /// TikTok's caption block covers the bottom 16.8 % — measured, not
  /// guessed. See `handoff.md` on the carousel.
  static const double _captionGutter = 0.168;

  /// And its action rail the right 15 %, applied to both sides.
  static const double _contentWidth = 1 - 0.15 * 2;

  @override
  bool shouldRepaint(PalmRevealPainter old) =>
      old.frame != frame ||
      old.curves != curves ||
      old.photo != photo ||
      old.verdictHeadline != verdictHeadline;
}
