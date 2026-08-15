import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_palette.dart';

/// Semantic colour roles for Sanctum.
///
/// Widgets read colours from here — never from [SanctumPalette], and
/// never as a raw hex literal. Access it through `context.colors`.
///
/// It is a [ThemeExtension] rather than a bag of statics so that a
/// second theme can be introduced later by supplying different values,
/// with zero widget changes. [lerp] is what lets Flutter animate
/// smoothly between themes when that day comes.
@immutable
class SanctumColors extends ThemeExtension<SanctumColors> {
  /// Creates a semantic colour set.
  const SanctumColors({
    required this.background,
    required this.backgroundEnd,
    required this.surface,
    required this.surfaceRaised,
    required this.glassFill,
    required this.glassBorder,
    required this.accent,
    required this.accentSecondary,
    required this.accentTertiary,
    required this.accentCool,
    required this.gold,
    required this.goldMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAccent,
    required this.divider,
    required this.glow,
    required this.scrim,
    required this.success,
    required this.warning,
    required this.danger,
    required this.moonLit,
    required this.moonShadow,
  });

  /// The dark cosmic / aurora theme — Sanctum's default and, for now,
  /// only art direction.
  factory SanctumColors.nocturne() => SanctumColors(
    background: SanctumPalette.abyss,
    backgroundEnd: SanctumPalette.midnight,
    surface: SanctumPalette.nebula,
    surfaceRaised: SanctumPalette.veil,
    glassFill: SanctumPalette.white.withValues(alpha: 0.06),
    glassBorder: SanctumPalette.white.withValues(alpha: 0.12),
    accent: SanctumPalette.violet,
    accentSecondary: SanctumPalette.orchid,
    accentTertiary: SanctumPalette.rose,
    accentCool: SanctumPalette.azure,
    gold: SanctumPalette.gold,
    goldMuted: SanctumPalette.goldDeep,
    textPrimary: SanctumPalette.moonlight,
    textSecondary: SanctumPalette.mist,
    textTertiary: SanctumPalette.whisper,
    textOnAccent: SanctumPalette.voidBlack,
    divider: SanctumPalette.white.withValues(alpha: 0.08),
    glow: SanctumPalette.violet,
    scrim: SanctumPalette.voidBlack.withValues(alpha: 0.6),
    success: SanctumPalette.jade,
    warning: SanctumPalette.amber,
    danger: SanctumPalette.ember,
    moonLit: SanctumPalette.moonlight,
    moonShadow: SanctumPalette.veil,
  );

  /// Base ground behind every screen.
  final Color background;

  /// Far end of the background gradient.
  final Color backgroundEnd;

  /// Sheets, bars and grouped backgrounds.
  final Color surface;

  /// Cards sitting above [surface].
  final Color surfaceRaised;

  /// Fill of a frosted glass panel.
  final Color glassFill;

  /// Hairline edge that gives glass its lift.
  final Color glassBorder;

  /// Primary interactive colour.
  final Color accent;

  /// Second aurora stop; gradients and highlights.
  final Color accentSecondary;

  /// Warm aurora stop; used least, so it stays special.
  final Color accentTertiary;

  /// Cool counterpoint for charts and rare states.
  final Color accentCool;

  /// Ceremonial marks: rules, glyphs, streak flames.
  final Color gold;

  /// Gold that must not compete for attention.
  final Color goldMuted;

  /// Headlines and body copy.
  final Color textPrimary;

  /// Supporting copy.
  final Color textSecondary;

  /// Captions, metadata, disabled labels.
  final Color textTertiary;

  /// Text drawn on top of [accent].
  final Color textOnAccent;

  /// Hairline separators.
  final Color divider;

  /// Colour of bloom and outer glow effects.
  final Color glow;

  /// Dimming layer behind modals.
  final Color scrim;

  /// Positive state.
  final Color success;

  /// Cautionary state.
  final Color warning;

  /// Destructive or failed state.
  final Color danger;

  /// The illuminated face of the moon.
  final Color moonLit;

  /// The unlit face of the moon.
  final Color moonShadow;

  @override
  SanctumColors copyWith({
    Color? background,
    Color? backgroundEnd,
    Color? surface,
    Color? surfaceRaised,
    Color? glassFill,
    Color? glassBorder,
    Color? accent,
    Color? accentSecondary,
    Color? accentTertiary,
    Color? accentCool,
    Color? gold,
    Color? goldMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnAccent,
    Color? divider,
    Color? glow,
    Color? scrim,
    Color? success,
    Color? warning,
    Color? danger,
    Color? moonLit,
    Color? moonShadow,
  }) {
    return SanctumColors(
      background: background ?? this.background,
      backgroundEnd: backgroundEnd ?? this.backgroundEnd,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      accent: accent ?? this.accent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentTertiary: accentTertiary ?? this.accentTertiary,
      accentCool: accentCool ?? this.accentCool,
      gold: gold ?? this.gold,
      goldMuted: goldMuted ?? this.goldMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      divider: divider ?? this.divider,
      glow: glow ?? this.glow,
      scrim: scrim ?? this.scrim,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      moonLit: moonLit ?? this.moonLit,
      moonShadow: moonShadow ?? this.moonShadow,
    );
  }

  @override
  SanctumColors lerp(ThemeExtension<SanctumColors>? other, double t) {
    if (other is! SanctumColors) return this;
    return SanctumColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundEnd: Color.lerp(backgroundEnd, other.backgroundEnd, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      accentTertiary: Color.lerp(accentTertiary, other.accentTertiary, t)!,
      accentCool: Color.lerp(accentCool, other.accentCool, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldMuted: Color.lerp(goldMuted, other.goldMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      moonLit: Color.lerp(moonLit, other.moonLit, t)!,
      moonShadow: Color.lerp(moonShadow, other.moonShadow, t)!,
    );
  }
}
