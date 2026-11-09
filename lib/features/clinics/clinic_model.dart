import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easycheck_online/shared/models/clinic_model.dart' as display;

/// Clinic model for EasyCheck Online.
/// Document ID in Firestore is the unique clinic ID (e.g., CLN-84920).
class ClinicModel {
  final String clinicId;
  final String name;
  final String address;
  final String city;
  final String region;
  final String phone;
  final String email;
  final String? description;
  final bool isActive;
  final bool isOnline;

  // Doctor / live-display fields. Optional so older documents keep working.
  final String doctorName;
  final String doctorCredentials;
  final String doctorSpecialty;
  final String doctorPhotoUrl;

  /// Wide cover image shown on the patient home card. Falls back to the doctor
  /// photo when a clinic has not uploaded a dedicated cover yet.
  final String clinicPhotoUrl;

  final String doctorStatus; // available | delayed | offDuty
  final String
  doctorTiming; // manually entered OPD hours, e.g. 9:00 AM – 5:00 PM
  final int todayParchiCount;
  final int yesterdayParchiCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ClinicModel({
    required this.clinicId,
    required this.name,
    required this.address,
    required this.city,
    required this.region,
    required this.phone,
    required this.email,
    this.description,
    required this.isActive,
    required this.isOnline,
    this.doctorName = '',
    this.doctorCredentials = '',
    this.doctorSpecialty = '',
    this.doctorPhotoUrl = '',
    this.clinicPhotoUrl = '',
    this.doctorStatus = 'available',
    this.doctorTiming = '',
    this.todayParchiCount = 0,
    this.yesterdayParchiCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The best available image for the patient-facing clinic card.
  String get coverPhotoUrl =>
      clinicPhotoUrl.isNotEmpty ? clinicPhotoUrl : doctorPhotoUrl;

  /// Create from Firestore document snapshot.
  factory ClinicModel.fromDocument(Map<String, dynamic> data, String clinicId) {
    return ClinicModel(
      clinicId: clinicId,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      region: data['region'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      description: data['description'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      isOnline: data['isOnline'] as bool? ?? false,
      doctorName: data['doctorName'] as String? ?? '',
      doctorCredentials: data['doctorCredentials'] as String? ?? '',
      doctorSpecialty: data['doctorSpecialty'] as String? ?? '',
      doctorPhotoUrl: data['doctorPhotoUrl'] as String? ?? '',
      clinicPhotoUrl: data['clinicPhotoUrl'] as String? ?? '',
      doctorStatus: data['doctorStatus'] as String? ?? 'available',
      doctorTiming: data['doctorTiming'] as String? ?? '',
      todayParchiCount: (data['todayParchiCount'] as num?)?.toInt() ?? 0,
      yesterdayParchiCount:
          (data['yesterdayParchiCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'region': region,
      'phone': phone,
      'email': email,
      'description': description,
      'isActive': isActive,
      'isOnline': isOnline,
      'doctorName': doctorName,
      'doctorCredentials': doctorCredentials,
      'doctorSpecialty': doctorSpecialty,
      'doctorPhotoUrl': doctorPhotoUrl,
      'clinicPhotoUrl': clinicPhotoUrl,
      'doctorStatus': doctorStatus,
      'doctorTiming': doctorTiming,
      'todayParchiCount': todayParchiCount,
      'yesterdayParchiCount': yesterdayParchiCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ClinicModel copyWith({
    String? name,
    String? address,
    String? city,
    String? region,
    String? phone,
    String? email,
    String? description,
    bool? isActive,
    bool? isOnline,
    String? doctorName,
    String? doctorCredentials,
    String? doctorSpecialty,
    String? doctorPhotoUrl,
    String? clinicPhotoUrl,
    String? doctorStatus,
    String? doctorTiming,
    int? todayParchiCount,
    int? yesterdayParchiCount,
    DateTime? updatedAt,
  }) {
    return ClinicModel(
      clinicId: clinicId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      doctorName: doctorName ?? this.doctorName,
      doctorCredentials: doctorCredentials ?? this.doctorCredentials,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
      clinicPhotoUrl: clinicPhotoUrl ?? this.clinicPhotoUrl,
      doctorStatus: doctorStatus ?? this.doctorStatus,
      doctorTiming: doctorTiming ?? this.doctorTiming,
      todayParchiCount: todayParchiCount ?? this.todayParchiCount,
      yesterdayParchiCount: yesterdayParchiCount ?? this.yesterdayParchiCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Adapt this Firestore record to the presentation model used by the
  /// Stitch-derived clinic details screen.
  display.ClinicModel toDisplayModel({int? liveParchiCount}) {
    final status = !isActive
        ? display.ClinicStatus.unavailable
        : switch (doctorStatus) {
            'delayed' => display.ClinicStatus.delayed,
            'offDuty' => display.ClinicStatus.unavailable,
            _ =>
              isOnline
                  ? display.ClinicStatus.available
                  : display.ClinicStatus.unavailable,
          };

    return display.ClinicModel(
      id: clinicId,
      name: name,
      address: address,
      isActive: isActive,
      doctor: display.DoctorModel(
        id: '${clinicId}_doctor',
        name: doctorName,
        credentials: doctorCredentials,
        specialty: doctorSpecialty,
        photoAssetPath: doctorPhotoUrl.isEmpty ? null : doctorPhotoUrl,
        timing: doctorTiming,
        status: switch (doctorStatus) {
          'delayed' => display.DoctorStatus.delayed,
          'offDuty' => display.DoctorStatus.offDuty,
          _ => display.DoctorStatus.available,
        },
      ),
      status: status,
      todayParchiCount: liveParchiCount ?? todayParchiCount,
      yesterdayParchiCount: yesterdayParchiCount,
    );
  }

  @override
  String toString() {
    return 'ClinicModel(clinicId: $clinicId, name: $name, isActive: $isActive, isOnline: $isOnline)';
  }
}
