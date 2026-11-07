import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default Firebase options for EasyCheck Online.
///
/// These values are public Firebase project configuration values (not secrets).
/// The correct options are selected at runtime so the same codebase builds for
/// Android and Flutter web without importing `dart:io`.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        // Only Android and web apps are registered for this project. Other
        // platforms still boot; initialization failures are handled gracefully
        // by main.dart (UI-only mode).
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA5vDJWRjTRmfMqAYzy1QkHq6_u4WMagiY',
    appId: '1:1085858861836:web:51aa34e12dd044c161ef29',
    messagingSenderId: '1085858861836',
    projectId: 'easycheck-online',
    authDomain: 'easycheck-online.firebaseapp.com',
    storageBucket: 'easycheck-online.firebasestorage.app',
    measurementId: 'G-YXNLR45RD4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDdsNd9BbNjnyVS0p-m-5hMnRf0GYcqGx8',
    appId: '1:1085858861836:android:f6c366f51fe48bac61ef29',
    messagingSenderId: '1085858861836',
    projectId: 'easycheck-online',
    storageBucket: 'easycheck-online.firebasestorage.app',
  );
}
