import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import '../../core/errors/app_failure.dart';

/// Uploads the patient-facing doctor photo through the Supabase Edge Function.
///
/// The app sends the Firebase ID token, the clinic ID and the image bytes. The
/// function verifies the token, confirms an active `clinic_admin` membership in
/// Firestore, validates the real image format, and writes the file with a
/// service-role key that never leaves the server. Only the resulting public URL
/// is stored in Firestore (`clinics/{clinicId}.doctorPhotoUrl`).
class ClinicPhotoService {
  ClinicPhotoService({
    http.Client? client,
    Uri? endpoint,
    Future<String?> Function()? idTokenProvider,
  }) : _client = client ?? http.Client(),
       _endpoint = endpoint ?? SupabaseConfig.clinicPhotoEndpoint,
       _idTokenProvider = idTokenProvider ?? _firebaseIdToken;

  final http.Client _client;
  final Uri _endpoint;
  final Future<String?> Function() _idTokenProvider;

  static const int maxBytes = 5 * 1024 * 1024;
  static const Duration _timeout = Duration(seconds: 60);

  static Future<String?> _firebaseIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Future<String> uploadDoctorPhoto({
    required String clinicId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw const ValidationFailure('The selected photo is empty.');
    }
    if (bytes.length > maxBytes) {
      throw const ValidationFailure(
        'The photo is larger than 5 MB. Choose a smaller image.',
      );
    }

    final token = await _idTokenProvider();
    if (token == null || token.isEmpty) {
      throw const UnauthorizedFailure(
        'Your sign-in session has expired. Please sign in again.',
      );
    }

    final request = http.MultipartRequest('POST', _endpoint)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['clinicId'] = clinicId
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw const ConnectionFailure(
        'Could not reach the photo service. Check your connection and try '
        'again.',
      );
    }

    if (response.statusCode == 200) {
      final url = _readUrl(response.body);
      if (url != null) return url;
      throw const ServerFailure(
        'The photo service returned an invalid response. Please try again.',
      );
    }

    switch (response.statusCode) {
      case 401:
        throw const UnauthorizedFailure(
          'Your sign-in session has expired. Please sign in again.',
        );
      case 403:
        throw const UnauthorizedFailure(
          'Only an active clinic admin can change this photo.',
        );
      case 413:
        throw const ValidationFailure(
          'The photo is larger than 5 MB. Choose a smaller image.',
        );
      case 415:
        throw const ValidationFailure(
          'Use a JPEG, PNG or WebP image.',
        );
      default:
        throw const ServerFailure(
          'The photo could not be uploaded. Please try again.',
        );
    }
  }

  String? _readUrl(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final url = decoded['url'];
      if (url is String && url.startsWith('https://')) return url;
    } catch (_) {
      return null;
    }
    return null;
  }
}
