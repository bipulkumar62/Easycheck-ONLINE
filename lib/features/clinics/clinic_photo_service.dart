import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../core/errors/app_failure.dart';

/// Uploads the patient-facing doctor photo for a clinic.
///
/// The file is stored under a stable per-clinic path so replacing the photo
/// does not leave orphaned objects behind. Only an active clinic administrator
/// may write this path; the storage rules enforce that on the server.
class ClinicPhotoService {
  Future<String> uploadDoctorPhoto({
    required String clinicId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('clinics')
          .child(clinicId)
          .child('doctor_photo');

      final snapshot = await ref.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          cacheControl: 'public,max-age=3600',
        ),
      );

      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw ServerFailure(
        error.message ?? 'Could not upload the doctor photo.',
      );
    }
  }
}
