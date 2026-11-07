import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';

/// Shared shell for the Clinical Precision authentication and approval
/// screens. It keeps the same fixed top bar, surface colour, spacing and card
/// proportions as the original admin Stitch screens.
class AdminAuthShell extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;
  final VoidCallback? onSignOut;

  const AdminAuthShell({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AdminColors.surface,
      body: Stack(
        children: [
          // Ambient orbs from the Clinical Precision login screen.
          Positioned(
            top: -60,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AdminColors.primaryContainer.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: AdminColors.secondary.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              topPadding + 80,
              16,
              MediaQuery.of(context).padding.bottom + 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: child,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topPadding + 64,
              padding: EdgeInsets.only(top: topPadding),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF073B78), Color(0xFF0A4A8A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26041A33),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 2,
                      color: const Color(0xFF16A36A).withValues(alpha: 0.55),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        if (showBack)
                          IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                        const BrandMark(
                          size: 36,
                          padding: 4,
                          radius: 10,
                          showShadow: false,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (onSignOut != null)
                          IconButton(
                            tooltip: 'Sign out',
                            onPressed: onSignOut,
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xCCFFFFFF),
                              size: 21,
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card used for approval, pending, rejected and access-denied states.
class AdminStatusCard extends StatelessWidget {
  final IconData icon;
  final String? eyebrow;
  final String title;
  final String body;
  final Color iconBackground;
  final Color iconColor;
  final Color? eyebrowColor;
  final Widget? footer;

  const AdminStatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.eyebrow,
    this.iconBackground = AdminColors.surfaceContainerLow,
    this.iconColor = AdminColors.primary,
    this.eyebrowColor,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AdminColors.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14073B78),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x08073B78),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
          ),
          if (eyebrow != null) ...[
            const SizedBox(height: 16),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (eyebrowColor ?? iconColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      eyebrow!,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: eyebrowColor ?? iconColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AdminColors.onSurface,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AdminColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 20),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// A labelled detail row used on approval status screens.
class AdminDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AdminDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AdminColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AdminColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared error banner for authentication forms.
class AdminErrorBanner extends StatelessWidget {
  final String message;

  const AdminErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AdminColors.onErrorContainer.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AdminColors.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AdminColors.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
