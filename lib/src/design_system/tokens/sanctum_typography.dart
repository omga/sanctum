import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';

/// Sanctum's type scale.
///
/// Two families, doing different jobs. Cormorant Garamond is a high-
/// contrast serif that carries the app's voice at large sizes; Inter is
/// a neutral UI sans that gets out of the way at small ones. Using the
/// serif for body copy would be pretty and unreadable; using the sans
/// for display would be readable and generic.
///
/// ## Variable fonts
///
/// Both families ship as single *variable* font files, so one asset
/// covers every weight instead of six static TTFs. Weight is selected
/// through [FontVariation] on the `wght` axis. [TextStyle.fontWeight] is
/// set alongside it so that accessibility tooling and any fallback font
/// still resolve sensibly.
@immutable
class SanctumTypography extends ThemeExtension<SanctumTypography> {
  /// Creates a type set.
  const SanctumTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.title,
    required this.quote,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.label,
    required this.caption,
    required this.button,
  });

  /// Builds the default scale, inking it with [colors].
  factory SanctumTypography.nocturne(SanctumColors colors) {
    TextStyle base(
      String family,
      double size,
      double height,
      int weight,
      double spacing,
      Color color,
    ) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        height: height,
        letterSpacing: spacing,
        color: color,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: [FontVariation('wght', weight.toDouble())],
      );
    }

    return SanctumTypography(
      displayLarge: base(_serif, 44, 1.08, 300, -0.5, colors.textPrimary),
      displayMedium: base(_serif, 34, 1.14, 300, -0.3, colors.textPrimary),
      displaySmall: base(_serif, 27, 1.2, 400, -0.2, colors.textPrimary),
      title: base(_serif, 21, 1.3, 500, 0, colors.textPrimary),
      quote: base(_serif, 25, 1.45, 300, 0.2, colors.textPrimary),
      bodyLarge: base(_sans, 17, 1.5, 400, 0, colors.textPrimary),
      bodyMedium: base(_sans, 15, 1.52, 400, 0, colors.textPrimary),
      bodySmall: base(_sans, 13, 1.46, 400, 0.1, colors.textSecondary),
      label: base(_sans, 13, 1.2, 500, 0.4, colors.textSecondary),
      caption: base(_sans, 11, 1.3, 500, 1.2, colors.textTertiary),
      button: base(_sans, 16, 1.2, 600, 0.2, colors.textPrimary),
    );
  }

  /// Display family: high-contrast serif.
  static const String _serif = 'CormorantGaramond';

  /// UI family: neutral sans.
  static const String _sans = 'Inter';

  /// Symbol family, for astrological glyphs.
  static const String symbolFamily = 'SanctumSymbols';

  /// A style for drawing a zodiac glyph at [size].
  static TextStyle symbol(double size, Color color) => TextStyle(
    fontFamily: symbolFamily,
    fontSize: size,
    color: color,
    height: 1,
  );

  /// Hero numerals and the one big statement on a screen.
  final TextStyle displayLarge;

  /// Screen titles.
  final TextStyle displayMedium;

  /// Section headers.
  final TextStyle displaySmall;

  /// Card titles.
  final TextStyle title;

  /// Affirmations and oracle copy — the app's voice.
  final TextStyle quote;

  /// Lead paragraphs.
  final TextStyle bodyLarge;

  /// Default body copy.
  final TextStyle bodyMedium;

  /// Dense secondary copy.
  final TextStyle bodySmall;

  /// Form labels and tab titles.
  final TextStyle label;

  /// Overlines and metadata. Usually letterspaced caps.
  final TextStyle caption;

  /// Button text.
  final TextStyle button;

  @override
  SanctumTypography copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? title,
    TextStyle? quote,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? button,
  }) {
    return SanctumTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      title: title ?? this.title,
      quote: quote ?? this.quote,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      button: button ?? this.button,
    );
  }

  @override
  SanctumTypography lerp(
    ThemeExtension<SanctumTypography>? other,
    double t,
  ) {
    if (other is! SanctumTypography) return this;
    return SanctumTypography(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      displaySmall: TextStyle.lerp(displaySmall, other.displaySmall, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      quote: TextStyle.lerp(quote, other.quote, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
    );
  }
}
