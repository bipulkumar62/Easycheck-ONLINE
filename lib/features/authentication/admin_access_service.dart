import 'package:firebase_auth/firebase_auth.dart';

import '../../features/clinics/clinic_membership_model.dart';
import '../../features/clinics/clinic_membership_repository.dart';
import '../../features/clinics/clinic_model.dart';
import '../../features/clinics/clinic_repository.dart';
import 'admin_access_request_model.dart';
import 'admin_access_request_repository.dart';

/// Result of resolving a signed-in doctor/staff account.
enum AdminAccessState {
  /// An active membership or linked clinic administrator record exists.
  approved,

  /// The newest request is waiting for Super Admin review.
  pending,

  /// The newest request was rejected.
  rejected,

  /// No membership and no request exist yet.
  none,

  /// The membership is active but the clinic itself has been disabled by the
  /// network administrator. The clinic is offline and its controls are paused.
  inactive,

  /// A request is marked approved but the membership is missing/inactive.
  /// The client must fail closed and ask the user to contact support.
  inconsistent,
}

class AdminAccessResolution {
  final AdminAccessState state;
  final ClinicModel? clinic;
  final ClinicMembershipModel? membership;
  final AdminAccessRequestModel? request;
  final String? message;

  const AdminAccessResolution({
    required this.state,
    this.clinic,
    this.membership,
    this.request,
    this.message,
  });

  bool get isApproved => state == AdminAccessState.approved;
}

/// Server-backed authorization check for the clinic admin experience.
///
/// The client never trusts the role selected on the role-selection screen.
/// Every entry into the admin experience calls [resolve], which verifies the
/// Firebase UID against an active `clinic_members` record and then checks
/// `admin_access_requests` for pending or rejected applications. The clinic
/// document never carries an administrator identifier, so a public clinic read
/// cannot reveal a staff UID.
class AdminAccessService {
  final ClinicMembershipRepository _membershipRepository;
  final ClinicRepository _clinicRepository;
  final AdminAccessRequestRepository _requestRepository;

  AdminAccessService({
    ClinicMembershipRepository? membershipRepository,
    ClinicRepository? clinicRepository,
    AdminAccessRequestRepository? requestRepository,
  })  : _membershipRepository =
            membershipRepository ?? ClinicMembershipRepository(),
        _clinicRepository = clinicRepository ?? ClinicRepository(),
        _requestRepository = requestRepository ?? AdminAccessRequestRepository();

  Future<AdminAccessResolution> resolve(User user) => resolveUid(user.uid);

  /// UID-based resolution used by the widget and by unit tests. Authorization
  /// never depends on the provider, email or the role selected in the UI.
  Future<AdminAccessResolution> resolveUid(String uid) async {
    final memberships = await _membershipRepository.getUserMemberships(uid);

    AdminAccessResolution? inactiveResolution;
    for (final membership in memberships) {
      final clinic = await _clinicRepository.getClinic(membership.clinicId);
      if (clinic == null) continue;
      if (clinic.isActive) {
        return AdminAccessResolution(
          state: AdminAccessState.approved,
          clinic: clinic,
          membership: membership,
        );
      }
      inactiveResolution ??= AdminAccessResolution(
        state: AdminAccessState.inactive,
        clinic: clinic,
        membership: membership,
        message: '${clinic.name} is offline because its subscription is '
            'inactive. Queue controls and staff changes are paused until the '
            'network administrator enables the clinic again.',
      );
    }

    // An active membership in a disabled clinic is a subscription state, not
    // an authorization failure. Report it clearly instead of asking the clinic
    // admin to request access again.
    if (inactiveResolution != null) return inactiveResolution;

    // Clinic access is granted only by an active membership. A clinic document
    // on its own never authorizes the admin experience.
    final requests = await _requestRepository.getRequestsForUser(uid);
    if (requests.isNotEmpty) {
      final request = requests.first;
      final clinic =
          await _clinicRepository.getClinic(request.requestedClinicId);

      switch (request.status) {
        case AdminAccessRequestStatus.pending:
          return AdminAccessResolution(
            state: AdminAccessState.pending,
            clinic: clinic,
            request: request,
          );
        case AdminAccessRequestStatus.rejected:
          return AdminAccessResolution(
            state: AdminAccessState.rejected,
            clinic: clinic,
            request: request,
          );
        case AdminAccessRequestStatus.approved:
          return AdminAccessResolution(
            state: AdminAccessState.inconsistent,
            clinic: clinic,
            request: request,
            message: 'Your access request was approved, but no active clinic '
                'membership was found. Ask your clinic administrator to '
                'activate your membership, then try again.',
          );
      }
    }

    return const AdminAccessResolution(state: AdminAccessState.none);
  }
}
