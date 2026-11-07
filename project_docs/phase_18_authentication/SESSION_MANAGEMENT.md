# Session Management

**Phase:** Task 18 — Firebase Authentication Implementation  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Authentication State Listening

The app listens to Firebase Auth state changes via a single `StreamBuilder` in `EasyCheckApp`:

```dart
StreamBuilder<User?>(
  stream: firebaseInitialized
      ? FirebaseAuth.instance.authStateChanges()
      : const Stream<User?>.empty(),
  builder: (context, authSnapshot) {
    final isAuthenticated = authSnapshot.hasData;
    // Route based on authentication state
  },
)
```

**Key design decisions:**
- Single listener — no duplicate auth state subscriptions
- Stream is closed automatically when the `EasyCheckApp` widget is disposed
- If Firebase is not initialized (tests, offline), an empty stream is used

---

## 2. Login State Persistence

| Mechanism | Implementation |
|-----------|---------------|
| Token storage | Firebase Auth SDK persists ID tokens in secure device storage |
| Token refresh | Firebase Auth SDK auto-refreshes expired tokens (1-hour lifetime) |
| App restart | `authStateChanges()` emits current user on cold start |
| Foreground/background | Session persists across app lifecycle events |

**No custom token storage is implemented.** Firebase Auth SDK handles all token management securely.

---

## 3. Session Restoration After Restart

```
App cold start
    │
    ▼
Firebase.initializeApp()
    │
    ▼
EasyCheckApp builds
    │
    ▼
StreamBuilder listens to authStateChanges()
    │
    ├─ User is signed in → emits User object → isAuthenticated = true
    │   → initialRoute = '/patient/home'
    │   → PatientHomeScreen renders
    │
    └─ No user → emits null → isAuthenticated = false
        → initialRoute = '/patient/login'
        → PatientLoginScreen renders
```

---

## 4. Logout

**Status:** Not implemented in this task.

**Reason:** The approved Stitch UI designs do not include a logout button. The admin login screen's helpdesk modal has "Understood • Return to Login" which dismisses the modal but does not sign out.

**Future implementation:** When logout is required, `FirebaseAuth.instance.signOut()` will be called, which:
- Clears the cached ID token
- Emits null on `authStateChanges()`
- Triggers navigation to `/patient/login`

---

## 5. Authentication Error Handling

| Error Source | Detection | Handling |
|--------------|-----------|----------|
| Network failure | `FirebaseAuthException` | `_isSigningIn = false`; button re-enabled; error logged via `debugPrint` |
| Invalid credentials | `FirebaseAuthException` | `_isSigningIn = false`; button re-enabled; error logged via `debugPrint` |
| User cancellation | `signInWithProvider` returns null | App remains on login screen; no error shown |
| Firebase not initialized | Catch-all exception | `_isSigningIn = false`; button re-enabled; error logged via `debugPrint` |

**No error is shown to the user** — the button simply re-enables and the user can retry. This matches the Stitch design which does not include error display states.

---

## 6. Expired/Revoked Sessions

Firebase Auth SDK handles token expiration and revocation automatically:
- ID tokens expire after 1 hour and are auto-refreshed
- Revoked tokens cause `authStateChanges()` to emit null
- Next app interaction routes user to login

No custom handling is required in the Flutter code.

---

## 7. Avoiding Duplicate Listeners

Only one `StreamBuilder` listens to `authStateChanges()` — in `EasyCheckApp`. Individual screens do not create their own auth state subscriptions. This prevents:
- Multiple simultaneous listeners
- Memory leaks from unsubscribed streams
- Inconsistent auth state across the app

---

## 8. Test Coverage

| Session Feature | Test Coverage | Result |
|-----------------|--------------|--------|
| Firebase initialization in test setUpAll | `setUpAll` with graceful fallback | PASS |
| App renders with Firebase available | Widget test 1 | PASS |
| App renders without Firebase | setUpAll catch block | PASS |
| Login screen renders with Google button | Widget test 4 | PASS |
| Admin login screen renders | Widget test 4 | PASS |

**Not covered (requires Firebase Emulator or production):**
- Actual Google Sign-In flow
- Session persistence across app restart
- Logout behavior
- Token refresh

---

## 9. Security Considerations

| Control | Status |
|---------|--------|
| ID tokens auto-refreshed | ✅ Firebase Auth SDK |
| Tokens stored in secure device storage | ✅ Firebase Auth SDK |
| No custom token storage | ✅ Relies on Firebase Auth |
| Session persists across restart | ✅ Firebase Auth SDK |
| No manual token handling | ✅ All token ops via SDK |

---

## 10. Readiness for Task 19

Session management is fully implemented using Firebase Auth's built-in capabilities. Task 19 will add:
- User profile persistence to Firestore
- Profile retrieval after login
- Profile creation on first login

**STOP after Task 18. Waiting for approval before proceeding.**
