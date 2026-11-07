// Data models for EasyCheck Online — derived from Stitch prototype data.

enum DoctorStatus { available, delayed, offDuty }

enum ClinicStatus { available, delayed, unavailable, closed }

class DoctorModel {
  final String id;
  final String name;
  final String credentials;
  final String specialty;
  final String? photoAssetPath;
  final DoctorStatus status;
  final String timing;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.credentials,
    required this.specialty,
    this.photoAssetPath,
    required this.status,
    this.timing = '',
  });

  String get fullName =>
      credentials.trim().isEmpty ? name : '$name, $credentials';
}

class ClinicModel {
  final String id;
  final String name;
  final String address;
  final DoctorModel doctor;
  final ClinicStatus status;
  final int todayParchiCount;
  final int? yesterdayParchiCount;

  /// Whether the network administrator has enabled this clinic. A disabled
  /// clinic stays visible to patients as offline, but its queue is paused.
  final bool isActive;

  const ClinicModel({
    required this.id,
    required this.name,
    required this.address,
    required this.doctor,
    required this.status,
    required this.todayParchiCount,
    this.yesterdayParchiCount,
    this.isActive = true,
  });
}

class AdminUserModel {
  final String displayName;
  final String email;
  final String role;
  final String clinicId;
  final String clinicName;
  final String? photoAssetPath;

  const AdminUserModel({
    required this.displayName,
    required this.email,
    required this.role,
    required this.clinicId,
    required this.clinicName,
    this.photoAssetPath,
  });
}
