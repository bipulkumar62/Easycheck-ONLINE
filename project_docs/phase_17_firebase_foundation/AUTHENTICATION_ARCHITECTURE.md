# Authentication Architecture

**Phase:** Task 17 — Firebase Project Setup & Backend Architecture  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Authentication Strategy

EasyCheck Online uses **Firebase Authentication** with **Google Sign-In (OAuth 2.0)** as the primary authentication method, with **Anonymous Authentication** as a fallback for patients who do not wish to sign in.

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| Primary method | Google Sign-In | Clinic staff need verified identities; patients benefit from single-tap login |
| Fallback method | Anonymous Auth | Patients can browse clinics without creating an account |
| Email/Password | Not enabled | Google Sign-In is simpler and more secure |
| Phone Auth | Not enabled | Not in approved scope |
| Multi-factor auth | Not enabled | Not in approved scope |

---

## 2. User Roles

| Role | Auth Method | Use Case |
|------|-------------|----------|
| `patient` | Google Sign-In or Anonymous | Browse clinics, view queue status |
| `clinic_admin` | Google Sign-In only | Manage clinic operations, issue parchi tokens |
| `front_desk_lead` | Google Sign-In only | Daily tallies, doctor status |
| `triage_coordinator` | Google Sign-In only | Patient queue management |

**Role Assignment:** Roles are stored in `users.role` field and clinic membership in `clinic_members` collection. Firebase Auth does not store custom roles — they are enforced via Firestore Security Rules.

---

## 3. Authentication Flow

### 3.1 Patient Sign-In (Google)

```
Patient taps "Continue with Google" on /patient/login
    │
    ▼
Flutter calls google_sign_in plugin
    │
    ▼
Google OAuth consent screen
    │
    ▼
Google returns ID token + user info
    │
    ▼
Flutter calls FirebaseAuth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken))
    │
    ▼
Firebase Auth creates/returns user account
    │
    ▼
Flutter checks if users/{uid} exists → creates if new (role: "patient")
    │
    ▼
Navigate to /patient/home
```

### 3.2 Clinic Staff Sign-In (Google)

```
Staff taps "Continue with Google" on /admin/login
    │
    ▼
Flutter calls google_sign_in plugin
    │
    ▼
Google OAuth consent screen
    │
    ▼
Google returns ID token + user info
    │
    ▼
Flutter calls FirebaseAuth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken))
    │
    ▼
Firebase Auth returns user account
    │
    ▼
Flutter checks users/{uid}.role == "clinic_admin"
    │
    ├─ If YES and clinic_members exists → Navigate to /admin/dashboard
    ├─ If YES but no clinic_members → Navigate to /admin/unauthorized
    └─ If NO → Navigate to /admin/unauthorized
```

### 3.3 Anonymous Sign-In (Patient Fallback)

```
Patient chooses to browse without signing in
    │
    ▼
Flutter calls FirebaseAuth.instance.signInAnonymously()
    │
    ▼
Firebase Auth returns anonymous user account
    │
    ▼
Flutter creates users/{uid} with role: "patient", isAnonymous: true
    │
    ▼
Navigate to /patient/home
```

### 3.4 Sign-Out

```
User taps "Log out"
    │
    ▼
Flutter calls FirebaseAuth.instance.signOut()
    │
    ▼
Google sign-in plugin signs out (clears Google session)
    │
    ▼
Navigate to appropriate login screen (/patient/login or /admin/login)
```

---

## 4. Session Management

| Aspect | Implementation |
|--------|---------------|
| Session persistence | Firebase Auth persists across app restarts (auto sign-in) |
| Token refresh | Handled automatically by Firebase Auth SDK |
| Id token expiry | 1 hour (auto-refreshed by SDK) |
| Sign-out on app close | Not implemented (session persists) |

---

## 5. Current vs. Target State

### Current State (Simulated)

| Aspect | Current Implementation |
|--------|----------------------|
| Authentication | Simulated with `setState` delays and hardcoded redirects |
| Google Sign-In | Fake button with 1200ms delay simulation |
| User accounts | None — hardcoded "Dr. Sarah Jenkins", "Reception Apex" |
| Role checking | None — all admin screens accessible via direct navigation |
| Token persistence | None |

### Target State (Firebase)

| Aspect | Target Implementation |
|--------|----------------------|
| Authentication | `FirebaseAuth.instance.signInWithCredential()` |
| Google Sign-In | Real OAuth via `google_sign_in` + `firebase_auth` plugins |
| User accounts | Created in `users` collection on first sign-in |
| Role checking | Firestore Security Rules check `users.role` and `clinic_members` |
| Token persistence | Firebase Auth handles automatically |

---

## 6. Security Considerations

| Consideration | Implementation |
|--------------|---------------|
| ID token verification | Firebase Auth verifies automatically on server side |
| Client-side trust | **None** — Flutter UI checks are NOT security controls |
| Anonymous access | Restricted to read-only clinic browsing |
| Admin access | Requires `clinic_members` entry with appropriate permissions |
| Session hijacking | Firebase Auth handles token security |
| Passwordless | No password-based auth — reduces credential stuffing risk |

---

## 7. What Is NOT Implemented in This Phase

| Feature | Reason |
|---------|--------|
| `FirebaseAuth.signInWithCredential()` | Task restriction — no auth implementation yet |
| Google Sign-In integration | Task restriction — deferred to next phase |
| User account creation in Firestore | Task restriction — deferred |
| Role-based route guards | Task restriction — deferred |
| Anonymous sign-in UI | Task restriction — deferred |

---

## 8. Migration Path from Simulated to Real Auth

| Step | Action |
|------|--------|
| 1 | Generate `firebase_options.dart` via `flutterfire configure` |
| 2 | Initialize Firebase in `main.dart` |
| 3 | Replace simulated Google button with real `google_sign_in` flow |
| 4 | Replace simulated OAuth delay with `FirebaseAuth.signInWithCredential()` |
| 5 | Add `users` collection write on first sign-in |
| 6 | Add route guards checking `users.role` and `clinic_members` |
| 7 | Update admin screens to check permissions via Firestore reads |
