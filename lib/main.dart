import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with real configuration options.
  // If Firebase is not available (e.g. in tests), the app still boots in
  // UI-only mode. Authentication and authorization are never simulated: the
  // affected screens fail closed and show a real error instead.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    // Firebase not available — UI-only mode continues.
  }

  if (firebaseReady) {
    // App Check protects the backend from requests made outside the real app.
    // Debug builds use the debug provider; release builds use Play Integrity.
    // Enforcement is enabled from the Firebase Console only after the debug
    // token and Play signing certificate are registered.
    if (!kIsWeb) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleDeviceCheckProvider(),
        );
      } catch (_) {
        // App Check is a hardening layer; never block app startup on it.
      }
    }

    try {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(true);
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
        return true;
      };
    } catch (_) {
      // Crash reporting must never prevent the app from starting.
    }
  }

  runZonedGuarded<Future<void>>(() async {
    runApp(const EasyCheckApp());
  }, (Object error, StackTrace stackTrace) {
    if (firebaseReady) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: true,
      );
    } else {
      debugPrint('Uncaught error: $error');
    }
  });
}
