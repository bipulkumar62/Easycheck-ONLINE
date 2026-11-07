import 'package:cloud_firestore/cloud_firestore.dart';

/// Clinic membership model linking a user to a clinic with a specific role.
/// Document ID is composite: {userId}_{clinicId}
class ClinicMembershipModel {
  final String userId;
  final String clinicId;
  final String role; // 'front_desk_lead', 'triage_coordinator', 'clinic_admin'
  final List<String> permissions;
  final bool isActive;
  final DateTime joinedAt;
  final String? assignedBy;

  const ClinicMembershipModel({
    required this.userId,
    required this.clinicId,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.joinedAt,
    this.assignedBy,
  });

  /// Valid clinic membership roles.
  static const List<String> validRoles = [
    'clinic_admin',
    'front_desk_lead',
    'triage_coordinator',
  ];

  /// Valid permissions that can be assigned.
  static const List<String> validPermissions = [
    'update_tally',
    'update_status',
    'reset_tally',
    'manage_staff',
    'view_queue',
  ];

  /// Create from Firestore document snapshot.
  factory ClinicMembershipModel.fromDocument(Map<String, dynamic> data, String documentId) {
    final parts = documentId.split('_');
    return ClinicMembershipModel(
      userId: parts.first,
      clinicId: parts.skip(1).join('_'),
      role: data['role'] as String? ?? '',
      permissions: List<String>.from(data['permissions'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedBy: data['assignedBy'] as String?,
    );
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clinicId': clinicId,
      'role': role,
      'permissions': permissions,
      'isActive': isActive,
      'joinedAt': joinedAt,
      'assignedBy': assignedBy,
    };
  }

  /// Check if the membership has a specific permission.
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  ClinicMembershipModel copyWith({
    String? role,
    List<String>? permissions,
    bool? isActive,
    String? assignedBy,
  }) {
    return ClinicMembershipModel(
      userId: userId,
      clinicId: clinicId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt,
      assignedBy: assignedBy ?? this.assignedBy,
    );
  }

  @override
  String toString() {
    return 'ClinicMembershipModel(userId: $userId, clinicId: $clinicId, role: $role, isActive: $isActive)';
  }
}
