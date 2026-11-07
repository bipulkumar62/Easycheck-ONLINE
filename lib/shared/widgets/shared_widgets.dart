import 'package:flutter/material.dart';
import 'package:easycheck_online/app/theme/app_colors.dart';
import 'package:easycheck_online/app/theme/app_typography.dart';
import 'package:easycheck_online/app/theme/app_spacing.dart';
import '../../core/widgets/live_dot.dart';

class LiveStatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color dotColor;

  const LiveStatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveDot(
            size: 6,
            color: dotColor,
            semanticsLabel: label,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class LivePulseDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool animate;

  const LivePulseDot({
    super.key,
    required this.color,
    this.size = 8.0,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiveDot(
      size: size,
      color: color,
      pulse: animate,
    );
  }
}

class StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const StatusButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.12)
                : AdminColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10.0),
            border: isActive
                ? Border.all(color: activeColor, width: 2.0)
                : null,
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isActive ? activeColor : AdminColors.onSurfaceVariant,
                  size: 24.0),
              const SizedBox(height: 3.0),
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  color: isActive ? activeColor : AdminColors.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
