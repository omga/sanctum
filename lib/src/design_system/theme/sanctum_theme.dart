import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_typography.dart';

/// Builds Sanctum's [ThemeData].
///
/// Material's own slots are populated too, so stock widgets
/// ([TextField], [SnackBar], dialogs) inherit the look without being
/// restyled one by one. Sanctum's own tokens ride along as
/// [ThemeExtension]s and are the ones app code actually reads.
abstract final class SanctumTheme {
  /// The dark cosmic / aurora theme.
  static ThemeData nocturne() {
    final colors = SanctumColors.nocturne();
    final type = SanctumTypography.nocturne(colors);

    final scheme = ColorScheme.dark(
      primary: colors.accent,
      onPrimary: colors.textOnAccent,
      secondary: colors.accentSecondary,
      onSecondary: colors.textOnAccent,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      error: colors.danger,
      onError: colors.textOnAccent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      splashFactory: InkSparkle.splashFactory,
      extensions: [colors, type],

      // Sanctum draws its own backgrounds, so app bars must be invisible
      // rather than "dark".
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: type.title,
        iconTheme: IconThemeData(color: colors.textSecondary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      textTheme: TextTheme(
        displayLarge: type.displayLarge,
        displayMedium: type.displayMedium,
        displaySmall: type.displaySmall,
        titleLarge: type.title,
        bodyLarge: type.bodyLarge,
        bodyMedium: type.bodyMedium,
        bodySmall: type.bodySmall,
        labelLarge: type.button,
        labelSmall: type.caption,
      ),

      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SanctumRadii.xl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceRaised,
        contentTextStyle: type.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: SanctumRadii.mdAll,
        ),
      ),

      // The default pink-ish cursor fights the palette.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.gold,
        selectionColor: colors.accent.withValues(alpha: 0.35),
        selectionHandleColor: colors.gold,
      ),

      // Sanctum's own motion tokens govern real transitions; this simply
      // stops Material's default zoom from fighting them.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Terse, safe access to Sanctum's tokens from any [BuildContext].
///
/// `context.colors.accent` instead of
/// `Theme.of(context).extension<SanctumColors>()!.accent`. The
/// convenience matters: if reading a token is verbose, people type a hex
/// literal instead, and the design system quietly stops being true.
extension SanctumThemeX on BuildContext {
  /// Semantic colours.
  SanctumColors get colors => Theme.of(this).extension<SanctumColors>()!;

  /// The type scale.
  SanctumTypography get type => Theme.of(this).extension<SanctumTypography>()!;

  /// Bottom padding that clears the shell's floating nav pill.
  ///
  /// The shell sets `extendBody: true`, so every screen inside it draws
  /// underneath the pill and has to inset its own scroll padding. The
  /// idiom used to be a fixed `huge + xxl`, which is 96 — and the pill's
  /// top edge on an iPhone 16e sits 97 points above the bottom of the
  /// screen. One point short, which is invisible on a screen ending in a
  /// card and very visible on one ending in a wrapped caption: the last
  /// line renders behind the glass.
  ///
  /// It is short because a fixed number cannot be right on both kinds of
  /// phone. The pill floats *above* the home-indicator inset, so the
  /// clearance it needs is its own height plus that inset — 34 points
  /// here, zero on a phone with a physical button. `journal_screen`
  /// already worked this out for its compose button and says so in a
  /// comment; this is the same measurement, named once, so the next
  /// screen does not have to rediscover it.
  double get navBarClearance =>
      MediaQuery.paddingOf(this).bottom +
      SanctumSpacing.huge +
      SanctumSpacing.lg;
}
