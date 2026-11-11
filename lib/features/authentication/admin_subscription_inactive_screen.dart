import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../clinics/clinic_model.dart';
import 'admin_auth_widgets.dart';
import 'auth_gate_screen.dart';

/// Shown when a clinic membership is valid but the clinic itself has been
/// disabled by the network administrator. This is a subscription state, not an
/// authorization failure: the clinic admin keeps the membership and simply
/// waits for the clinic to be enabled again.
class AdminSubscriptionInactiveScreen extends StatelessWidget {
  final ClinicModel? clinic;
  final String? message;

  const AdminSubscriptionInactiveScreen({super.key, this.clinic, this.message});

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
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.initial, (route) => false);
  }

  void _checkAgain(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.authGate,
      (route) => false,
      arguments: const AuthGateArgs(role: AuthRole.admin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final clinicName = clinic?.name.trim();
    final body = message?.trim().isNotEmpty == true
        ? message!.trim()
        : 'This clinic is offline because its subscription is inactive. '
              'Queue controls and staff changes are paused until the network '
              'administrator enables the clinic again.';

    return AdminAuthShell(
      title: 'Subscription Inactive',
      onSignOut: () => _signOut(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminStatusCard(
            icon: Icons.pause_circle_rounded,
            eyebrow: 'SUBSCRIPTION INACTIVE',
            title: 'Clinic Temporarily Offline',
            body: body,
            iconBackground: AdminColors.errorContainer,
            iconColor: AdminColors.onErrorContainer,
            eyebrowColor: AdminColors.onErrorContainer,
            footer: clinicName == null && user == null
                ? null
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (clinicName != null)
                          AdminDetailRow(
                            icon: Icons.local_hospital_outlined,
                            label: 'Clinic',
                            value: clinicName,
                          ),
                        if (user != null)
                          AdminDetailRow(
                            icon: Icons.mail_outline_rounded,
                            label: 'Signed-in account',
                            value: user.email ?? 'Clinic account',
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _checkAgain(context),
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text(
              'Check again',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
