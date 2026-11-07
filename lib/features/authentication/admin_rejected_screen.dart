import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import 'admin_access_request_model.dart';
import 'admin_auth_widgets.dart';

/// Rejected application screen.
///
/// Rejection never grants admin access. Reviewer identity is deliberately not
/// shown; only the clinic, request metadata and an optional applicant-facing
/// reason are displayed.
class AdminRejectedScreen extends StatelessWidget {
  final AdminAccessFlowArgs? args;

  const AdminRejectedScreen({super.key, this.args});

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
    final flow = args;
    final request = flow?.request;
    final clinicName = flow?.clinic?.name ?? request?.requestedClinicId;
    final reason = request?.rejectionReason?.trim();

    return AdminAuthShell(
      title: 'Application Status',
      onSignOut: () => _signOut(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminStatusCard(
            icon: Icons.cancel_outlined,
            eyebrow: 'NOT APPROVED',
            title: 'Application not approved',
            body: request == null
                ? 'Your clinic access request was not approved. Admin access '
                    'has not been granted.'
                : 'Your request for $clinicName was not approved. Admin access '
                    'has not been granted.',
            iconBackground: AdminColors.errorContainer,
            iconColor: AdminColors.onErrorContainer,
            eyebrowColor: AdminColors.onErrorContainer,
          ),
          if (request != null) ...[
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
                    label: 'Request ID',
                    value: request.id,
                  ),
                  if (request.reviewedAt != null)
                    AdminDetailRow(
                      icon: Icons.event_available_outlined,
                      label: 'Reviewed',
                      value: DateFormat.yMMMd()
                          .add_jm()
                          .format(request.reviewedAt!),
                    ),
                  if (reason != null && reason.isNotEmpty)
                    AdminDetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Reason',
                      value: reason,
                    ),
                ],
              ),
            ),
          ],
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
                Icon(Icons.info_outline_rounded,
                    color: AdminColors.secondary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'If your clinic details were incorrect, you can submit a '
                    'new request for a different clinic. Each request is '
                    'reviewed independently.',
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
              AppRoutes.adminAccessRequest,
            ),
            icon: const Icon(Icons.add_business_rounded, size: 19),
            label: const Text(
              'Request access for another clinic',
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
          TextButton(
            onPressed: () => _signOut(context),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
