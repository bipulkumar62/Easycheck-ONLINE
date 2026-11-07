import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static const Color primary = Color(0xFF002553);
  static const Color secondary = Color(0xFF006D44);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF434750);
  static const Color onError = Color(0xFFBA1A1A);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color outline = Color(0xFF737781);

  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 40.0,
    fontWeight: FontWeight.w700,
    color: Color(0xFF002553),
    letterSpacing: -0.03,
    height: 1.15,
  );

  static const TextStyle headlineXl = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36.0,
    fontWeight: FontWeight.w700,
    color: Color(0xFF002553),
    letterSpacing: -0.03,
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    color: Color(0xFF002553),
    letterSpacing: -0.02,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 26.0,
    fontWeight: FontWeight.w600,
    color: Color(0xFF002553),
    letterSpacing: -0.015,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    color: Color(0xFF002553),
    letterSpacing: -0.01,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: Color(0xFF002553),
    letterSpacing: 0.0,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: Color(0xFF002553),
    letterSpacing: 0.0,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: Color(0xFF0B1C30),
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: Color(0xFF334155),
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: Color(0xFF434750),
  );

  static const TextStyle labelLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: Color(0xFF434750),
    letterSpacing: 0.01,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: Color(0xFF434750),
    letterSpacing: 0.02,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    color: Color(0xFF434750),
    letterSpacing: 0.03,
  );
}

/// Backwards-compatible aliases used by the admin and patient screens.
/// Both roles share the same Inter type scale; only colors differ per theme.
typedef AdminTypography = AppTypography;
typedef PatientTypography = AppTypography;
