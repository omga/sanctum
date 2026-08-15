import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';

/// A frosted panel that reads as glass lit from above.
///
/// ## What actually makes glass convincing
///
/// Not the blur. Three things, in order of importance:
///
/// 1. A **bright hairline border**, brightest at the top-left, fading
///    toward the bottom-right. This is the specular edge, and it does
///    most of the work — a blurred panel with no edge just looks smudged.
/// 2. A **very low-opacity fill**, so what is behind still reads through.
/// 3. The blur itself, last.
///
/// ## Cost
///
/// [BackdropFilter] forces the compositor to save the layer behind it and
/// re-blur it every frame it changes. That is genuinely expensive.
///
/// **Never place a [GlassCard] inside a scrolling list.** Each one is its
/// own save-layer, and a list of them will drop frames on mid-range
/// Android. For repeated rows use [GlassCard.flat], which fakes the same
/// look with a translucent fill and no blur at all — visually near
/// identical over a dark background, and free.
class GlassCard extends StatelessWidget {
  /// Creates a blurred glass panel.
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(SanctumSpacing.lg),
    this.borderRadius = SanctumRadii.lgAll,
    this.blur = 18,
    this.onTap,
    super.key,
  }) : _blurred = true;

  /// Creates a glass panel with no [BackdropFilter].
  ///
  /// Use this anywhere the panel repeats — lists, grids, chips.
  const GlassCard.flat({
    required this.child,
    this.padding = const EdgeInsets.all(SanctumSpacing.lg),
    this.borderRadius = SanctumRadii.lgAll,
    this.onTap,
    super.key,
  }) : blur = 0,
       _blurred = false;

  /// Panel content.
  final Widget child;

  /// Inset around [child].
  final EdgeInsets padding;

  /// Corner rounding.
  final BorderRadius borderRadius;

  /// Blur sigma. Ignored by [GlassCard.flat].
  final double blur;

  /// Optional tap handler. Adds an ink response when present.
  final VoidCallback? onTap;

  final bool _blurred;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // Fill is a gradient, not a flat colour: brighter at the top-left
        // mimics light falling across a real pane.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.glassFill,
            colors.glassFill.withValues(alpha: colors.glassFill.a * 0.4),
          ],
        ),
        border: GradientBoxBorder(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.glassBorder,
              colors.glassBorder.withValues(alpha: colors.glassBorder.a * 0.25),
            ],
          ),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap case final onTap?) {
      panel = Stack(
        children: [
          panel,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                splashColor: colors.accent.withValues(alpha: 0.12),
                highlightColor: colors.accent.withValues(alpha: 0.06),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      );
    }

    if (!_blurred) {
      return ClipRRect(borderRadius: borderRadius, child: panel);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: panel,
      ),
    );
  }
}

/// A [BoxBorder] whose stroke is a gradient.
///
/// Flutter's [Border] only takes flat colours, but a uniformly bright
/// edge looks like a rectangle outline rather than light catching a pane.
/// This paints the border as a stroked round-rect filled with a shader.
@immutable
class GradientBoxBorder extends BoxBorder {
  /// Creates a gradient border.
  const GradientBoxBorder({required this.gradient, this.width = 1});

  /// The gradient painted along the stroke.
  final Gradient gradient;

  /// Stroke width in logical pixels.
  final double width;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    // Inset by half the stroke so the line sits inside the bounds rather
    // than straddling and being half-clipped by the enclosing ClipRRect.
    final inner = rect.deflate(width / 2);
    if (borderRadius == null) {
      canvas.drawRect(inner, paint);
    } else {
      canvas.drawRRect(borderRadius.toRRect(inner), paint);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradientBoxBorder &&
          other.gradient == gradient &&
          other.width == width);

  @override
  int get hashCode => Object.hash(gradient, width);
}
