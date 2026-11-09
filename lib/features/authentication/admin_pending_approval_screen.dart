import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/errors/app_failure.dart';
import 'admin_access_request_model.dart';
import 'admin_access_service.dart';
import 'admin_auth_widgets.dart';
import 'auth_error_mapper.dart';

/// Pending approval screen for a doctor/staff account.
///
/// The screen only reflects the stored request status. It never auto-approves
/// and never opens the clinic dashboard unless a fresh backend resolution
/// returns an approved membership.
class AdminPendingApprovalScreen extends StatefulWidget {
  final AdminAccessFlowArgs? args;

  const AdminPendingApprovalScreen({super.key, this.args});

  @override
  State<AdminPendingApprovalScreen> createState() =>
      _AdminPendingApprovalScreenState();
}

class _AdminPendingApprovalScreenState
    extends State<AdminPendingApprovalScreen> {
  final AdminAccessService _adminAccessService = AdminAccessService();

  bool _checking = false;
  String? _error;

  User? get _user {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkStatus() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final user = _user;
      if (user == null) {
        throw const UnauthorizedFailure(
          'Your sign-in session has expired. Please sign in again.',
        );
      }

      final resolution = await _adminAccessService.resolve(user);
      if (!mounted) return;

      switch (resolution.state) {
        case AdminAccessState.approved:
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
          return;
        case AdminAccessState.rejected:
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.adminRejected,
            arguments: AdminAccessFlowArgs(
              request: resolution.request!,
              clinic: resolution.clinic ?? widget.args?.clinic,
            ),
          );
          return;
        case AdminAccessState.none:
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.adminAccessRequest);
          return;
        case AdminAccessState.inactive:
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.adminInactive,
            arguments: resolution.clinic,
          );
          return;
        case AdminAccessState.inconsistent:
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.adminUnauthorized,
            arguments: resolution.message,
          );
          return;
        case AdminAccessState.pending:
          setState(() => _checking = false);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Your request is still pending Super Admin review.',
                ),
              ),
            );
          return;
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = AuthErrorMapper.message(error);
      });
    }
  }

  Future<void> _signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Still return to the role selection screen.
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.initial, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.args;
    final request = flow?.request;
    final clinicName =
        flow?.clinic?.name ??
        (request == null
            ? null
            : (request.requestedClinicName.trim().isNotEmpty
                  ? request.requestedClinicName
                  : request.requestedClinicId));

    return AdminAuthShell(
      title: 'Approval Pending',
      onSignOut: _signOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminStatusCard(
            icon: Icons.hourglass_top_rounded,
            eyebrow: 'PENDING REVIEW',
            title: 'Approval pending',
            body: request == null
                ? 'Your clinic access request is waiting for Super Admin '
                      'review. Check the status again shortly.'
                : 'Your request for $clinicName is waiting for Super Admin '
                      'review. The clinic dashboard stays locked until the '
                      'request is approved.',
            iconBackground: AdminColors.surfaceContainerHigh,
            iconColor: AdminColors.secondary,
            eyebrowColor: AdminColors.secondary,
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
                    label: 'Clinic ID',
                    value: request.requestedClinicId,
                  ),
                  AdminDetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Submitted',
                    value: DateFormat.yMMMd().add_jm().format(
                      request.createdAt,
                    ),
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
                Icon(
                  Icons.timer_outlined,
                  color: AdminColors.secondary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Expected review is within 8–12 hours. This is a review '
                    'target, not automatic approval. You can check again at '
                    'any time.',
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
          if (_error != null) ...[
            const SizedBox(height: 14),
            AdminErrorBanner(message: _error!),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _checking ? null : _checkStatus,
            icon: _checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AdminColors.onPrimary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 19),
            label: Text(
              _checking ? 'Checking status…' : 'Check status',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
          TextButton(onPressed: _signOut, child: const Text('Sign out')),
        ],
      ),
    );
  }
}
