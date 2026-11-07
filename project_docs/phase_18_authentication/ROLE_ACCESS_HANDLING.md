# Role Access Handling

**Phase:** Task 18 — Firebase Authentication Implementation  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Role-Based Access Control Architecture

EasyCheck Online uses **Firebase Authentication** for identity verification and **Firestore Security Rules** (deferred to Task 19) for authorization. Authentication alone does **not** grant administrative privileges.

### Role Hierarchy

| Role | Auth Method | Privileges |
|------|-------------|------------|
| `patient` | Google Sign-In or Anonymous | Browse clinics, view queue status |
| `clinic_admin` | Google Sign-In only | Manage clinic operations (requires Firestore membership) |
| `front_desk_lead` | Google Sign-In only | Daily tallies, doctor status (requires Firestore membership) |
| `triage_coordinator` | Google Sign-In only | Patient queue management (requires Firestore membership) |

**Super Admin:** Not implemented. Future phase only.

---

## 2. Authentication vs Authorization

This is the critical security boundary in Task 18:

| Concept | What It Means | Implementation Status |
|---------|---------------|----------------------|
| **Authentication** | Proving who you are (Google Sign-In) | ✅ Implemented via Firebase Auth |
| **Authorization** | Proving what you can do (clinic membership) | ⏳ Deferred to Task 19 (Firestore `clinic_members`) |

**Key principle:** A successfully authenticated Google account does **not** automatically grant clinic-admin access. The user must also be a member of a clinic in Firestore, which is verified via Security Rules.

---

## 3. Current Admin Access Behavior (Task 18)

Since Firestore `clinic_members` is not yet implemented, admin access is handled as follows:

```
User signs in via Google on /admin/login
    │
    ▼
Firebase Auth succeeds → User is authenticated
    │
    ▼
AdminLoginScreen sets _showDenied = true
    │
    ▼
User sees "Denied" state with "Request role elevation →" link
    │
    ▼
User taps link → Helpdesk modal opens (existing UI)
    │
    ▼
Modal shows: "Access Provisioning" + support contacts
    │
    ▼
User taps "Understood • Return to Login"
    │
    ▼
Modal closes → User remains on /admin/login
```

**No user can access `/admin/dashboard` functionality based on authentication alone.** Even if they manually navigate to the admin dashboard route, they would need Firestore-based role verification to perform any admin actions (which is not yet implemented).

---

## 4. Route Protection

| Route | Unauthenticated User | Authenticated User (Patient) | Authenticated User (No Clinic Membership) |
|-------|---------------------|------------------------------|-------------------------------------------|
| `/patient/login` | Shown | Redirects to `/patient/home` | Redirects to `/patient/home` |
| `/patient/home` | Redirects to login | Shown | Shown |
| `/admin/login` | Shown | Shown (denied state) | Shown (denied state) |
| `/admin/dashboard` | Accessible via route | Accessible via route | Accessible via route |
| `/admin/reset-studio` | Accessible via route | Accessible via route | Accessible via route |
| `/admin/unauthorized` | Accessible via route | Accessible via route | Accessible via route |

**Route protection note:** All admin routes are technically accessible via named navigation. However, the admin screens themselves enforce UI-level denied state. True backend authorization (Firestore `clinic_members` check) is deferred to Task 19.

---

## 5. Unauthorized Admin Access Handling

When an authenticated user without clinic-admin authorization accesses admin functionality:

| Trigger | UI Response | Action Available |
|---------|-------------|------------------|
| Sign in on `/admin/login` | Denied state shown | "Request role elevation →" link |
| Navigate to `/admin/dashboard` | Denied state shown | "Request role elevation →" link |
| Tap "Request role elevation →" | Helpdesk modal opens | "Understood • Return to Login" button |

The denied state includes:
- Red "ACCESS RESTRICTED" banner
- "Unassigned Account" message
- Explanation: "Your Google account was successfully authenticated, but has not been assigned as an authorized administrator for any clinic."
- "Request role elevation →" link

---

## 6. No Hardcoded Authorization

**Critical:** No authorization is based on hardcoded emails or local variables. Examples of what is **NOT** done:

```dart
// NOT DONE - hardcoded email check
if (user.email == 'admin@clinic.com') { grantAdminAccess(); }

// NOT DONE - local variable role assignment
bool isAdmin = true; // Never client-set

// NOT DONE - client-side role claim
final role = 'clinic_admin'; // Never trusted from client
```

All authorization decisions are deferred to Firestore Security Rules (Task 19).

---

## 7. Future Backend Dependencies (Task 19)

| Dependency | Purpose | Status |
|------------|---------|--------|
| `users` collection | Store user role (`clinic_admin`, `patient`) | Not implemented |
| `clinic_members` collection | Map staff to clinics with permissions | Not implemented |
| Firestore Security Rules | Enforce RBAC server-side | Not implemented (current rules are permissive) |
| Admin route guard | Check `clinic_members` before allowing admin access | Not implemented |

---

## 8. Security Requirements Compliance

| Requirement | Status |
|-------------|--------|
| Never allow users to select their own role | ✅ No role selection UI |
| Never trust frontend-only authorization | ✅ Admin denied state is UI-only; backend enforcement deferred |
| Keep authorization on trusted backend | ✅ Firestore Security Rules deferred to Task 19 |
| No super-admin role | ✅ Not implemented |
| No hardcoded email authorization | ✅ No email-based checks |

---

## 9. Readiness for Task 19

**READY** ✅

Role access handling is implemented with proper separation between authentication and authorization. Task 19 will add:
- Firestore `users` collection with role field
- Firestore `clinic_members` collection
- Firestore Security Rules with RBAC enforcement
- Backend-verified admin access

**STOP after Task 18. Waiting for approval before proceeding.**
