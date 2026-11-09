import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import 'admin_access_request_model.dart';
import 'admin_auth_widgets.dart';

/// Confirmation shown immediately after a pending request is written to
/// Firestore. It never implies approval.
class AdminRequestSubmittedScreen extends StatelessWidget {
  final AdminAccessFlowArgs? args;

  const AdminRequestSubmittedScreen({super.key, this.args});

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

  @override
  Widget build(BuildContext context) {
    final flow = args;
    if (flow == null) {
      return AdminAuthShell(
        title: 'Request Submitted',
        showBack: false,
        onSignOut: () => _signOut(context),
        child: AdminStatusCard(
          icon: Icons.info_outline_rounded,
          eyebrow: 'REQUEST STATUS',
          title: 'Request details unavailable',
          body:
              'Open the access request form again to view or resubmit your '
              'clinic request.',
          iconBackground: AdminColors.surfaceContainerHigh,
          iconColor: AdminColors.secondary,
          footer: FilledButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminAccessRequest,
              (route) => false,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: AdminColors.onPrimary,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Open access request',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final request = flow.request;
    final clinicName =
        flow.clinic?.name ??
        (request.requestedClinicName.trim().isNotEmpty
            ? request.requestedClinicName
            : request.requestedClinicId);
    final submitted = DateFormat.yMMMd().add_jm().format(request.createdAt);

    return AdminAuthShell(
      title: 'Request Submitted',
      showBack: false,
      onSignOut: () => _signOut(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminStatusCard(
            icon: Icons.mark_email_read_rounded,
            eyebrow: 'PENDING REVIEW',
            title: 'Request submitted',
            body:
                'Your application for $clinicName has been submitted. Our '
                'team will review it and contact you within 8–12 hours. You '
                'will not have clinic dashboard access until it is approved.',
            iconBackground: AdminColors.secondaryContainer,
            iconColor: AdminColors.onSecondaryContainer,
            eyebrowColor: AdminColors.onSecondaryContainer,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AdminColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F073B78),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                AdminDetailRow(
                  icon: Icons.local_hospital_outlined,
                  label: 'Clinic',
                  value: '$clinicName (${request.requestedClinicId})',
                ),
                AdminDetailRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Clinic ID',
                  value: request.requestedClinicId,
                ),
                AdminDetailRow(
                  icon: Icons.schedule_rounded,
                  label: 'Submitted',
                  value: submitted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: AdminColors.secondary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The review target is within 8–12 hours. This is a target, '
                    'not automatic approval. Access is enabled only after a '
                    'Super Admin approves the application.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AdminColors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed(
              AppRoutes.adminPendingApproval,
              arguments: flow,
            ),
            icon: const Icon(Icons.pending_actions_rounded, size: 19),
            label: const Text(
              'View request status',
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
          TextButton(
            onPressed: () => _signOut(context),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
