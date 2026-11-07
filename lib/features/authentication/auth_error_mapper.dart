import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/app_failure.dart';

/// Converts Firebase Auth failures into user-facing, non-technical messages.
///
/// Cancellation is deliberately distinct from a denied authorization: closing
/// the Google popup is not an access failure and must not be presented as one.
class AuthErrorMapper {
  AuthErrorMapper._();

  static bool isCancellation(Object error) {
    if (error is GoogleSignInException) {
      return error.code == GoogleSignInExceptionCode.canceled;
    }
    if (error is! FirebaseAuthException) return false;
    return const {
      'popup-closed-by-user',
      'cancelled',
      'web-context-cancelled',
      'user-cancelled',
      'sign_in_cancelled',
    }.contains(error.code);
  }

  static String message(Object error) {
    if (error is AppFailure) return error.message;

    if (error is GoogleSignInException) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          return 'Sign-in cancelled. You can try again whenever you are ready.';
        case GoogleSignInExceptionCode.interrupted:
          return 'Google sign-in was interrupted. Please try again.';
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'Google sign-in is not available on this build. Please '
              'update the app or contact support.';
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'Google sign-in could not open on this device. Please try '
              'again.';
        case GoogleSignInExceptionCode.userMismatch:
          return 'A different Google account is already signed in. Sign out '
              'and try again.';
        case GoogleSignInExceptionCode.unknownError:
          return 'Google sign-in failed. Please try again.';
      }
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'popup-closed-by-user':
        case 'cancelled':
        case 'web-context-cancelled':
        case 'user-cancelled':
        case 'sign_in_cancelled':
          return 'Sign-in cancelled. You can try again whenever you are ready.';
        case 'network-request-failed':
        case 'unavailable':
          return 'Network error. Check your internet connection and try again.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different '
              'sign-in method. Use the original method or contact support.';
        case 'operation-not-allowed':
          return 'Google sign-in is not enabled for this app. Contact support.';
        case 'unauthorized-domain':
          return 'This website is not authorized for Google sign-in. '
              'Contact support.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'invalid-credential':
        case 'wrong-password':
          return 'The sign-in credentials could not be verified. Try again.';
        default:
          return 'Google sign-in failed. Please try again.';
      }
    }

    return 'Something went wrong while signing in. Please try again.';
  }
}
