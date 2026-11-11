import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double space2xl = 32.0;

  static const double gutter = 16.0;
  static const double gutterSm = 12.0;
  static const double margin = 16.0;
  static const double marginLg = 24.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius roundedDefault = BorderRadius.all(
    Radius.circular(8.0),
  );
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(20.0));
  static const BorderRadius rounded2xl = BorderRadius.all(
    Radius.circular(24.0),
  );
  static const BorderRadius rounded3xl = BorderRadius.all(
    Radius.circular(32.0),
  );
  static const BorderRadius roundedFull = BorderRadius.all(
    Radius.circular(999.0),
  );

  // Elevation tokens (soft, low-opacity navy shadows from DESIGN_TOKENS.md).
  static const List<BoxShadow> elevationLevel1 = [
    BoxShadow(
      color: Color(0x0F073B78),
      blurRadius: 8.0,
      offset: Offset(0.0, 2.0),
    ),
  ];

  static const List<BoxShadow> elevationLevel2 = [
    BoxShadow(
      color: Color(0x14073B78),
      blurRadius: 16.0,
      offset: Offset(0.0, 4.0),
    ),
  ];

  static const List<BoxShadow> elevationLevel3 = [
    BoxShadow(
      color: Color(0x1A073B78),
      blurRadius: 28.0,
      offset: Offset(0.0, 8.0),
    ),
  ];
}
