import 'package:easycheck_online/app/theme/app_theme.dart';
import 'package:easycheck_online/features/admin/admin_dashboard_screen.dart';
import 'package:easycheck_online/features/admin/admin_unauthorized_screen.dart';
import 'package:easycheck_online/features/authentication/admin_access_request_screen.dart';
import 'package:easycheck_online/features/authentication/admin_login_screen.dart';
import 'package:easycheck_online/features/authentication/admin_pending_approval_screen.dart';
import 'package:easycheck_online/features/authentication/admin_rejected_screen.dart';
import 'package:easycheck_online/features/authentication/admin_request_submitted_screen.dart';
import 'package:easycheck_online/features/authentication/auth_gate_screen.dart';
import 'package:easycheck_online/features/authentication/patient_login_screen.dart';
import 'package:easycheck_online/features/authentication/role_selection_screen.dart';
import 'package:easycheck_online/features/clinic/clinic_details_screen.dart';
import 'package:easycheck_online/features/legal/legal_screen.dart';
import 'package:easycheck_online/features/patient/patient_home_screen.dart';
import 'package:easycheck_online/firebase_options.dart';
import 'package:easycheck_online/shared/models/clinic_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Firebase is not available in the test environment. Screens that need
      // it fail closed, which is what these layout tests rely on.
    }
  });

  const testClinic = ClinicModel(
    id: 'CLN-001',
    name: 'Al-Shifa Family Health Clinic',
    address: 'Suite 402, Medical City Blvd, Near Civic Center',
    doctor: DoctorModel(
      id: 'DR-001',
      name: 'Dr. Rajesh Kumar',
      credentials: 'MD',
      specialty: 'Consultant Cardiologist & General Physician',
      timing: 'Mon–Sat · 9:00 AM – 5:00 PM',
      status: DoctorStatus.available,
    ),
    status: ClinicStatus.available,
    todayParchiCount: 42,
    yesterdayParchiCount: 38,
  );

  final cases = <String, ({Widget screen, ThemeData theme})>{
    'role selection': (
      screen: const RoleSelectionScreen(),
      theme: AppTheme.patientTheme,
    ),
    'patient login': (
      screen: const PatientLoginScreen(),
      theme: AppTheme.patientTheme,
    ),
    'admin login': (
      screen: const AdminLoginScreen(),
      theme: AppTheme.adminTheme,
    ),
    'access request (signed out)': (
      screen: const AdminAccessRequestScreen(),
      theme: AppTheme.adminTheme,
    ),
    'request submitted (missing payload)': (
      screen: const AdminRequestSubmittedScreen(),
      theme: AppTheme.adminTheme,
    ),
    'pending approval': (
      screen: const AdminPendingApprovalScreen(),
      theme: AppTheme.adminTheme,
    ),
    'rejected request': (
      screen: const AdminRejectedScreen(),
      theme: AppTheme.adminTheme,
    ),
    'unauthorized access': (
      screen: const AdminUnauthorizedScreen(),
      theme: AppTheme.adminTheme,
    ),
    'patient home': (
      screen: const PatientHomeScreen(),
      theme: AppTheme.patientTheme,
    ),
    'clinic details': (
      screen: const ClinicDetailsScreen(clinic: testClinic),
      theme: AppTheme.patientTheme,
    ),
    'privacy policy': (
      screen: const LegalScreen(document: LegalDocument.privacy),
      theme: AppTheme.patientTheme,
    ),
    'admin dashboard (fails closed)': (
      screen: const AdminDashboardScreen(),
      theme: AppTheme.adminTheme,
    ),
    'auth gate (admin)': (
      screen: const AuthGateScreen(role: AuthRole.admin),
      theme: AppTheme.adminTheme,
    ),
  };

  for (final entry in cases.entries) {
    for (final scale in <double>[1.3, 2.0]) {
      testWidgets(
        '${entry.key} has no overflow at 320px and text scale $scale',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              theme: entry.value.theme,
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: entry.value.screen,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 700));

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
