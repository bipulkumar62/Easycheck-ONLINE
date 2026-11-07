import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../authentication/admin_auth_widgets.dart';

/// Access denied / inconsistent authorization state — Clinical Precision.
///
/// This screen is shown when a signed-in account has no active clinic
/// membership, or when a request is marked approved but the trusted backend
/// has not created the matching membership. It offers only real actions.
class AdminUnauthorizedScreen extends StatelessWidget {
  final String? message;

  const AdminUnauthorizedScreen({super.key, this.message});

  User? get _user {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Still return to the role selection screen.
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.initial,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final body = message?.trim().isNotEmpty == true
        ? message!.trim()
        : 'Your Google account is signed in, but it does not have an active '
            'clinic membership. The clinic dashboard is available only after '
            'a Super Admin approves a clinic access request.';

    return AdminAuthShell(
      title: 'Access Review',
      onSignOut: () => _signOut(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminStatusCard(
            icon: Icons.shield_rounded,
            eyebrow: 'PERMISSIONS REQUIRED',
            title: 'Access Not Authorized',
            body: body,
            iconBackground: AdminColors.surfaceContainerLow,
            iconColor: AdminColors.secondary,
            eyebrowColor: AdminColors.onErrorContainer,
            footer: user == null
                ? null
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AdminDetailRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Signed-in account',
                      value: user.email ?? 'Google account',
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed(
              AppRoutes.adminAccessRequest,
            ),
            icon: const Icon(Icons.add_business_rounded, size: 19),
            label: const Text(
              'Request clinic access',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: AdminColors.onPrimary,
              minimumSize: const Size.fromHeight(50),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.switch_account_rounded, size: 18),
            label: const Text(
              'Sign out & switch account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.secondary,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              side: BorderSide(
                color: AdminColors.secondary.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
