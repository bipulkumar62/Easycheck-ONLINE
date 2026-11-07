import 'package:flutter/material.dart';

import '../constants/asset_constants.dart';

/// Canonical EasyCheck logo mark.
///
/// The source asset is a square, pre-padded, transparent PNG. Wrapping it in a
/// consistent tile prevents the old wide-wordmark-in-a-square distortion and
/// keeps the mark optically centred on every surface.
class BrandMark extends StatelessWidget {
  final double size;
  final double padding;
  final Color background;
  final Color borderColor;
  final double radius;
  final bool showShadow;

  const BrandMark({
    super.key,
    this.size = 48,
    this.padding = 5,
    this.background = Colors.white,
    this.borderColor = const Color(0x14073B78),
    this.radius = 14,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF073B78).withValues(alpha: 0.10),
                  blurRadius: size * 0.32,
                  offset: Offset(0, size * 0.10),
                ),
              ]
            : null,
      ),
      child: Image.asset(
        AssetConstants.logoMark,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => Icon(
          Icons.local_hospital_rounded,
          color: const Color(0xFF006D44),
          size: size * 0.55,
        ),
      ),
    );
  }
}
