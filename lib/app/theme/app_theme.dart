import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easycheck_online/app/theme/app_colors.dart';
import 'package:easycheck_online/app/theme/app_typography.dart';
import 'package:easycheck_online/app/theme/app_spacing.dart';

/// Central Material 3 themes for the two EasyCheck experiences:
/// - [patientTheme] — "Clinical Clarity" (navy primary)
/// - [adminTheme]   — "Clinical Precision" (emerald primary)
class AppTheme {
  const AppTheme._();

  static final ThemeData patientTheme = _buildTheme(
    brightness: Brightness.light,
    colors: const ColorScheme(
      brightness: Brightness.light,
      primary: PatientColors.primary,
      onPrimary: PatientColors.onPrimary,
      primaryContainer: PatientColors.primaryContainer,
      onPrimaryContainer: PatientColors.onPrimaryContainer,
      secondary: PatientColors.secondary,
      onSecondary: PatientColors.onSecondary,
      secondaryContainer: PatientColors.secondaryContainer,
      onSecondaryContainer: PatientColors.onSecondaryContainer,
      tertiary: PatientColors.tertiary,
      onTertiary: PatientColors.onTertiary,
      tertiaryContainer: PatientColors.tertiaryContainer,
      onTertiaryContainer: PatientColors.onTertiaryContainer,
      error: PatientColors.error,
      onError: PatientColors.onError,
      errorContainer: PatientColors.errorContainer,
      onErrorContainer: PatientColors.onErrorContainer,
      surface: PatientColors.surface,
      onSurface: PatientColors.onSurface,
      surfaceContainerLowest: PatientColors.surfaceContainerLowest,
      surfaceContainerLow: PatientColors.surfaceContainerLow,
      surfaceContainer: PatientColors.surfaceContainer,
      surfaceContainerHigh: PatientColors.surfaceContainerHigh,
      surfaceContainerHighest: PatientColors.surfaceContainerHighest,
      outline: PatientColors.outline,
      outlineVariant: PatientColors.outlineVariant,
      inverseSurface: PatientColors.inverseSurface,
      onInverseSurface: PatientColors.inverseOnSurface,
      inversePrimary: PatientColors.inversePrimary,
    ),
    scaffoldBackground: PatientColors.surface,
  );

  static final ThemeData adminTheme = _buildTheme(
    brightness: Brightness.light,
    colors: const ColorScheme(
      brightness: Brightness.light,
      primary: AdminColors.primary,
      onPrimary: AdminColors.onPrimary,
      primaryContainer: AdminColors.primaryContainer,
      onPrimaryContainer: AdminColors.onPrimaryContainer,
      secondary: AdminColors.secondary,
      onSecondary: AdminColors.onSecondary,
      secondaryContainer: AdminColors.secondaryContainer,
      onSecondaryContainer: AdminColors.onSecondaryContainer,
      tertiary: AdminColors.tertiary,
      onTertiary: AdminColors.onTertiary,
      tertiaryContainer: AdminColors.tertiaryContainer,
      onTertiaryContainer: AdminColors.onTertiaryContainer,
      error: AdminColors.error,
      onError: AdminColors.onError,
      errorContainer: AdminColors.errorContainer,
      onErrorContainer: AdminColors.onErrorContainer,
      surface: AdminColors.surface,
      onSurface: AdminColors.onSurface,
      surfaceContainerLowest: AdminColors.surfaceContainerLowest,
      surfaceContainerLow: AdminColors.surfaceContainerLow,
      surfaceContainer: AdminColors.surfaceContainer,
      surfaceContainerHigh: AdminColors.surfaceContainerHigh,
      surfaceContainerHighest: AdminColors.surfaceContainerHighest,
      outline: AdminColors.outline,
      outlineVariant: AdminColors.outlineVariant,
      inverseSurface: AdminColors.inverseSurface,
      onInverseSurface: AdminColors.inverseOnSurface,
      inversePrimary: AdminColors.inversePrimary,
    ),
    scaffoldBackground: AdminColors.surface,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colors,
    required Color scaffoldBackground,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Inter',
      colorScheme: colors,
      scaffoldBackgroundColor: scaffoldBackground,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLg,
        headlineLarge: AppTypography.headlineLg,
        headlineMedium: AppTypography.headlineMd,
        headlineSmall: AppTypography.headlineSm,
        titleLarge: AppTypography.headlineSm,
        titleMedium: AppTypography.titleMd,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        bodySmall: AppTypography.bodySm,
        labelLarge: AppTypography.labelLg,
        labelMedium: AppTypography.labelMd,
        labelSmall: AppTypography.labelSm,
      ),
      primaryTextTheme: const TextTheme(
        displayLarge: AppTypography.displayLg,
        headlineLarge: AppTypography.headlineLg,
        headlineMedium: AppTypography.headlineMd,
        headlineSmall: AppTypography.headlineSm,
        titleMedium: AppTypography.titleMd,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        bodySmall: AppTypography.bodySm,
        labelLarge: AppTypography.labelLg,
        labelMedium: AppTypography.labelMd,
        labelSmall: AppTypography.labelSm,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSm,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceLg,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyMd.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        labelStyle: AppTypography.bodyMd.copyWith(
          color: colors.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceXl,
            vertical: AppSpacing.spaceMd,
          ),
          textStyle: AppTypography.labelLg.copyWith(color: colors.onPrimary),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(64, 48),
          textStyle: AppTypography.labelLg.copyWith(color: colors.onPrimary),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: colors.outlineVariant),
          textStyle: AppTypography.labelLg.copyWith(color: colors.primary),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(48, 44),
          textStyle: AppTypography.labelLg.copyWith(color: colors.primary),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.onSurfaceVariant,
          minimumSize: const Size(44, 44),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        contentTextStyle: AppTypography.bodyMd.copyWith(
          color: colors.onSurface,
        ),
        actionTextColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.rounded2xl,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
      // Smooth, platform-native page changes. Android uses the predictive-back
      // shared-element transition when the OS supports it and the Material 3
      // fade-through transition otherwise.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
