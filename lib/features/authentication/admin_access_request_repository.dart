import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easycheck_online/core/errors/app_failure.dart';
import 'package:easycheck_online/features/authentication/admin_access_request_model.dart';

/// Reads and creates clinic-admin access requests.
///
/// The client may only create a `pending` request for its own authenticated
/// UID. Approval and rejection are intentionally not implemented here; they
/// belong to the trusted Super Admin backend (Admin SDK / Cloud Functions).
class AdminAccessRequestRepository {
  FirebaseFirestore? _firestore;

  FirebaseFirestore? get _fs {
    if (_firestore == null) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (_) {
        // Firebase not initialized (tests / UI-only mode).
        return null;
      }
    }
    return _firestore;
  }

  CollectionReference<Map<String, dynamic>>? _requestsCollection() {
    final fs = _fs;
    if (fs == null) return null;
    return fs.collection('admin_access_requests');
  }

  String documentId(String uid, String clinicId) => '${uid}_$clinicId';

  /// Fetches one request for a user/clinic pair.
  ///
  /// This uses the UID-filtered query instead of a direct document read. A
  /// direct read of a missing request is rejected by the security rules (the
  /// `resource` is null), which previously surfaced as a misleading
  /// "could not be saved" error on the very first submission.
  Future<AdminAccessRequestModel?> getRequest(
    String uid,
    String clinicId,
  ) async {
    final normalizedClinicId = clinicId.trim().toUpperCase();
    final requests = await getRequestsForUser(uid);
    for (final request in requests) {
      if (request.requestedClinicId == normalizedClinicId) {
        return request;
      }
    }
    return null;
  }

  /// Fetches every request belonging to [uid], newest first.
  ///
  /// The query is deliberately filtered by UID so it satisfies the Firestore
  /// rule that only the applicant may list their own requests.
  Future<List<AdminAccessRequestModel>> getRequestsForUser(String uid) async {
    try {
      final col = _requestsCollection();
      if (col == null) return const [];
      final snapshot = await col.where('uid', isEqualTo: uid).get();
      final requests = snapshot.docs
          .map(
            (doc) => AdminAccessRequestModel.fromDocument(doc.data(), doc.id),
          )
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to read access requests');
    }
  }

  /// Returns the newest request for [uid], if any.
  Future<AdminAccessRequestModel?> getLatestRequest(String uid) async {
    final requests = await getRequestsForUser(uid);
    if (requests.isEmpty) return null;
    return requests.first;
  }

  /// Creates a pending request for the signed-in user.
  ///
  /// The deterministic document ID prevents duplicate requests for the same
  /// user and clinic. The Firestore rules independently enforce the same
  /// constraint, so a client that bypasses this check still cannot create a
  /// duplicate or self-approve.
  Future<AdminAccessRequestModel> submitRequest({
    required String uid,
    required String email,
    required String displayName,
    required String clinicId,
    String clinicName = '',
    String contactNumber = '',
  }) async {
    final fs = _fs;
    if (fs == null) {
      throw const ServerFailure('Firebase is not available on this device.');
    }

    final normalizedClinicId = clinicId.trim().toUpperCase();
    if (!RegExp(r'^CLN-[0-9]{5}$').hasMatch(normalizedClinicId)) {
      throw const ServerFailure('Select a valid clinic before submitting.');
    }

    final normalizedEmail = email.trim();
    final ref = fs
        .collection('admin_access_requests')
        .doc(documentId(uid, normalizedClinicId));

    try {
      // Read through the UID-filtered query rather than the document itself.
      // A first-time applicant has no document yet, and a direct read of a
      // missing document is denied by the rules because `resource` is null.
      final existingRequests = await getRequestsForUser(uid);
      AdminAccessRequestModel? existing;
      for (final request in existingRequests) {
        if (request.requestedClinicId == normalizedClinicId) {
          existing = request;
          break;
        }
      }
      if (existing != null) {
        if (existing.status == AdminAccessRequestStatus.rejected) {
          throw const ServerFailure(
            'A previous request for this clinic was not approved. '
            'Contact your clinic administrator for help.',
          );
        }
        throw const ServerFailure(
          'You already have a request for this clinic. '
          'Check your request status instead.',
        );
      }

      final now = DateTime.now();
      await ref.set({
        'uid': uid,
        'email': normalizedEmail,
        'displayName': displayName.trim(),
        'requestedClinicId': normalizedClinicId,
        'requestedClinicName': clinicName.trim(),
        'contactNumber': contactNumber.trim(),
        'status': AdminAccessRequestStatus.pending.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'rejectionReason': null,
      });

      return AdminAccessRequestModel(
        id: ref.id,
        uid: uid,
        email: normalizedEmail,
        displayName: displayName.trim(),
        requestedClinicId: normalizedClinicId,
        requestedClinicName: clinicName.trim(),
        contactNumber: contactNumber.trim(),
        status: AdminAccessRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ServerFailure(
          'Your access request could not be saved. Please try again. If the '
          'problem continues, sign out and sign in again.',
        );
      }
      if (e.code == 'unavailable') {
        throw const ConnectionFailure(
          'Network unavailable. Check your connection and try again.',
        );
      }
      throw ServerFailure(e.message ?? 'Failed to submit the access request');
    }
  }
}
