import 'dart:async';
import 'dart:ui' show FragmentProgram, FragmentShader;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';

/// The animated aurora that sits behind Sanctum's screens.
///
/// Drives `shaders/aurora.frag` from a [Ticker], so the drift is a
/// function of real elapsed time rather than a looping controller — a
/// loop would eventually seam, and at 32 seconds a seam is very visible.
///
/// ## Performance
///
/// The whole effect is one GPU draw call, but it still repaints every
/// frame, so it is wrapped in a [RepaintBoundary]: without one, every
/// ancestor and sibling in the same layer repaints along with it.
///
/// Set [enabled] to `false` when the aurora is off-screen or the app is
/// backgrounded. A ticker left running is a battery drain the user will
/// blame on "the app", not on this widget.
class AuroraBackground extends StatefulWidget {
  /// Creates an aurora background painted behind [child].
  const AuroraBackground({
    this.child,
    this.intensity = 1.0,
    this.enabled = true,
    super.key,
  });

  /// Content drawn on top of the aurora.
  final Widget? child;

  /// Scales bloom brightness. Lower it behind dense text so the copy
  /// keeps its contrast.
  final double intensity;

  /// Whether the animation advances. When `false` the last frame stays
  /// on screen and the ticker is stopped.
  final bool enabled;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  /// Loaded once per process, not once per widget. Rebuilding the program
  /// on every mount would hitch each navigation.
  static Future<FragmentProgram>? _programFuture;

  late final Ticker _ticker;
  FragmentShader? _shader;
  double _seconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.enabled) _ticker.start();
    unawaited(_load());
  }

  Future<void> _load() async {
    final future = _programFuture ??= FragmentProgram.fromAsset(
      'shaders/aurora.frag',
    );
    final program = await future;
    if (!mounted) return;
    setState(() => _shader = program.fragmentShader());
  }

  void _onTick(Duration elapsed) {
    setState(() => _seconds = elapsed.inMicroseconds / 1e6);
  }

  @override
  void didUpdateWidget(AuroraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shader = _shader;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Until the shader compiles, show the flat gradient it resolves
        // to. Falling back to a blank container would flash black.
        if (shader == null)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.background, colors.backgroundEnd],
              ),
            ),
          )
        else
          RepaintBoundary(
            child: CustomPaint(
              painter: _AuroraPainter(
                shader: shader,
                seconds: _seconds,
                colors: colors,
                intensity: widget.intensity,
              ),
              isComplex: true,
              willChange: true,
            ),
          ),
        ?widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.shader,
    required this.seconds,
    required this.colors,
    required this.intensity,
  });

  final FragmentShader shader;
  final double seconds;
  final SanctumColors colors;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Index order must match the uniform declaration order in
    // aurora.frag. See the comment there before changing either.
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, seconds);
    _setColor(3, colors.accent);
    _setColor(6, colors.accentSecondary);
    _setColor(9, colors.accentTertiary);
    _setColor(12, colors.background);
    _setColor(15, colors.backgroundEnd);
    shader.setFloat(18, intensity);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _setColor(int index, Color color) {
    shader
      ..setFloat(index, color.r)
      ..setFloat(index + 1, color.g)
      ..setFloat(index + 2, color.b);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.seconds != seconds ||
      old.intensity != intensity ||
      old.colors != colors;
}
