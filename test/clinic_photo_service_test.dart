import 'dart:convert';
import 'dart:typed_data';

import 'package:easycheck_online/core/errors/app_failure.dart';
import 'package:easycheck_online/features/clinics/clinic_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final endpoint = Uri.parse('https://example.test/functions/v1/clinic-photo');
  final jpegBytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0x01, 0x02]);

  ClinicPhotoService serviceWith(
    Future<http.Response> Function(http.Request request) handler, {
    Future<String?> Function()? token,
  }) {
    return ClinicPhotoService(
      client: MockClient(handler),
      endpoint: endpoint,
      idTokenProvider: token ?? () async => 'firebase-id-token',
    );
  }

  group('ClinicPhotoService', () {
    test('sends the Firebase token and clinic id, then returns the URL',
        () async {
      late http.Request captured;
      final service = serviceWith((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'url': 'https://cdn.test/doctor.jpg?v=1'}),
          200,
        );
      });

      final url = await service.uploadDoctorPhoto(
        clinicId: 'CLN-84920',
        bytes: jpegBytes,
        fileName: 'doctor.jpg',
      );

      expect(url, 'https://cdn.test/doctor.jpg?v=1');
      expect(captured.url, endpoint);
      expect(captured.headers['Authorization'], 'Bearer firebase-id-token');
      expect(captured.body, contains('CLN-84920'));
      expect(captured.body, contains('doctor.jpg'));
    });

    test('rejects an empty photo without calling the network', () async {
      var called = false;
      final service = serviceWith((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      await expectLater(
        service.uploadDoctorPhoto(
          clinicId: 'CLN-84920',
          bytes: Uint8List(0),
          fileName: 'empty.jpg',
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(called, isFalse);
    });

    test('rejects a photo above the 5 MB limit without calling the network',
        () async {
      var called = false;
      final service = serviceWith((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      await expectLater(
        service.uploadDoctorPhoto(
          clinicId: 'CLN-84920',
          bytes: Uint8List(ClinicPhotoService.maxBytes + 1),
          fileName: 'huge.jpg',
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(called, isFalse);
    });

    test('requires a signed-in Firebase session', () async {
      var called = false;
      final service = serviceWith(
        (request) async {
          called = true;
          return http.Response('{}', 200);
        },
        token: () async => null,
      );

      await expectLater(
        service.uploadDoctorPhoto(
          clinicId: 'CLN-84920',
          bytes: jpegBytes,
          fileName: 'doctor.jpg',
        ),
        throwsA(isA<UnauthorizedFailure>()),
      );
      expect(called, isFalse);
    });

    test('maps server status codes to user-facing failures', () async {
      final expected = <int, Type>{
        401: UnauthorizedFailure,
        403: UnauthorizedFailure,
        413: ValidationFailure,
        415: ValidationFailure,
        500: ServerFailure,
      };

      for (final entry in expected.entries) {
        final service = serviceWith(
          (request) async => http.Response('{"error":"internal"}', entry.key),
        );

        await expectLater(
          service.uploadDoctorPhoto(
            clinicId: 'CLN-84920',
            bytes: jpegBytes,
            fileName: 'doctor.jpg',
          ),
          throwsA(isA<AppFailure>()),
          reason: 'status ${entry.key}',
        );

        try {
          await service.uploadDoctorPhoto(
            clinicId: 'CLN-84920',
            bytes: jpegBytes,
            fileName: 'doctor.jpg',
          );
        } on AppFailure catch (failure) {
          expect(
            failure.runtimeType,
            entry.value,
            reason: 'status ${entry.key}',
          );
          expect(failure.message, isNot(contains('internal')));
        }
      }
    });

    test('turns a network failure into a connection failure', () async {
      final service = serviceWith(
        (request) async => throw http.ClientException('socket closed'),
      );

      await expectLater(
        service.uploadDoctorPhoto(
          clinicId: 'CLN-84920',
          bytes: jpegBytes,
          fileName: 'doctor.jpg',
        ),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('rejects a success response without a usable URL', () async {
      final service = serviceWith(
        (request) async => http.Response(jsonEncode({'url': 'not-a-url'}), 200),
      );

      await expectLater(
        service.uploadDoctorPhoto(
          clinicId: 'CLN-84920',
          bytes: jpegBytes,
          fileName: 'doctor.jpg',
        ),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
