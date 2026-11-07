import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';

import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_reset_studio_screen.dart';
import '../features/admin/admin_unauthorized_screen.dart';
import '../features/authentication/admin_subscription_inactive_screen.dart';
import '../features/authentication/admin_access_request_model.dart';
import '../features/authentication/admin_access_request_screen.dart';
import '../features/authentication/admin_login_screen.dart';
import '../features/authentication/admin_pending_approval_screen.dart';
import '../features/authentication/admin_rejected_screen.dart';
import '../features/authentication/admin_request_submitted_screen.dart';
import '../features/authentication/auth_gate_screen.dart';
import '../features/authentication/patient_login_screen.dart';
import '../features/authentication/role_selection_screen.dart';
import '../features/clinic/clinic_details_screen.dart';
import '../features/clinics/clinic_model.dart' as firestore_clinic;
import '../features/patient/patient_home_screen.dart';
import '../shared/models/clinic_model.dart' as display_clinic;
import 'localization/app_localizations.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

/// Root application widget bootstrapping dual themes, localization, and routing.
///
/// The entry route is always role selection. Authentication state is handled
/// by the login screens and the [AuthGateScreen], which verifies the Firebase
/// UID against Firestore before opening any protected experience.
class EasyCheckApp extends StatelessWidget {
  const EasyCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyCheck Online',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.patientTheme,
      locale: AppLocalizations.defaultLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.initial,
      routes: {
        AppRoutes.initial: (_) => const RoleSelectionScreen(),
        AppRoutes.patientLogin: (_) => const PatientLoginScreen(),
        AppRoutes.authGate: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          final role =
              arguments is AuthGateArgs ? arguments.role : AuthRole.patient;
          final screen = AuthGateScreen(role: role);
          return role == AuthRole.admin
              ? _AdminThemed(child: screen)
              : screen;
        },
        AppRoutes.patientHome: (_) => const PatientHomeScreen(),
        AppRoutes.patientClinicDetails: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is display_clinic.ClinicModel) {
            return ClinicDetailsScreen(clinic: arguments);
          }
          if (arguments is firestore_clinic.ClinicModel) {
            return ClinicDetailsScreen(
              clinic: arguments.toDisplayModel(),
            );
          }
          return const PatientHomeScreen();
        },
        AppRoutes.adminLogin: (_) =>
            _AdminThemed(child: const AdminLoginScreen()),
        AppRoutes.adminDashboard: (_) =>
            _AdminThemed(child: const AdminDashboardScreen()),
        AppRoutes.adminResetStudio: (_) =>
            _AdminThemed(child: const AdminResetStudioScreen()),
        AppRoutes.adminUnauthorized: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          return _AdminThemed(
            child: AdminUnauthorizedScreen(
              message: arguments is String ? arguments : null,
            ),
          );
        },
        AppRoutes.adminInactive: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          final clinic = arguments is firestore_clinic.ClinicModel
              ? arguments
              : null;
          return _AdminThemed(
            child: AdminSubscriptionInactiveScreen(clinic: clinic),
          );
        },
        AppRoutes.adminAccessRequest: (_) =>
            _AdminThemed(child: const AdminAccessRequestScreen()),
        AppRoutes.adminRequestSubmitted: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          return _AdminThemed(
            child: AdminRequestSubmittedScreen(
              args: arguments is AdminAccessFlowArgs ? arguments : null,
            ),
          );
        },
        AppRoutes.adminPendingApproval: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          return _AdminThemed(
            child: AdminPendingApprovalScreen(
              args: arguments is AdminAccessFlowArgs ? arguments : null,
            ),
          );
        },
        AppRoutes.adminRejected: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          return _AdminThemed(
            child: AdminRejectedScreen(
              args: arguments is AdminAccessFlowArgs ? arguments : null,
            ),
          );
        },
      },
    );
  }
}

/// Wraps admin screens with the Clinical Precision theme.
class _AdminThemed extends StatelessWidget {
  final Widget child;

  const _AdminThemed({required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.adminTheme, child: child);
  }
}
