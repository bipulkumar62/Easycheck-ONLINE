import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easycheck_online/features/clinics/clinic_model.dart';
import 'package:easycheck_online/shared/models/clinic_model.dart' as display;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 5, 9);

  test('clinic document keeps the manually entered doctor timing', () {
    final clinic = ClinicModel.fromDocument({
      'name': 'Al-Shifa Family Health Clinic',
      'address': 'Suite 402, Medical City Blvd',
      'city': 'Lahore',
      'region': 'Punjab',
      'phone': '+92 42 111 222 333',
      'email': 'clinic@example.com',
      'isActive': true,
      'isOnline': true,
      'doctorName': 'Dr. Rajesh Kumar',
      'doctorCredentials': 'MD',
      'doctorSpecialty': 'Cardiologist',
      'doctorStatus': 'available',
      'doctorTiming': 'Mon-Sat, 9:00 AM - 5:00 PM',
      'todayParchiCount': 42,
      'yesterdayParchiCount': 38,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, 'CLN-84920');

    expect(clinic.doctorTiming, 'Mon-Sat, 9:00 AM - 5:00 PM');
    expect(clinic.toMap()['doctorTiming'], 'Mon-Sat, 9:00 AM - 5:00 PM');
    expect(
      clinic.copyWith(doctorTiming: 'Mon-Fri, 10:00 AM - 6:00 PM').doctorTiming,
      'Mon-Fri, 10:00 AM - 6:00 PM',
    );
  });

  test('missing doctor timing is tolerated for older documents', () {
    final clinic = ClinicModel.fromDocument({
      'name': 'Legacy Clinic',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, 'CLN-99999');

    expect(clinic.doctorTiming, isEmpty);
    expect(clinic.toDisplayModel().doctor.timing, isEmpty);
  });

  test('display model receives timing and status for the patient UI', () {
    final clinic = ClinicModel(
      clinicId: 'CLN-84920',
      name: 'Al-Shifa Family Health Clinic',
      address: 'Suite 402, Medical City Blvd',
      city: 'Lahore',
      region: 'Punjab',
      phone: '',
      email: '',
      isActive: true,
      isOnline: true,
      doctorName: 'Dr. Rajesh Kumar',
      doctorCredentials: 'MD',
      doctorSpecialty: 'Cardiologist',
      doctorStatus: 'delayed',
      doctorTiming: 'Mon-Sat, 9:00 AM - 5:00 PM',
      todayParchiCount: 42,
      yesterdayParchiCount: 38,
      createdAt: now,
      updatedAt: now,
    );

    final displayModel = clinic.toDisplayModel(liveParchiCount: 45);
    expect(displayModel.doctor.timing, 'Mon-Sat, 9:00 AM - 5:00 PM');
    expect(displayModel.doctor.status, display.DoctorStatus.delayed);
    expect(displayModel.status, display.ClinicStatus.delayed);
    expect(displayModel.todayParchiCount, 45);
  });
}
