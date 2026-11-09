import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easycheck_online/app/app.dart';
import 'package:easycheck_online/app/routes/app_routes.dart';
import 'package:easycheck_online/app/theme/app_theme.dart';
import 'package:easycheck_online/features/admin/admin_dashboard_screen.dart';
import 'package:easycheck_online/features/admin/admin_reset_studio_screen.dart';
import 'package:easycheck_online/features/admin/admin_unauthorized_screen.dart';
import 'package:easycheck_online/features/authentication/admin_access_request_model.dart';
import 'package:easycheck_online/features/authentication/admin_access_request_repository.dart';
import 'package:easycheck_online/features/authentication/admin_access_request_screen.dart';
import 'package:easycheck_online/features/authentication/admin_login_screen.dart';
import 'package:easycheck_online/features/authentication/admin_pending_approval_screen.dart';
import 'package:easycheck_online/features/authentication/admin_rejected_screen.dart';
import 'package:easycheck_online/features/authentication/admin_request_submitted_screen.dart';
import 'package:easycheck_online/features/authentication/auth_error_mapper.dart';
import 'package:easycheck_online/features/authentication/role_selection_screen.dart';
import 'package:easycheck_online/features/clinic/clinic_details_screen.dart';
import 'package:easycheck_online/features/patient/patient_home_screen.dart';
import 'package:easycheck_online/firebase_options.dart';
import 'package:easycheck_online/shared/models/clinic_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  setUpAll(() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Firebase is not available in the test environment. Screens that need
      // it fail closed, which is exactly what the security tests assert.
    }
  });

  group('Application entry', () {
    testWidgets('boots into role selection', (WidgetTester tester) async {
      await tester.pumpWidget(const EasyCheckApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Aap kis roop mein continue karna chahte hain?'),
        findsOneWidget,
      );
      expect(find.text('Continue as Patient'), findsOneWidget);
      expect(find.text('Continue as Doctor/Staff'), findsOneWidget);
    });

    testWidgets('patient role opens the patient Google login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const EasyCheckApp());
      await tester.pump(const Duration(milliseconds: 500));

      await tester.ensureVisible(find.byKey(const Key('role_patient_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('role_patient_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('OFFICIAL PATIENT PORTAL'), findsOneWidget);
    });

    testWidgets('doctor/staff role opens the clinic admin Google login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const EasyCheckApp());
      await tester.pump(const Duration(milliseconds: 500));

      await tester.ensureVisible(find.byKey(const Key('role_admin_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('role_admin_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Clinic Admin'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('role selection has no overflow at 320px width', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.patientTheme,
          home: const RoleSelectionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('Continue as Patient'), findsOneWidget);
      expect(find.text('Continue as Doctor/Staff'), findsOneWidget);
    });
  });

  group('Patient experience', () {
    testWidgets(
      'patient home renders discovery header and registered clinics',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.patientTheme,
            home: const PatientHomeScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Registered Clinics'), findsOneWidget);
        expect(find.text('India'), findsOneWidget);
      },
    );

    testWidgets('clinic details renders the parchi card and doctor timing', (
      WidgetTester tester,
    ) async {
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.patientTheme,
          home: const ClinicDetailsScreen(clinic: testClinic),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Clinic Details'), findsOneWidget);
      expect(find.text("Today's Parchi Count"), findsOneWidget);
      expect(find.text('Mon–Sat · 9:00 AM – 5:00 PM'), findsOneWidget);
    });

    testWidgets('patient home has no overflow at 320px width', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.patientTheme,
          home: const PatientHomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('Registered Clinics'), findsOneWidget);
    });

    testWidgets('patient home lays out on tablet widths', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.patientTheme,
          home: const PatientHomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('Search hospital or doctor'), findsOneWidget);
    });
  });

  group('Clinic admin experience', () {
    testWidgets('admin login renders clinic admin title and Google button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.adminTheme, home: const AdminLoginScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Clinic Admin'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('admin dashboard fails closed without authorization', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.adminTheme,
          home: const AdminDashboardScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Clinic Admin'), findsWidgets);
      expect(find.text('Could not open the dashboard'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('access request form requires a signed-in account', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.adminTheme,
          home: const AdminAccessRequestScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sign in to request access'), findsOneWidget);
      expect(find.text('Back to role selection'), findsOneWidget);
    });

    testWidgets('request submitted screen handles missing navigation payload', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.adminTheme,
          home: const AdminRequestSubmittedScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Request details unavailable'), findsOneWidget);
      expect(find.text('Open access request'), findsOneWidget);
    });

    testWidgets('pending approval screen shows a pending state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.adminTheme,
          home: const AdminPendingApprovalScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Approval pending'), findsOneWidget);
      expect(find.text('Check status'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('rejected screen shows a not-approved state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.adminTheme,
          home: const AdminRejectedScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Application not approved'), findsOneWidget);
      expect(find.text('Request access for another clinic'), findsOneWidget);
    });

    testWidgets(
      'unauthorized screen offers real request and sign-out actions',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.adminTheme,
            home: const AdminUnauthorizedScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Access Not Authorized'), findsOneWidget);
        expect(find.text('Request clinic access'), findsOneWidget);
        expect(find.text('Sign out & switch account'), findsOneWidget);
      },
    );

    testWidgets('reset studio renders scenario toolbar and reset modal', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.adminTheme,
          home: const AdminResetStudioScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Reset Dialog'), findsOneWidget);
      expect(find.text('Staff Audit'), findsOneWidget);
      expect(find.text('Reset today’s count?'), findsOneWidget);
    });
  });

  group('Approval request model', () {
    test('round-trips a pending request without losing fields', () {
      final now = DateTime.utc(2026, 11, 5, 9, 30);
      final request = AdminAccessRequestModel(
        id: 'uid-1_CLN-84920',
        uid: 'uid-1',
        email: 'staff@example.com',
        displayName: 'Dr. Ayesha Khan',
        requestedClinicId: 'CLN-84920',
        contactNumber: '+92 300 1234567',
        status: AdminAccessRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final restored = AdminAccessRequestModel.fromDocument(
        request.toMap(),
        request.id,
      );

      expect(restored.uid, request.uid);
      expect(restored.email, request.email);
      expect(restored.displayName, request.displayName);
      expect(restored.requestedClinicId, request.requestedClinicId);
      expect(restored.contactNumber, request.contactNumber);
      expect(restored.status, AdminAccessRequestStatus.pending);
      expect(restored.reviewedAt, isNull);
      expect(restored.reviewedBy, isNull);
      expect(restored.rejectionReason, isNull);
    });

    test('parses approved and rejected statuses and review metadata', () {
      final reviewedAt = DateTime.utc(2026, 11, 5, 10);
      final approved = AdminAccessRequestModel.fromDocument({
        'uid': 'uid-2',
        'email': 'lead@example.com',
        'displayName': 'Front Desk Lead',
        'requestedClinicId': 'CLN-84921',
        'status': 'approved',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 4)),
        'updatedAt': Timestamp.fromDate(reviewedAt),
        'reviewedAt': Timestamp.fromDate(reviewedAt),
        'reviewedBy': 'super-admin-uid',
      }, 'uid-2_CLN-84921');

      expect(approved.status, AdminAccessRequestStatus.approved);
      expect(approved.reviewedBy, 'super-admin-uid');
      expect(approved.reviewedAt, isNotNull);

      final rejected = AdminAccessRequestModel.fromDocument({
        'uid': 'uid-3',
        'status': 'rejected',
        'rejectionReason': 'Clinic details could not be verified.',
      }, 'uid-3_CLN-84922');

      expect(rejected.status, AdminAccessRequestStatus.rejected);
      expect(rejected.rejectionReason, contains('verified'));
    });

    test('unknown status fails closed to pending', () {
      expect(
        AdminAccessRequestStatus.fromValue('self-approved'),
        AdminAccessRequestStatus.pending,
      );
      expect(
        AdminAccessRequestStatus.fromValue(null),
        AdminAccessRequestStatus.pending,
      );
    });

    test('request document ID is deterministic per user and clinic', () {
      final repository = AdminAccessRequestRepository();
      expect(repository.documentId('uid-1', 'CLN-84920'), 'uid-1_CLN-84920');
      expect(
        repository.documentId('uid-1', 'CLN-84920'),
        repository.documentId('uid-1', 'CLN-84920'),
      );
      expect(
        repository.documentId('uid-1', 'CLN-84921'),
        isNot(repository.documentId('uid-1', 'CLN-84920')),
      );
    });
  });

  group('Authentication error mapping', () {
    test('cancellation is distinct and non-alarming', () {
      final error = FirebaseAuthException(code: 'popup-closed-by-user');
      expect(AuthErrorMapper.isCancellation(error), isTrue);
      expect(AuthErrorMapper.message(error), contains('cancelled'));
    });

    test('network failure tells the user to check connectivity', () {
      final error = FirebaseAuthException(code: 'network-request-failed');
      expect(AuthErrorMapper.message(error), contains('Network error'));
    });

    test('unauthorized domain is reported without leaking internals', () {
      final error = FirebaseAuthException(code: 'unauthorized-domain');
      final message = AuthErrorMapper.message(error);
      expect(message, contains('not authorized'));
      expect(message, isNot(contains('auth/unauthorized-domain')));
    });

    test('native Google cancellation is non-alarming', () {
      const error = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
      expect(AuthErrorMapper.isCancellation(error), isTrue);
      expect(AuthErrorMapper.message(error), contains('cancelled'));
    });

    test('native Google configuration errors stay non-technical', () {
      const error = GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'serverClientId must be provided on Android',
      );
      final message = AuthErrorMapper.message(error);
      expect(message, contains('not available'));
      expect(message, isNot(contains('serverClientId')));
      expect(message, isNot(contains('Android')));
    });
  });

  testWidgets('app routes expose the role-selection entry', (tester) async {
    expect(AppRoutes.initial, '/');
    expect(AppRoutes.authGate, '/auth/gate');
    expect(AppRoutes.adminAccessRequest, '/admin/access-request');
    expect(AppRoutes.adminPendingApproval, '/admin/pending-approval');
    expect(AppRoutes.adminRejected, '/admin/rejected');
  });
}
