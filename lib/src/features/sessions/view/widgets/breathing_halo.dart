import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';

/// A slow pulsing ring that gives the tone something to look like.
///
/// Its cycle is roughly a calm breath — about 5.5 seconds, which is close
/// to the rate breathing exercises aim for. People unconsciously match
/// it, which does more for the session than any waveform visualiser would.
class BreathingHalo extends StatefulWidget {
  /// Creates a halo.
  const BreathingHalo({required this.active, this.size = 200, super.key});

  /// Whether to animate. When false the halo rests at its midpoint.
  final bool active;

  /// Diameter of the outer ring.
  final double size;

  @override
  State<BreathingHalo> createState() => _BreathingHaloState();
}

class _BreathingHaloState extends State<BreathingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(BreathingHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutSine.transform(_controller.value);
          final scale = 0.82 + t * 0.18;

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.accent.withValues(alpha: 0.34 * t + 0.06),
                        colors.accentTertiary.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                    border: Border.all(
                      color: colors.gold.withValues(alpha: 0.18 + t * 0.22),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
