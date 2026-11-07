import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'live_dot.dart';

enum ClinicOperationalStatus {
  available,
  delayed,
  unavailable,
}

/// Generic Status Pill matching the exact specs in DESIGN_TOKENS.md.
class StatusPill extends StatelessWidget {
  final ClinicOperationalStatus status;
  final String label;

  const StatusPill({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color dotColor;

    switch (status) {
      case ClinicOperationalStatus.available:
        bgColor = PatientColors.surfaceContainerLow;
        textColor = PatientColors.secondary;
        dotColor = PatientColors.secondary;
        break;
      case ClinicOperationalStatus.delayed:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        dotColor = const Color(0xFFF59E0B);
        break;
      case ClinicOperationalStatus.unavailable:
        bgColor = PatientColors.surfaceContainer;
        textColor = PatientColors.onSurfaceVariant;
        dotColor = PatientColors.outline;
        break;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 240.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveDot(
            size: 5.5,
            color: dotColor,
            pulse: status == ClinicOperationalStatus.available,
            semanticsLabel: label,
          ),
          const SizedBox(width: 2.0),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PatientTypography.labelSm.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
