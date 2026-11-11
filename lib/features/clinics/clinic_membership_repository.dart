import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easycheck_online/features/clinics/clinic_membership_model.dart';
import 'package:easycheck_online/core/errors/app_failure.dart';

class ClinicMembershipRepository {
  FirebaseFirestore? _firestore;

  FirebaseFirestore? get _fs {
    if (_firestore == null) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (_) {
        // Firebase not initialized (UI-only mode / tests).
        return null;
      }
    }
    return _firestore;
  }

  CollectionReference<Map<String, dynamic>>? _membershipsCollection() {
    final fs = _fs;
    if (fs == null) return null;
    return fs.collection('clinic_members');
  }

  String _documentId(String userId, String clinicId) => '${userId}_$clinicId';

  Future<ClinicMembershipModel?> getMembership(
    String userId,
    String clinicId,
  ) async {
    try {
      final col = _membershipsCollection();
      if (col == null) return null;
      final doc = await col.doc(_documentId(userId, clinicId)).get();
      if (!doc.exists) return null;
      return ClinicMembershipModel.fromDocument(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to get membership');
    }
  }

  Future<void> createMembership(ClinicMembershipModel membership) async {
    try {
      final col = _membershipsCollection();
      if (col == null) return;
      await col
          .doc(_documentId(membership.userId, membership.clinicId))
          .set(membership.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to create membership');
    }
  }

  Future<void> updateMembership(
    String userId,
    String clinicId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final col = _membershipsCollection();
      if (col == null) return;
      await col.doc(_documentId(userId, clinicId)).update(updates);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to update membership');
    }
  }

  Future<List<ClinicMembershipModel>> getUserMemberships(String userId) async {
    try {
      final col = _membershipsCollection();
      if (col == null) return const [];
      final snapshot = await col
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => ClinicMembershipModel.fromDocument(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to get user memberships');
    }
  }

  Future<List<ClinicMembershipModel>> getClinicMembers(String clinicId) async {
    try {
      final col = _membershipsCollection();
      if (col == null) return const [];
      final snapshot = await col
          .where('clinicId', isEqualTo: clinicId)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => ClinicMembershipModel.fromDocument(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to get clinic members');
    }
  }

  Future<bool> hasPermission(
    String userId,
    String clinicId,
    String permission,
  ) async {
    try {
      final membership = await getMembership(userId, clinicId);
      if (membership == null) return false;
      return membership.hasPermission(permission);
    } on ServerFailure {
      return false;
    }
  }

  Future<void> deactivateMembership(String userId, String clinicId) async {
    try {
      final col = _membershipsCollection();
      if (col == null) return;
      await col.doc(_documentId(userId, clinicId)).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to deactivate membership');
    }
  }
}
