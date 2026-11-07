import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model for EasyCheck Online.
/// Document ID in Firestore is the Firebase Auth UID.
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String role; // 'patient' or 'clinic_admin'
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  /// Create from Firestore document snapshot.
  factory UserProfile.fromDocument(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: data['role'] as String? ?? 'patient',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, role: $role, isActive: $isActive)';
  }
}
