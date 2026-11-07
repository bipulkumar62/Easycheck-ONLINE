import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/app_failure.dart';

/// Real Google sign-in for the patient and clinic-staff flows.
///
/// On Android this uses the native Google Identity flow (Credential Manager)
/// so the user sees the system account picker instead of a browser redirect.
/// On platforms without a native authenticate UI, it falls back to Firebase's
/// provider flow.
class GoogleAuthService {
  static Future<void>? _initialization;

  static Future<void> _ensureInitialized() async {
    final existing = _initialization;
    if (existing != null) {
      await existing;
      return;
    }

    final future = GoogleSignIn.instance.initialize();
    _initialization = future;
    try {
      await future;
    } catch (_) {
      // Allow a later retry if initialization failed (for example because the
      // device was offline or the Play Services cache was being updated).
      _initialization = null;
      rethrow;
    }
  }

  /// Signs in with Google and returns the Firebase user.
  ///
  /// An existing Firebase session is reused so a patient who returns to the app
  /// does not have to approve the same account again. Use [signOut] first when
  /// the user explicitly wants a different account.
  Future<User> signIn() async {
    if (Firebase.apps.isEmpty) {
      throw const ServerFailure(
        'Sign-in is not available on this device. Please install the latest '
        'version of the app and try again.',
      );
    }

    final auth = FirebaseAuth.instance;
    final existing = auth.currentUser;
    if (existing != null) return existing;

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      final result = await auth.signInWithProvider(GoogleAuthProvider());
      final user = result.user;
      if (user == null) {
        throw const UnauthorizedFailure(
          'Google sign-in did not return an account. Please try again.',
        );
      }
      return user;
    }

    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const UnauthorizedFailure(
        'Google did not return a valid sign-in token. Please try again.',
      );
    }

    final result = await auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    final user = result.user;
    if (user == null) {
      throw const UnauthorizedFailure(
        'Google sign-in did not return an account. Please try again.',
      );
    }
    return user;
  }

  /// Refreshes the Google credential for sensitive actions such as account
  /// deletion. Returns normally only when the signed-in Firebase user has a
  /// fresh authentication time.
  Future<void> reauthenticate() async {
    if (Firebase.apps.isEmpty) {
      throw const ServerFailure(
        'Sign-in is not available on this device. Please install the latest '
        'version of the app and try again.',
      );
    }

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      throw const UnauthorizedFailure(
        'Your sign-in session has expired. Please sign in again.',
      );
    }

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      await user.reauthenticateWithProvider(GoogleAuthProvider());
      return;
    }

    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const UnauthorizedFailure(
        'Google did not return a valid sign-in token. Please try again.',
      );
    }

    await user.reauthenticateWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  /// Clears both the Google session and the Firebase session.
  ///
  /// Safe to call even if Google Sign-In has not been initialized or Firebase is
  /// unavailable; failures are ignored so the caller can still return to the
  /// role-selection screen.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google Sign-In may not be initialized on this platform.
    }
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // UI-only/test mode: the caller still navigates away.
    }
  }
}
