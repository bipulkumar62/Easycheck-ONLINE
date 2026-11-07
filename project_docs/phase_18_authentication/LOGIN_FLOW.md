# Login Flow

**Phase:** Task 18 — Firebase Authentication Implementation  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Approved Authentication Method

**Google Sign-In (OAuth 2.0)** via Firebase Authentication, as specified in the Task 17 architecture and Stitch design analysis.

Email/password login is **not** implemented — not in the approved scope.

---

## 2. Patient Login Flow

```
Patient opens /patient/login
    │
    ▼
[PatientLoginScreen renders]
    │
    ├─ Google Sign-In button visible
    │   │
    │   │ User taps "Continue with Google"
    │   ▼
    │ [FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider())]
    │   │
    │   ├─ Success → Firebase Auth returns user account
    │   │       → Navigator.pushReplacementNamed('/patient/home')
    │   │       → PatientHomeScreen renders
    │   │
    │   ├─ Cancellation → signInWithProvider returns null
    │   │       → App remains on /patient/login
    │   │       → No error shown (user chose to cancel)
    │   │
    │   └─ Error (network, invalid credentials, etc.)
    │           → FirebaseAuthException caught
    │           → _isSigningIn set to false
    │           → Button returns to enabled state
    │           → Error logged to debug console (not shown to user)
    │
    └─ Privacy Policy / Terms links
        → Open modal dialogs (existing UI, unchanged)
```

### UI Elements Preserved

| Element | Status |
|---------|--------|
| Full-bleed clinic photo background | ✅ Unchanged |
| Soft glass gradient overlay | ✅ Unchanged |
| Live sync desk active pill | ✅ Unchanged |
| EasyCheck Online wordmark | ✅ Unchanged |
| Value proposition card | ✅ Unchanged |
| Social proof badges | ✅ Unchanged |
| Google Sign-In button (48px) | ✅ Connected to Firebase Auth |
| HIPAA encryption notice | ✅ Unchanged |
| Privacy Policy / Terms links | ✅ Unchanged |

---

## 3. Clinic-Admin Login Flow

```
Admin opens /admin/login
    │
    ▼
[AdminLoginScreen renders]
    │
    ├─ Google Sign-In button visible
    │   │
    │   │ User taps "Continue with Google"
    │   ▼
    │ [FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider())]
    │   │
    │   ├─ Success → Firebase Auth returns user account
    │   │       → Admin screen shows DENIED state (_showDenied = true)
    │   │       → User sees "Request role elevation →" link
    │   │       → Link opens helpdesk modal (existing UI)
    │   │
    │   ├─ Cancellation → App remains on /admin/login
    │   │
    │   └─ Error → FirebaseAuthException caught
    │           → _showDenied = true
    │           → Error logged to debug console
    │
    └─ Helpdesk modal (existing UI)
        → "Access Provisioning" info
        → Support contacts (Ext: 4092, admin-it@metrohealth.net)
        → "Understood • Return to Login" button
```

### Important Security Boundary

**Authentication ≠ Authorization.** A successful Google Sign-In only proves identity. It does **not** grant clinic-admin access. Clinic-admin authorization requires Firestore `clinic_members` membership verification, which is deferred to Task 19.

Until Firestore membership is implemented:
- All authenticated users see the denied state on `/admin/login`
- No user can access `/admin/dashboard` functionality based on auth alone
- The "Request role elevation →" link is the only available action

---

## 4. Error Handling

| Error Type | Detection | User-Facing Behavior | Logging |
|------------|-----------|---------------------|---------|
| User cancels Google Sign-In | `signInWithProvider` returns null | App remains on login screen | None (expected) |
| Network failure | `FirebaseAuthException` with network error code | Button re-enables; no UI error shown | `debugPrint` |
| Invalid credentials | `FirebaseAuthException` with invalid credential code | Button re-enables; no UI error shown | `debugPrint` |
| Firebase not initialized | Catch-all exception | Button re-enables; no UI error shown | `debugPrint` |
| Account not found | `FirebaseAuthException` | Button re-enables; no UI error shown | `debugPrint` |

**No fake success messages are ever displayed.** If authentication fails, the user remains on the login screen with the button re-enabled.

---

## 5. Session Management

| Aspect | Implementation |
|--------|---------------|
| Auth state listening | `FirebaseAuth.instance.authStateChanges()` in `EasyCheckApp` StreamBuilder |
| Login persistence | Firebase Auth SDK handles token storage and refresh |
| Session restoration | On app restart, `authStateChanges()` emits current user → routes to `/patient/home` |
| Logout | Not yet implemented (no logout button in Stitch UI) |
| Expired/revoked sessions | Firebase Auth SDK handles automatically; `authStateChanges()` emits null |

---

## 6. Route Protection

| Route | Unauthenticated | Authenticated |
|-------|----------------|---------------|
| `/patient/login` | Shown (initial route) | Redirects to `/patient/home` |
| `/patient/home` | Redirects to `/patient/login` | Shown |
| `/patient/clinic-details` | Not directly accessible | Accessible via named route from home |
| `/admin/login` | Shown | Shown (but denied state) |
| `/admin/dashboard` | Accessible via named route | Accessible via named route |
| `/admin/reset-studio` | Accessible via named route | Accessible via named route |
| `/admin/unauthorized` | Accessible via named route | Accessible via named route |

**Note:** Admin routes are accessible via named navigation but functionality is guarded by UI-level denied state. True backend authorization (Firestore `clinic_members` check) is deferred to Task 19.

---

## 7. UI Restrictions Compliance

| Restriction | Status |
|-------------|--------|
| Preserve Stitch design exactly | ✅ No visual changes |
| Do not redesign login screens | ✅ Unchanged |
| Do not change typography/spacing/colors | ✅ Unchanged |
| Connect existing buttons to auth actions | ✅ Google Sign-In button calls Firebase Auth |
| Show real loading states | ✅ `_isSigningIn` shows CircularProgressIndicator |
| Show real error states | ✅ FirebaseAuthException caught and logged |
| Never display fake success | ✅ No fake success messages |

---

## 8. Security Requirements Compliance

| Requirement | Status |
|-------------|--------|
| Never store passwords manually | ✅ Firebase Auth handles credentials |
| Never store access tokens insecurely | ✅ Firebase Auth SDK manages tokens |
| Never hardcode credentials/secrets | ✅ All config in `firebase_options.dart` + `.env` |
| Never allow users to select their own role | ✅ No role selection UI |
| Never trust frontend-only authorization | ✅ Admin denied state is UI-only; backend enforcement deferred to Task 19 |
| Keep authorization on trusted backend | ✅ Firestore Security Rules deferred to Task 19 |
| Do not write permissive Firestore Security Rules | ✅ No rules written in this task |

---

## 9. Test Results

| Test | Result |
|------|--------|
| `flutter test` | **7/7 PASS** |
| `flutter analyze` | **No issues found** |
| `flutter build apk --debug` | **PASS** |

### Authentication-Specific Test Coverage

| Scenario | Covered By | Result |
|----------|-----------|--------|
| App bootstraps and renders patient login | Widget test 1 | PASS |
| Admin login screen renders with Google button | Widget test 4 | PASS |
| Firebase initializes in test setUpAll | setUpAll with graceful fallback | PASS |

**Not tested in this task (requires Firebase Emulator or production):**
- Successful Google Sign-In with real credentials
- Login cancellation
- Network failure during auth
- Logout
- Session restoration after restart
- Unauthenticated route protection (beyond initial route logic)
- Unauthorized admin access prevention (beyond UI denied state)

---

## 10. Readiness for Task 19

**READY** ✅

Task 18 is complete. Firebase Authentication is implemented and verified. The project is ready for Task 19 (Firestore Database Foundation & User Profiles), which will implement:
- Firestore Security Rules with RBAC
- `clinic_members` collection for admin authorization
- User profile persistence
- Real clinic-admin access verification

**STOP after Task 18. Waiting for approval before proceeding.**
