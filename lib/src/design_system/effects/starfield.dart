import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';

/// A field of slowly twinkling, parallaxing stars.
///
/// ## Why the stars are seeded
///
/// Positions come from a [math.Random] with a fixed [seed], generated
/// once in `initState`. Two consequences, both deliberate:
///
/// * The sky does not reshuffle itself on every rebuild, which would be
///   deeply distracting.
/// * Golden tests are stable, because the same seed paints the same sky
///   on every machine.
///
/// ## Why one ticker
///
/// Every star twinkles, but there is a single [Ticker] and a single
/// [CustomPainter]. The naive version — one `AnimatedOpacity` per star —
/// would create hundreds of animation controllers and elements, and would
/// drop frames long before it looked good.
class Starfield extends StatefulWidget {
  /// Creates a starfield.
  const Starfield({
    this.starCount = 140,
    this.seed = 7,
    this.enabled = true,
    this.child,
    super.key,
  });

  /// How many stars to paint.
  ///
  /// Deliberately capped low. Past roughly 200 the visual gain is nil and
  /// the raster cost on low-end Android is not.
  final int starCount;

  /// Seed for star placement. Same seed, same sky.
  final int seed;

  /// Whether the twinkle advances.
  final bool enabled;

  /// Content drawn above the stars.
  final Widget? child;

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _StarfieldState extends State<Starfield>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late List<_Star> _stars;
  double _seconds = 0;

  @override
  void initState() {
    super.initState();
    _stars = _generate();
    _ticker = createTicker((elapsed) {
      setState(() => _seconds = elapsed.inMicroseconds / 1e6);
    });
    if (widget.enabled) _ticker.start();
  }

  List<_Star> _generate() {
    final random = math.Random(widget.seed);
    return List.generate(widget.starCount, (_) {
      // depth 0 = far (small, dim, slow), 1 = near.
      final depth = random.nextDouble();
      return _Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: 0.4 + depth * 1.1,
        baseOpacity: 0.18 + depth * 0.5,
        twinklePhase: random.nextDouble() * math.pi * 2,
        twinkleSpeed: 0.25 + random.nextDouble() * 0.6,
        depth: depth,
      );
    });
  }

  @override
  void didUpdateWidget(Starfield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.starCount != oldWidget.starCount ||
        widget.seed != oldWidget.seed) {
      _stars = _generate();
    }
    if (widget.enabled && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _StarfieldPainter(
              stars: _stars,
              seconds: _seconds,
              color: context.colors.textPrimary,
              accent: context.colors.accentSecondary,
            ),
            willChange: widget.enabled,
          ),
        ),
        ?widget.child,
      ],
    );
  }
}

@immutable
class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseOpacity,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.depth,
  });

  final double x;
  final double y;
  final double radius;
  final double baseOpacity;
  final double twinklePhase;
  final double twinkleSpeed;
  final double depth;
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter({
    required this.stars,
    required this.seconds,
    required this.color,
    required this.accent,
  });

  final List<_Star> stars;
  final double seconds;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    for (final star in stars) {
      // Nearer stars drift further — that difference is the parallax.
      final drift = seconds * (2 + star.depth * 6);
      final dx = (star.x * size.width + drift) % size.width;
      final dy = star.y * size.height;

      final twinkle =
          0.5 + 0.5 * math.sin(seconds * star.twinkleSpeed + star.twinklePhase);
      final opacity = (star.baseOpacity * (0.55 + 0.45 * twinkle)).clamp(
        0.0,
        1.0,
      );

      // A handful of the nearest stars take the aurora's tint, so the sky
      // and the aurora read as one scene rather than two stacked layers.
      final tint = star.depth > 0.88 ? accent : color;

      paint.color = tint.withValues(alpha: opacity);
      canvas.drawCircle(Offset(dx, dy), star.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) =>
      old.seconds != seconds ||
      old.color != color ||
      !identical(old.stars, stars);
}
