import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/score_dial.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/sign_avatar.dart';

/// The card a user posts after a match.
///
/// Self-contained — its own background, its own border, nothing behind
/// it — because it is captured to an image. Everything animated is
/// frozen at its final value here: a capture of a half-filled ring is
/// the kind of bug that only ever shows up in someone else's feed.
class MatchShareCard extends StatelessWidget {
  /// Creates the card.
  const MatchShareCard({required this.match, super.key});

  /// The match to render.
  final CompatibilityMatch match;

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
          colors: [colors.backgroundEnd, colors.background],
        ),
        border: Border.all(color: colors.gold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SanctumSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SignAvatar(sign: match.you.sign, size: 46),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SanctumSpacing.md,
                  ),
                  child: Text(
                    '+',
                    style: type.title.copyWith(color: colors.gold),
                  ),
                ),
                SignAvatar(sign: match.them.sign, size: 46),
              ],
            ),
            const SizedBox(height: SanctumSpacing.md),
            Text(
              match.pairing.toUpperCase(),
              style: type.caption.copyWith(
                color: colors.gold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: SanctumSpacing.lg),
            ScoreDial(
              score: match.overall,
              verdict: match.verdict,
              yours: match.you.sign.element,
              theirs: match.them.sign.element,
              size: 170,
              animate: false,
            ),
            const SizedBox(height: SanctumSpacing.lg),
            Text(
              match.shareLine,
              style: type.quote,
              textAlign: TextAlign.center,
            ),
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
                Text(match.aspect.displayName, style: type.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
