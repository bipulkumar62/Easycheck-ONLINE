import 'package:flutter/material.dart';

import '../../app/theme/app_typography.dart';

enum AppSnackType { info, success, error }

/// Branded floating message used instead of the default dark snackbar.
///
/// It follows the active theme (patient navy or clinic-admin emerald), keeps a
/// readable surface, and uses a small coloured icon so status feedback feels
/// deliberate rather than like a system error box.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final scheme = Theme.of(context).colorScheme;
    final accent = switch (type) {
      AppSnackType.success => scheme.secondary,
      AppSnackType.error => scheme.error,
      AppSnackType.info => scheme.primary,
    };
    final icon = switch (type) {
      AppSnackType.success => Icons.check_circle_rounded,
      AppSnackType.error => Icons.error_outline_rounded,
      AppSnackType.info => Icons.info_outline_rounded,
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: duration,
          content: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      color: scheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  /// Infers the visual tone from common action messages so existing call sites
  /// get useful feedback without repeating a type argument everywhere.
  static void showAuto(BuildContext context, String message) {
    final lower = message.toLowerCase();
    final isError =
        lower.contains('could not') ||
        lower.contains('failed') ||
        lower.contains('not available') ||
        lower.contains('not active') ||
        lower.contains('expired') ||
        lower.contains('error') ||
        lower.contains('unable') ||
        message.contains('नहीं') ||
        message.contains('विफल') ||
        message.contains('त्रुटि') ||
        message.contains('गलती');
    final isSuccess =
        lower.contains('updated') ||
        lower.contains('saved') ||
        lower.contains('reset') ||
        lower.contains('deleted') ||
        lower.contains('created') ||
        lower.contains('sent') ||
        message.contains('अपडेट') ||
        message.contains('सहेजा') ||
        message.contains('रीसेट') ||
        message.contains('हटाया') ||
        message.contains('बनाया') ||
        message.contains('भेजा');
    show(
      context,
      message,
      type: isError
          ? AppSnackType.error
          : isSuccess
          ? AppSnackType.success
          : AppSnackType.info,
    );
  }
}
