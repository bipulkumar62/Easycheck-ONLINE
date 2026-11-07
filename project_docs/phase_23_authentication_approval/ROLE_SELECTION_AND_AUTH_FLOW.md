# Role Selection & Authentication Flow

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 5, 2026

---

## 1. Entry Screen

Every app launch starts at `AppRoutes.initial` (`/`) with `RoleSelectionScreen`.

Required heading, rendered exactly:

> **Aap kis roop mein continue karna chahte hain?**

Supporting copy:

> Choose how you want to use EasyCheck. You can switch later by signing out.

Two cards are presented:

| Card | Key | Destination |
|------|-----|-------------|
| Continue as Patient | `role_patient_button` | `/patient/login` |
| Continue as Doctor/Staff | `role_admin_button` | `/admin/login` |

Both cards reuse the original Clinical Clarity palette, Inter typography, rounded cards, ambient accent orbs and the EasyCheck logo mark. The layout was checked at 320 px width with no overflow.

The selected role is **not** an authorization decision. It only chooses which login experience to open.

---

## 2. Patient Flow

```
App launch
  → Role Selection
  → "Continue as Patient"
  → Patient Google Login
  → Google account chosen
  → AuthGate (role = patient)
  → ensurePatientProfile(uid, email, displayName, photoUrl)
  → Patient Home
```

### 2.1 Profile creation rules

`UserProfileRepository.ensurePatientProfile` runs a Firestore transaction:

1. Read `users/{uid}`.
2. If the document does not exist, create it with:
   - `email`
   - `displayName`
   - `photoUrl`
   - `role: 'patient'`
   - `createdAt`, `updatedAt`
   - `isActive: true`
3. If the document already exists, return it unchanged.

Existing profile fields are **never overwritten**, and the deterministic document ID (the Firebase UID) prevents duplicate profiles.

### 2.2 Existing session reuse

If `FirebaseAuth.instance.currentUser` is already present, `GoogleAuthService.signIn()` returns it and the login screen continues to the auth gate. This avoids re-authentication friction after an app restart.

### 2.3 Google sign-in implementation

`lib/features/authentication/google_auth_service.dart` handles the real sign-in:

1. On Android, `GoogleSignIn.instance.authenticate()` opens the native Google Identity account picker (`CredentialChooserActivity`) — not a Chrome/browser redirect.
2. The returned Google ID token is exchanged with Firebase Auth via `signInWithCredential(GoogleAuthProvider.credential(idToken: ...))`.
3. On platforms without a native authenticate UI, the service falls back to Firebase's `signInWithProvider(GoogleAuthProvider())`.
4. Native `GoogleSignInException` codes and Firebase Auth errors are mapped by `AuthErrorMapper` to non-technical messages.

### 2.4 Switch account

The login screen offers a **Use a different account** action that calls `GoogleAuthService.signOut()` — clearing both the Google session and the Firebase session — and clears the visible error, so the next tap opens the Google account picker again.

---

## 3. Doctor / Staff Flow

```
App launch
  → Role Selection
  → "Continue as Doctor/Staff"
  → Clinic Admin Google Login
  → Google account chosen
  → AuthGate (role = admin)
  → AdminAccessService.resolve(user.uid)
      ├─ active membership / clinics.adminUid → Admin Dashboard
      ├─ pending request                      → Pending Approval
      ├─ rejected request                     → Rejected
      ├─ approved request, no membership      → Unauthorized (fail closed)
      └─ no membership and no request         → Access Request Form
```

### 3.1 Resolution order

`AdminAccessService.resolveUid(uid)` checks:

1. **Active memberships** — `clinic_members` where `userId == uid`, role is active and the clinic is active.
2. **Clinic owner link** — `clinics.adminUid == uid` and the clinic is active. This field can only be written by trusted backend tooling; Firestore rules block client changes.
3. **Access requests** — newest request for the UID:
   - `pending` → pending screen
   - `rejected` → rejected screen
   - `approved` but no active membership → inconsistent/unauthorized screen
4. **No record** → access request form.

No branch treats “signed in with Google” as sufficient for admin access.

### 3.2 Inconsistent state

If a request says `approved` but no active membership exists, the app does **not** open the dashboard. It shows `AdminUnauthorizedScreen` with an explanation that the membership must be activated by the clinic administrator. This prevents a forged or stale approval flag from granting access.

---

## 4. Access Request Form

`AdminAccessRequestScreen` collects:

| Field | Notes |
|-------|-------|
| Clinic | Dropdown populated from active Firestore clinics |
| Full name | Minimum 2 characters |
| Email | Prefilled from the authenticated Google account; read-only identity source |
| Contact number | Required |
| Role/context | Clinic staff access request |

Submission:

- Requires a signed-in Firebase user.
- Uses document ID `{uid}_{clinicId}` to prevent duplicates.
- Writes `status: 'pending'` only.
- Writes review fields as `null`.
- On success, opens `AdminRequestSubmittedScreen` with the real request ID and clinic name.
- If a request already exists, the repository reports the duplicate instead of creating a second document.

---

## 5. Pending, Rejected and Unauthorized Screens

| Screen | Content | Actions |
|--------|---------|---------|
| Submitted | Request ID, clinic, pending status, what happens next | Check status, sign out |
| Pending | “Approval pending”, clinic, submitted date | Check status, sign out |
| Rejected | “Application not approved”, clinic, reason if present | Request access for another clinic, sign out |
| Unauthorized | “Access Not Authorized”, real message | Request clinic access, sign out & switch account |

All four screens use the shared `AdminAuthShell` so the Clinical Precision top bar, surface color, card proportions and spacing remain consistent with the original Stitch admin UI.

No screen fabricates an approval, a reviewer, a timestamp or a success state.

---

## 6. Error Handling

`AuthErrorMapper` converts Firebase Auth and app failures into non-technical messages:

| Condition | User-facing behavior |
|-----------|----------------------|
| Google popup/picker closed (`canceled`, `popup-closed-by-user`) | “Sign-in cancelled.” — treated as cancellation, not denial |
| Google flow interrupted | “Google sign-in was interrupted. Please try again.” |
| Google client/provider configuration error | “Google sign-in is not available on this build.” No SDK names or config values shown |
| Google UI unavailable | “Google sign-in could not open on this device.” |
| Different Google account already active | Asks the user to sign out and try again |
| Network failure | “Network error. Check your connection and try again.” |
| Unauthorized domain | Explains the domain is not authorized, without exposing error codes |
| Firebase not configured | Install/update message; no simulated success |
| Expired session | “Your sign-in session has expired. Please sign in again.” |
| Firestore/backend failure | Retry affordance on the auth gate; dashboard fails closed |

The auth gate has explicit **Retry** and **Sign out** actions. A failed resolution never falls through to a dashboard.

---

## 7. Google-Only Enforcement

| Setting | State |
|---------|-------|
| Google sign-in provider | Enabled (`projects/1085858861836/defaultSupportedIdpConfigs/google.com`) |
| Email/password provider | Disabled |
| Anonymous provider | Removed from `firebase.json` |
| Live email/password sign-up | Blocked with `OPERATION_NOT_ALLOWED` |

`firebase.json` now declares only `googleSignIn`. The deployed Identity Toolkit configuration was verified after deployment.

---

## 8. Session and Navigation Guarantees

- Role selection is always the first route, including for already-authenticated users.
- Successful patient login uses `pushNamedAndRemoveUntil` to Patient Home, so Back cannot return to login.
- Successful admin resolution replaces the auth gate with the resolved destination.
- Sign-out always returns to role selection and clears the Firebase session.
- Back navigation from either login screen returns to role selection.
- No route opens the admin dashboard without `AdminDashboardScreen` re-checking authorization on load.

---

## 9. Visual Preservation

The new screens reuse:

- Patient palette (`PatientColors`) for role selection and patient login.
- Admin palette (`AdminColors`) for doctor/staff login and approval screens.
- Inter font family and existing type scale.
- Existing card radii, shadows, padding and ambient orbs.
- Existing logo assets and icon language.

No Stitch screen was redesigned. New screens were composed from the same tokens and component patterns.
