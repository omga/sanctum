import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_typography.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/element_palette.dart';

/// A person, drawn as an element-tinted disc with their sign glyph.
///
/// Deliberately not a photograph. For celebrities that is a legal
/// position — a public birth date is a fact, a likeness is not — and for
/// everyone else it is simply better: a grid of consistent glyph discs
/// looks composed, where a grid of scraped press photos looks like a
/// scraper.
class SignAvatar extends StatelessWidget {
  /// Creates an avatar.
  const SignAvatar({
    required this.sign,
    this.size = 64,
    this.dimmed = false,
    super.key,
  });

  /// The sign to draw.
  final ZodiacSign sign;

  /// Diameter.
  final double size;

  /// Whether to render it muted, for locked states.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final gradient = ElementPalette.gradient(sign.element, colors);
    final lead = ElementPalette.lead(sign.element, colors);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: gradient.begin,
          end: gradient.end,
          colors: [
            gradient.colors.first.withValues(alpha: dimmed ? 0.18 : 0.42),
            gradient.colors.last.withValues(alpha: dimmed ? 0.10 : 0.22),
          ],
        ),
        border: Border.all(
          color: lead.withValues(alpha: dimmed ? 0.25 : 0.7),
          width: 1.5,
        ),
        boxShadow: dimmed
            ? null
            : [
                BoxShadow(
                  color: lead.withValues(alpha: 0.22),
                  blurRadius: size * 0.35,
                ),
              ],
      ),
      child: Text(
        sign.glyph,
        style: SanctumTypography.symbol(
          size * 0.42,
          dimmed ? colors.textTertiary : colors.textPrimary,
        ),
      ),
    );
  }
}
