import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/oracle_card.dart';
import 'package:sanctum/src/l10n/l10n.dart';

/// The daily oracle card, face-down until tapped.
///
/// ## Why a real 3-D flip
///
/// A cross-fade would be a tenth of the code. But the entire value of
/// this feature is ceremony — the card is the thing people screenshot and
/// send to a friend, which is the app's cheapest possible marketing. A
/// perspective flip with the reveal landing at the halfway point is what
/// makes it feel like a card rather than two images.
class OracleCardView extends StatefulWidget {
  /// Creates the card view.
  const OracleCardView({
    required this.card,
    required this.revealed,
    required this.onReveal,
    super.key,
  });

  /// The card for today.
  final OracleCard card;

  /// Whether it has been flipped.
  final bool revealed;

  /// Called when the user taps a face-down card.
  final VoidCallback onReveal;

  @override
  State<OracleCardView> createState() => _OracleCardViewState();
}

class _OracleCardViewState extends State<OracleCardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SanctumMotion.ritual,
    // Start already flipped if the card was revealed earlier today, so
    // reopening the app does not replay the ceremony.
    value: widget.revealed ? 1 : 0,
  );

  @override
  void didUpdateWidget(OracleCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed && !oldWidget.revealed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.revealed) return;
    unawaited(HapticFeedback.mediumImpact());
    widget.onReveal();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final angle = t * math.pi;
          // Past 90° we are looking at the back of the front face, so the
          // reverse side is drawn and counter-rotated.
          final showFront = angle > math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // perspective
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _CardFace(card: widget.card),
                  )
                : const _CardBack(),
          );
        },
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SanctumSpacing.xl,
        vertical: SanctumSpacing.xxl,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.auto_awesome, color: colors.gold, size: 30),
            const SizedBox(height: SanctumSpacing.md),
            Text(
              context.l10n.oracleCardLabel,
              style: context.type.caption.copyWith(color: colors.gold),
            ),
            const SizedBox(height: SanctumSpacing.sm),
            Text(
              context.l10n.oracleTapToTurn,
              style: context.type.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card});

  final OracleCard card;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: SanctumRadii.lgAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accent.withValues(alpha: 0.28),
            colors.accentTertiary.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: colors.gold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SanctumSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.name.toUpperCase(),
              style: type.caption.copyWith(color: colors.gold),
            ),
            const SizedBox(height: SanctumSpacing.md),
            Text(card.message, style: type.quote),
            const SizedBox(height: SanctumSpacing.lg),
            Divider(color: colors.gold.withValues(alpha: 0.25)),
            const SizedBox(height: SanctumSpacing.md),
            Text(card.guidance, style: type.bodyMedium),
          ],
        ),
      ),
    );
  }
}
