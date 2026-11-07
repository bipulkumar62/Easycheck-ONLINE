import 'package:easycheck_online/features/authentication/admin_access_request_model.dart';
import 'package:easycheck_online/features/authentication/admin_access_request_repository.dart';
import 'package:easycheck_online/features/authentication/admin_access_service.dart';
import 'package:easycheck_online/features/clinics/clinic_membership_model.dart';
import 'package:easycheck_online/features/clinics/clinic_membership_repository.dart';
import 'package:easycheck_online/features/clinics/clinic_model.dart';
import 'package:easycheck_online/features/clinics/clinic_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMembershipRepository extends ClinicMembershipRepository {
  _FakeMembershipRepository(this.memberships);

  final List<ClinicMembershipModel> memberships;

  @override
  Future<List<ClinicMembershipModel>> getUserMemberships(String userId) async {
    return memberships.where((item) => item.userId == userId).toList();
  }
}

class _FakeClinicRepository extends ClinicRepository {
  _FakeClinicRepository(this.clinics);

  final Map<String, ClinicModel> clinics;

  @override
  Future<ClinicModel?> getClinic(String clinicId) async => clinics[clinicId];

  @override
  Future<List<ClinicModel>> getAllClinics() async => clinics.values.toList();
}

class _FakeRequestRepository extends AdminAccessRequestRepository {
  _FakeRequestRepository(this.requests);

  final List<AdminAccessRequestModel> requests;

  @override
  Future<List<AdminAccessRequestModel>> getRequestsForUser(String uid) async {
    return requests.where((item) => item.uid == uid).toList();
  }
}

ClinicModel _clinic({
  String id = 'CLN-84920',
  bool isActive = true,
}) {
  final now = DateTime.utc(2026, 11, 5);
  return ClinicModel(
    clinicId: id,
    name: 'Al-Shifa Family Health Clinic',
    address: 'Suite 402, Medical City Blvd',
    city: 'Lahore',
    region: 'Punjab',
    phone: '+92 42 111 222 333',
    email: 'clinic@example.com',
    isActive: isActive,
    isOnline: true,
    doctorName: 'Dr. Rajesh Kumar',
    doctorCredentials: 'MD',
    doctorSpecialty: 'Cardiologist',
    doctorStatus: 'available',
    doctorTiming: 'Mon-Sat, 9:00 AM - 5:00 PM',
    todayParchiCount: 42,
    yesterdayParchiCount: 38,
    createdAt: now,
    updatedAt: now,
  );
}

ClinicMembershipModel _membership({
  String uid = 'uid-1',
  String clinicId = 'CLN-84920',
  String role = 'clinic_admin',
  bool isActive = true,
}) {
  return ClinicMembershipModel(
    userId: uid,
    clinicId: clinicId,
    role: role,
    permissions: ClinicMembershipModel.validPermissions,
    isActive: isActive,
    joinedAt: DateTime.utc(2026, 11, 1),
    assignedBy: 'super-admin',
  );
}

AdminAccessRequestModel _request({
  String uid = 'uid-1',
  String clinicId = 'CLN-84920',
  AdminAccessRequestStatus status = AdminAccessRequestStatus.pending,
}) {
  final now = DateTime.utc(2026, 11, 5, 9);
  return AdminAccessRequestModel(
    id: '${uid}_$clinicId',
    uid: uid,
    email: 'staff@example.com',
    displayName: 'Dr. Ayesha Khan',
    requestedClinicId: clinicId,
    contactNumber: '+92 300 1234567',
    status: status,
    createdAt: now,
    updatedAt: now,
    reviewedAt: status == AdminAccessRequestStatus.pending ? null : now,
    reviewedBy:
        status == AdminAccessRequestStatus.pending ? null : 'super-admin',
    rejectionReason: status == AdminAccessRequestStatus.rejected
        ? 'Clinic details could not be verified.'
        : null,
  );
}

AdminAccessService _service({
  List<ClinicMembershipModel> memberships = const [],
  Map<String, ClinicModel>? clinics,
  List<AdminAccessRequestModel> requests = const [],
}) {
  return AdminAccessService(
    membershipRepository: _FakeMembershipRepository(memberships),
    clinicRepository: _FakeClinicRepository(
      clinics ?? {'CLN-84920': _clinic()},
    ),
    requestRepository: _FakeRequestRepository(requests),
  );
}

void main() {
  group('AdminAccessService authorization resolution', () {
    test('active membership grants clinic access', () async {
      final resolution = await _service(
        memberships: [_membership()],
      ).resolveUid('uid-1');

      expect(resolution.state, AdminAccessState.approved);
      expect(resolution.clinic?.clinicId, 'CLN-84920');
      expect(resolution.membership?.role, 'clinic_admin');
    });

    test('a clinic record without a membership does not grant access',
        () async {
      final resolution = await _service(
        clinics: {'CLN-84920': _clinic()},
      ).resolveUid('uid-1');

      expect(resolution.state, AdminAccessState.none);
      expect(resolution.membership, isNull);
    });

    test('membership in a disabled clinic reports a subscription state',
        () async {
      final resolution = await _service(
        memberships: [_membership()],
        clinics: {'CLN-84920': _clinic(isActive: false)},
      ).resolveUid('uid-1');

      expect(resolution.state, AdminAccessState.inactive);
      expect(resolution.clinic?.clinicId, 'CLN-84920');
      expect(resolution.message, contains('subscription'));
    });

    test('pending request reports pending, not approved', () async {
      final resolution = await _service(
        requests: [_request()],
      ).resolveUid('uid-1');

      expect(resolution.state, AdminAccessState.pending);
      expect(resolution.request?.status, AdminAccessRequestStatus.pending);
    });

    test('rejected request reports rejected, not approved', () async {
      final resolution = await _service(
        requests: [_request(status: AdminAccessRequestStatus.rejected)],
      ).resolveUid('uid-1');

      expect(resolution.state, AdminAccessState.rejected);
      expect(resolution.request?.status, AdminAccessRequestStatus.rejected);
    });

    test('approved request without membership fails closed as inconsistent',
        () async {
      final resolution = await _service(
        requests: [_request(status: AdminAccessRequestStatus.approved)],
      ).resolveUid('uid-1');

      expect(resolution.state, AdminAccessState.inconsistent);
      expect(resolution.message, contains('no active clinic membership'));
    });

    test('unknown user with no request has no access', () async {
      final resolution = await _service().resolveUid('uid-unknown');

      expect(resolution.state, AdminAccessState.none);
      expect(resolution.clinic, isNull);
    });

    test('membership in one clinic wins over a pending request in another',
        () async {
      final resolution = await _service(
        memberships: [_membership(clinicId: 'CLN-84920')],
        clinics: {
          'CLN-84920': _clinic(),
          'CLN-84921': _clinic(id: 'CLN-84921'),
        },
        requests: [_request(clinicId: 'CLN-84921')],
      ).resolveUid('uid-1');

      expect(resolution.state, AdminAccessState.approved);
      expect(resolution.clinic?.clinicId, 'CLN-84920');
    });

    test('a request for another UID is ignored', () async {
      final resolution = await _service(
        requests: [_request(uid: 'uid-other')],
      ).resolveUid('uid-1');

      expect(resolution.state, AdminAccessState.none);
    });
  });
}
