import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easycheck_online/features/clinics/clinic_model.dart';

/// Lifecycle of a clinic-admin access request.
///
/// Only the Super Admin dashboard (trusted backend / Admin SDK) may move a
/// request out of [pending]. The applicant client can only create a pending
/// request and read its own status.
enum AdminAccessRequestStatus {
  pending,
  approved,
  rejected;

  String get value => name;

  static AdminAccessRequestStatus fromValue(String? value) {
    switch (value) {
      case 'approved':
        return AdminAccessRequestStatus.approved;
      case 'rejected':
        return AdminAccessRequestStatus.rejected;
      case 'pending':
      default:
        return AdminAccessRequestStatus.pending;
    }
  }
}

/// A doctor/staff request to be linked to a clinic.
///
/// Firestore collection: `admin_access_requests`
/// Document ID: `{uid}_{requestedClinicId}` so one request per user/clinic
/// pair can exist. The deterministic ID is also the duplicate guard.
class AdminAccessRequestModel {
  final String id;
  final String uid;
  final String email;
  final String displayName;
  final String requestedClinicId;
  final String contactNumber;
  final AdminAccessRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const AdminAccessRequestModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.displayName,
    required this.requestedClinicId,
    this.contactNumber = '',
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  factory AdminAccessRequestModel.fromDocument(
    Map<String, dynamic> data,
    String id,
  ) {
    return AdminAccessRequestModel(
      id: id,
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      requestedClinicId: data['requestedClinicId'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      status: AdminAccessRequestStatus.fromValue(data['status'] as String?),
      createdAt: _toDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(data['updatedAt']) ?? DateTime.now(),
      reviewedAt: _toDate(data['reviewedAt']),
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Serializes the model using client timestamps. Server writes use
  /// `FieldValue.serverTimestamp()` instead; this is mainly for tests and
  /// trusted tooling.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'requestedClinicId': requestedClinicId,
      'contactNumber': contactNumber,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  AdminAccessRequestModel copyWith({
    String? email,
    String? displayName,
    String? requestedClinicId,
    String? contactNumber,
    AdminAccessRequestStatus? status,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return AdminAccessRequestModel(
      id: id,
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      requestedClinicId: requestedClinicId ?? this.requestedClinicId,
      contactNumber: contactNumber ?? this.contactNumber,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  String toString() {
    return 'AdminAccessRequestModel(id: $id, clinic: $requestedClinicId, '
        'status: ${status.value})';
  }
}

/// Navigation payload shared by the request-submitted, pending and rejected
/// screens. Keeping the clinic alongside the request avoids an extra read on
/// every transition while the clinic is already known.
class AdminAccessFlowArgs {
  final AdminAccessRequestModel request;
  final ClinicModel? clinic;

  const AdminAccessFlowArgs({
    required this.request,
    this.clinic,
  });
}
