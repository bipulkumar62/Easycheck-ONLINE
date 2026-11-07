/// Named route constants representing all discovered screens in the Stitch analysis.
class AppRoutes {
  AppRoutes._();

  static const String initial = '/';

  // Shared Authentication Route Constants
  static const String authGate = '/auth/gate';

  // Patient Route Constants
  static const String patientLogin = '/patient/login';
  static const String patientHome = '/patient/home';
  static const String patientClinicDetails = '/patient/clinic-details';

  // Admin Route Constants
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminResetStudio = '/admin/reset-studio';
  static const String adminUnauthorized = '/admin/unauthorized';
  static const String adminInactive = '/admin/inactive';
  static const String adminAccessRequest = '/admin/access-request';
  static const String adminRequestSubmitted = '/admin/request-submitted';
  static const String adminPendingApproval = '/admin/pending-approval';
  static const String adminRejected = '/admin/rejected';
}
