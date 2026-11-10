import 'package:shared_preferences/shared_preferences.dart';

import 'auth_gate_screen.dart';

/// Remembers which experience the user last opened and lets the app resume an
/// existing Firebase session without showing the Google account picker again.
///
/// The stored role is only a UX hint. [AuthGateScreen] still verifies the
/// Firebase UID against Firestore before any protected screen opens.
class AuthSessionStore {
  AuthSessionStore._();

  static const String _storageKey = 'easycheck_last_role';
  static bool _autoResumeAttempted = false;

  /// True once the entry screen has already tried to resume this launch. This
  /// prevents a loop when an expired or unauthorised session returns the user
  /// to role selection from the verification screen.
  static bool get autoResumeAttempted => _autoResumeAttempted;

  static void markAutoResumeAttempted() {
    _autoResumeAttempted = true;
  }

  static void resetAutoResume() {
    _autoResumeAttempted = false;
  }

  static Future<void> saveRole(AuthRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        role == AuthRole.admin ? 'admin' : 'patient',
      );
    } catch (_) {
      // The current session still works when preferences are unavailable.
    }
  }

  static Future<AuthRole?> loadRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return switch (prefs.getString(_storageKey)) {
        'admin' => AuthRole.admin,
        'patient' => AuthRole.patient,
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}
