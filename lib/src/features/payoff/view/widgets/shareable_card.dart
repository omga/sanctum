import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_typography.dart';
import 'package:sanctum/src/domain/models/reading.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';

/// The card a user posts.
///
/// ## Why this is a separate widget from the screen
///
/// It is captured to an image, so it has to be self-contained: its own
/// background, its own padding, no reliance on anything painted behind
/// it. It is also deliberately *portrait and square-ish* rather than
/// full-screen — a screenshot of a whole phone screen is a bad Instagram
/// story, and a bad story is a wasted acquisition channel.
///
/// The watermark is not decoration either. An unbranded card is free
/// content for whoever reposts it.
class ShareableCard extends StatelessWidget {
  /// Creates the card.
  const ShareableCard({required this.reading, super.key});

  /// The reading to render.
  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: SanctumRadii.xlAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.backgroundEnd,
            colors.background,
          ],
        ),
        border: Border.all(color: colors.gold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SanctumSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  reading.sign.glyph,
                  style: SanctumTypography.symbol(30, colors.gold),
                ),
                const SizedBox(width: SanctumSpacing.md),
                Text(
                  reading.sign.label(context.l10n).toUpperCase(),
                  style: type.caption.copyWith(color: colors.gold),
                ),
              ],
            ),
            const SizedBox(height: SanctumSpacing.lg),
            Text(reading.shareLine, style: type.quote),
            const SizedBox(height: SanctumSpacing.xl),
            Divider(color: colors.gold.withValues(alpha: 0.25)),
            const SizedBox(height: SanctumSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SANCTUM',
                  style: type.caption.copyWith(color: colors.textSecondary),
                ),
                Text(
                  context.l10n.quizElementSign(
                    reading.sign.element.label(context.l10n),
                  ),
                  style: type.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
