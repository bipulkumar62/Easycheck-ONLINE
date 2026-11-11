import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easycheck_online/features/clinics/clinic_model.dart';
import 'package:easycheck_online/core/errors/app_failure.dart';

/// Repository for clinic operations in Firestore.
class ClinicRepository {
  FirebaseFirestore? _firestore;

  FirebaseFirestore? get _fs {
    if (_firestore == null) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (_) {
        // Firebase not initialized (e.g., in tests)
        return null;
      }
    }
    return _firestore;
  }

  CollectionReference<Map<String, dynamic>>? _clinicsCollection() {
    final fs = _fs;
    if (fs == null) return null;
    return fs.collection('clinics');
  }

  Future<ClinicModel?> getClinic(String clinicId) async {
    try {
      final col = _clinicsCollection();
      if (col == null) return null;
      final doc = await col.doc(clinicId).get();
      if (!doc.exists) return null;
      return ClinicModel.fromDocument(doc.data()!, clinicId);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to get clinic');
    }
  }

  Future<void> createClinic(ClinicModel clinic) async {
    try {
      final col = _clinicsCollection();
      if (col == null) return;
      await col.doc(clinic.clinicId).set(clinic.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to create clinic');
    }
  }

  Future<void> updateClinic(
    String clinicId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final col = _clinicsCollection();
      if (col == null) return;
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await col.doc(clinicId).update(updates);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to update clinic');
    }
  }

  Stream<ClinicModel?> clinicStream(String clinicId) {
    final col = _clinicsCollection();
    if (col == null) return Stream.value(null);
    return col.doc(clinicId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClinicModel.fromDocument(doc.data()!, clinicId);
    });
  }

  Stream<List<ClinicModel>> activeClinicsStream() {
    final col = _clinicsCollection();
    if (col == null) return Stream.value([]);
    return col.where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ClinicModel.fromDocument(doc.data(), doc.id))
          .toList();
    });
  }

  /// Every clinic the patient is allowed to discover, including clinics that
  /// the network administrator has disabled. Disabled clinics stay visible so
  /// patients see an honest offline state instead of a clinic disappearing.
  Stream<List<ClinicModel>> clinicsStream() {
    final col = _clinicsCollection();
    if (col == null) return Stream.value([]);
    return col.snapshots().map((snapshot) {
      final clinics = snapshot.docs
          .map((doc) => ClinicModel.fromDocument(doc.data(), doc.id))
          .toList();
      clinics.sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return clinics;
    });
  }

  Future<List<ClinicModel>> getAllClinics() async {
    try {
      final col = _clinicsCollection();
      if (col == null) return [];
      final snapshot = await col.get();
      return snapshot.docs
          .map((doc) => ClinicModel.fromDocument(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to get clinics');
    }
  }

  Future<bool> isClinicActive(String clinicId) async {
    try {
      final col = _clinicsCollection();
      if (col == null) return false;
      final doc = await col.doc(clinicId).get();
      if (!doc.exists) return false;
      return doc.data()?['isActive'] as bool? ?? false;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to check clinic status');
    }
  }

  Future<bool> isClinicOnline(String clinicId) async {
    try {
      final col = _clinicsCollection();
      if (col == null) return false;
      final doc = await col.doc(clinicId).get();
      if (!doc.exists) return false;
      return doc.data()?['isOnline'] as bool? ?? false;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to check clinic online status');
    }
  }
}
