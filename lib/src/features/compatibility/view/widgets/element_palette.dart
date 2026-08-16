import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';

/// Maps an element onto the palette.
///
/// Every avatar, ring and glyph in this feature is tinted by the sign's
/// element rather than by a single accent. It costs nothing and it means
/// two people on the same screen are visibly *different* — which is the
/// entire subject of the screen.
abstract final class ElementPalette {
  /// The lead colour for [element].
  static Color lead(ZodiacElement element, SanctumColors colors) =>
      switch (element) {
        ZodiacElement.fire => colors.gold,
        ZodiacElement.earth => colors.success,
        ZodiacElement.air => colors.accentSecondary,
        ZodiacElement.water => colors.accentCool,
      };

  /// The trailing colour, for gradients.
  static Color trail(ZodiacElement element, SanctumColors colors) =>
      switch (element) {
        ZodiacElement.fire => colors.accentTertiary,
        ZodiacElement.earth => colors.goldMuted,
        ZodiacElement.air => colors.accent,
        ZodiacElement.water => colors.accentSecondary,
      };

  /// A two-stop gradient for [element].
  static LinearGradient gradient(
    ZodiacElement element,
    SanctumColors colors,
  ) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lead(element, colors), trail(element, colors)],
  );
}
