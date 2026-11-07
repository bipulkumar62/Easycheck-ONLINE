# Interaction Status: Admin Screen 01

**Phase:** Phase 11 — Admin UI Implementation  
**Screen Target:** Screen A-01 (Admin Google Authentication)

---

## 1. Prototype Interactions Implemented

1. **Google Sign-In Trigger (`_handleGoogleSignIn()`):**
   - **Trigger:** Tap on `"Continue with Google"` button.
   - **Action:** Disables button interactions, displays the spinning OAuth loader overlay (`"Authenticating OAuth..."`) for 1200ms.
   - **Feedback:** Reveals dynamic verified status card displaying `"IDENTITY VERIFIED"`, `"Dr. Sarah Jenkins"`, `"Lead Triage • Station 4 Ready"`, and spinning redirect message.
   - **Navigation:** Redirects to `/admin/dashboard` via `Navigator.pushReplacementNamed()`.
   - **Source Reference:** Matches JavaScript lines 103–139 of `google_authentication/code.html`.

2. **Access Provisioning Helpdesk Dialog:**
   - **Trigger:** Tap on `"Request role elevation →"` or helpdesk trigger.
   - **Action:** Opens the `_buildHelpdeskModal` overlay with frosted backdrop.
   - **Dismissal:** Tap on close icon (`close_rounded`) or `"Understood • Return to Login"` button dismisses modal.
   - **Source Reference:** Matches JavaScript lines 166–174 of `google_authentication/code.html`.

---

## 2. Backend Dependencies (Deferred to Firebase Phase)

| Interaction | Frontend State Implemented | Backend Dependency |
| :--- | :--- | :--- |
| **OAuth Exchange** | 1200ms simulated handshake | `FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider)` |
| **RBAC Authorization** | Verified/Denied state card | Cloud Firestore security check querying `staff_roles/{uid}` |
| **Session Persistence** | Memory state | Firebase Auth persistent session tokens |
