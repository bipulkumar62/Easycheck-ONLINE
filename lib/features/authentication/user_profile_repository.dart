import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easycheck_online/core/errors/app_failure.dart';
import 'package:easycheck_online/features/authentication/user_profile_model.dart';

/// Repository for user profile operations in Firestore.
class UserProfileRepository {
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

  CollectionReference<Map<String, dynamic>>? _usersCollection() {
    final fs = _fs;
    if (fs == null) return null;
    return fs.collection('users');
  }

  /// Get a user profile by UID.
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final col = _usersCollection();
      if (col == null) return null;
      final doc = await col.doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromDocument(doc.data()!, uid);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to get user profile');
    }
  }

  /// Creates a patient profile only when one does not already exist.
  ///
  /// Existing profile data is never overwritten. The transaction makes the
  /// check-and-create atomic so two concurrent sign-ins cannot replace an
  /// established display name, photo, role or timestamps.
  Future<UserProfile> ensurePatientProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final fs = _fs;
    if (fs == null) {
      throw const ServerFailure('Firebase is not available on this device.');
    }

    final ref = fs.collection('users').doc(uid);
    try {
      return await fs.runTransaction<UserProfile>((transaction) async {
        final snapshot = await transaction.get(ref);
        if (snapshot.exists) {
          final profile = UserProfile.fromDocument(snapshot.data()!, uid);
          if (!profile.isActive) {
            throw const UnauthorizedFailure(
              'This account has been deactivated. Contact support.',
            );
          }
          return profile;
        }

        final now = DateTime.now();
        final profile = UserProfile(
          uid: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          role: 'patient',
          createdAt: now,
          updatedAt: now,
          isActive: true,
        );
        transaction.set(ref, profile.toMap());
        return profile;
      });
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to create user profile');
    }
  }

  /// Create a new user profile.
  Future<void> createProfile(UserProfile profile) async {
    try {
      final col = _usersCollection();
      if (col == null) return;
      await col.doc(profile.uid).set(profile.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to create user profile');
    }
  }

  /// Update specific fields of a user profile.
  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    try {
      final col = _usersCollection();
      if (col == null) return;
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await col.doc(uid).update(updates);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to update user profile');
    }
  }

  /// Permanently deletes the signed-in patient's profile document.
  ///
  /// Security rules allow this only for the profile owner and only when the
  /// stored role is `patient`. Clinic memberships are provisioned separately
  /// and are never removed by this call.
  Future<void> deleteProfile(String uid) async {
    final col = _usersCollection();
    if (col == null) {
      throw const ServerFailure('Firebase is not available on this device.');
    }
    try {
      await col.doc(uid).delete();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to delete user profile');
    }
  }

  /// Stream of user profile changes (real-time listener).
  Stream<UserProfile?> profileStream(String uid) {
    final col = _usersCollection();
    if (col == null) return Stream.value(null);
    return col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDocument(doc.data()!, uid);
    });
  }

  /// Check if a profile exists for the given UID.
  Future<bool> profileExists(String uid) async {
    try {
      final col = _usersCollection();
      if (col == null) return false;
      final doc = await col.doc(uid).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to check profile existence');
    }
  }
}
