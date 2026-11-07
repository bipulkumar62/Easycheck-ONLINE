import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/errors/app_failure.dart';
import '../../core/widgets/brand_mark.dart';
import 'admin_access_request_model.dart';
import 'admin_access_service.dart';
import 'auth_error_mapper.dart';
import 'user_profile_repository.dart';

/// Which experience the user selected on the role-selection screen.
enum AuthRole { patient, admin }

/// Arguments for [AppRoutes.authGate].
class AuthGateArgs {
  final AuthRole role;

  const AuthGateArgs({required this.role});
}

/// Authentication loading / verification screen.
///
/// The Firebase user already exists when this screen opens. It creates or
/// retrieves the patient profile, or resolves the clinic-admin membership and
/// approval request, then routes to the correct destination. No success state
/// is simulated: every branch is driven by an actual Firebase result.
class AuthGateScreen extends StatefulWidget {
  final AuthRole role;

  const AuthGateScreen({super.key, required this.role});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final UserProfileRepository _profileRepository = UserProfileRepository();
  final AdminAccessService _adminAccessService = AdminAccessService();

  bool _loading = true;
  bool _resolving = false;
  String? _error;

  bool get _isAdmin => widget.role == AuthRole.admin;

  Color get _surface =>
      _isAdmin ? AdminColors.surface : PatientColors.surface;
  Color get _primary =>
      _isAdmin ? AdminColors.primary : PatientColors.primary;
  Color get _onSurface =>
      _isAdmin ? AdminColors.onSurface : PatientColors.onSurface;
  Color get _onSurfaceVariant => _isAdmin
      ? AdminColors.onSurfaceVariant
      : PatientColors.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    if (_resolving) return;
    _resolving = true;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      if (Firebase.apps.isEmpty) {
        throw const ServerFailure(
          'Firebase is not configured on this device. Please install the '
          'latest version of the app and try again.',
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw const UnauthorizedFailure(
          'Your sign-in session has expired. Please sign in again.',
        );
      }

      if (!_isAdmin) {
        await _profileRepository.ensurePatientProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.patientHome,
          (route) => false,
        );
        return;
      }

      final resolution = await _adminAccessService.resolve(user);
      if (!mounted) return;
      _routeForResolution(resolution);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthErrorMapper.message(error);
      });
    } finally {
      _resolving = false;
    }
  }

  void _routeForResolution(AdminAccessResolution resolution) {
    switch (resolution.state) {
      case AdminAccessState.approved:
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.adminDashboard,
          (route) => false,
        );
        return;
      case AdminAccessState.pending:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.adminPendingApproval,
          arguments: AdminAccessFlowArgs(
            request: resolution.request!,
            clinic: resolution.clinic,
          ),
        );
        return;
      case AdminAccessState.rejected:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.adminRejected,
          arguments: AdminAccessFlowArgs(
            request: resolution.request!,
            clinic: resolution.clinic,
          ),
        );
        return;
      case AdminAccessState.none:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.adminAccessRequest,
        );
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
    }
  }

  Future<void> _signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Still return to the entry screen if sign-out fails.
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.initial,
      (route) => false,
    );
  }

  void _backToRoleSelection() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.initial,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _loading ? _buildLoading() : _buildError(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(size: 72, padding: 9, radius: 20),
        const SizedBox(height: 24),
        Text(
          _isAdmin ? 'Verifying clinic access' : 'Preparing your portal',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isAdmin
              ? 'Checking your clinic membership and approval status…'
              : 'Securing your session and loading your patient profile…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: _onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isAdmin
            ? AdminColors.surfaceContainerLowest
            : PatientColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _isAdmin
                  ? AdminColors.errorContainer
                  : PatientColors.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.gpp_bad_rounded,
              color: _isAdmin
                  ? AdminColors.onErrorContainer
                  : PatientColors.onErrorContainer,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not verify your account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _resolve,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Try again',
              textAlign: TextAlign.center,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
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
          OutlinedButton(
            onPressed: _backToRoleSelection,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              minimumSize: const Size.fromHeight(44),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              side: BorderSide(
                color: _primary.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to role selection',
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: _signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
