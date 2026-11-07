import 'package:flutter/material.dart';

/// Exact color values derived strictly from DESIGN_TOKENS.md
class PatientColors {
  PatientColors._();

  // Primary Navy Hierarchy
  static const Color primary = Color(0xFF002553);
  static const Color primaryContainer = Color(0xFF073B78);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF82A7EB);
  static const Color inversePrimary = Color(0xFFAAC7FF);
  static const Color primaryFixed = Color(0xFFD7E3FF);
  static const Color primaryFixedDim = Color(0xFFAAC7FF);
  static const Color onPrimaryFixed = Color(0xFF001B3E);
  static const Color onPrimaryFixedVariant = Color(0xFF1A4683);

  // Secondary Emerald Hierarchy (Status, Live Actions)
  static const Color secondary = Color(0xFF006D44);
  static const Color secondaryContainer = Color(0xFF7DF7B6);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF007147);
  static const Color secondaryFixed = Color(0xFF80FAB9);
  static const Color secondaryFixedDim = Color(0xFF62DD9E);
  static const Color onSecondaryFixed = Color(0xFF002111);
  static const Color onSecondaryFixedVariant = Color(0xFF005232);

  // Tertiary Slate/Teal
  static const Color tertiary = Color(0xFF002942);
  static const Color tertiaryContainer = Color(0xFF004064);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF4FAEF4);

  // Surfaces & Canvas
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF434750);
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);
  static const Color outline = Color(0xFF737781);
  static const Color outlineVariant = Color(0xFFC3C6D2);
  static const Color surfaceTint = Color(0xFF375E9D);

  // Error & Alerts
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
}

/// Admin color palette ("Clinical Precision") from DESIGN_TOKENS.md
class AdminColors {
  AdminColors._();

  // Primary Emerald Hierarchy (Operational Dispatch)
  static const Color primary = Color(0xFF006A42);
  static const Color primaryContainer = Color(0xFF008655);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFF6FFF6);
  static const Color inversePrimary = Color(0xFF62DD9E);
  static const Color primaryFixed = Color(0xFF80FAB9);
  static const Color primaryFixedDim = Color(0xFF62DD9E);
  static const Color onPrimaryFixed = Color(0xFF002111);
  static const Color onPrimaryFixedVariant = Color(0xFF005232);

  // Secondary Navy Authority Hierarchy
  static const Color secondary = Color(0xFF375E9D);
  static const Color secondaryContainer = Color(0xFF94B9FE);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF1D4886);
  static const Color secondaryFixed = Color(0xFFD7E3FF);
  static const Color secondaryFixedDim = Color(0xFFAAC7FF);
  static const Color onSecondaryFixed = Color(0xFF001B3E);
  static const Color onSecondaryFixedVariant = Color(0xFF1A4683);

  // Tertiary Slate
  static const Color tertiary = Color(0xFF535F59);
  static const Color tertiaryContainer = Color(0xFF6B7771);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFF5FFF8);

  // Surfaces & Canvas
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCCDBF3);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE6EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD5E3FC);
  static const Color surfaceVariant = Color(0xFFD5E3FC);
  static const Color onSurface = Color(0xFF0D1C2E);
  static const Color onSurfaceVariant = Color(0xFF3D4A41);
  static const Color inverseSurface = Color(0xFF233144);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);
  static const Color outline = Color(0xFF6D7A70);
  static const Color outlineVariant = Color(0xFFBCCABF);

  // Error & Destructive Reset
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
}
