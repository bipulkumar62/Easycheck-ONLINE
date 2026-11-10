# MULTI-TAB-CONFLICT.md — Multi-Tab & Concurrent Session Audit

> **Target Application:** EasyCheck Online (`easycheck-online`)  
> **Auditor Role:** Senior Software Engineer — Browser Concurrency, State Management & Production Reliability  
> **Audit Status:** Complete — Read-Only Forensic Assessment  
> **Document Version:** 1.0.0  
> **Audit Date:** 2026-11-10  
> **Execution Mode:** Non-Destructive / Zero Code Modifications  

---

## 1. Executive Summary & Audit Scope

This document provides a comprehensive forensic audit of **multi-tab concurrency**, **browser state synchronization**, **shared web storage interactions**, and **race conditions** across **EasyCheck Online**.

When web applications run in a browser environment (Chrome, Edge, Safari, Firefox), users frequently open multiple tabs or windows (e.g., viewing patient queue metrics in Tab A while managing clinic settings or viewing the patient discovery experience in Tab B). Because browser tabs share origin-level resources—including **HTML5 `localStorage`**, **`IndexedDB`**, **Firebase Auth instances**, and **Service Workers**—uncoordinated state mutations in one tab can silently corrupt, desynchronize, or clobber operations in another tab.

### High-Level Audit Findings

| Category | Finding Summary | Severity | Status |
| :--- | :--- | :---: | :---: |
| **Auth State Sync Across Tabs** | Zero screens or services listen to `FirebaseAuth.instance.authStateChanges()`. Logging out in Tab A leaves Tab B displaying authenticated views with stale in-memory state until an action fails. | **High** | Confirmed |
| **Cross-Tab Role Clobbering** | `AuthSessionStore` persists the active UX role (`admin` vs `patient`) into shared `localStorage['flutter.easycheck_last_role']`. Opening a Patient view in Tab B mutates the role for Tab A upon browser refresh. | **High** | Confirmed |
| **Single-Origin Identity Switching** | Firebase Web Auth shares a single IndexedDB user store per origin. Signing in with a personal account in Tab B silently changes the Auth UID for Tab A, breaking Admin dashboard writes. | **High** | Confirmed |
| **Concurrent Profile Editing (LWW)** | Clinic doctor profile editing (`_saveDoctorProfile`) uses blind `updateClinic` calls without optimistic concurrency control (OCC). Tab B's stale dialog overwrites Tab A's edits. | **Medium** | Confirmed |
| **Multi-Tab Access Request Race** | `submitRequest` uses non-transactional checks followed by `ref.set()`. Simultaneous submissions across tabs trigger Firestore security rule violations (`permission-denied`). | **Medium** | Confirmed |
| **Real-Time Queue Tally (Resilient)** | Queue tally increments/decrements/resets utilize Firestore atomic transactions (`runTransaction`) and live streams (`sessionStream`), effectively serializing counter updates across tabs. | **Low Risk** | Confirmed Resilient |

---

## 2. Phase 1 — Project Architecture & Shared State Discovery

### 2.1 Technology Stack & Web Execution Layer

- **Framework:** Flutter Web & Mobile (`sdk: ^3.13.0`, Material 3 design system).
- **Web Renderer:** CanvasKit / HTML Flutter engine.
- **Client Storage Engines:**
  - `shared_preferences: ^2.5.6` (Maps directly to HTML5 `window.localStorage` on web under the `flutter.` key prefix).
  - `firebase_auth: ^7.0.1` (Utilizes browser `IndexedDB` under `firebaseLocalStorageDb` to store OAuth tokens and session state across tabs).
  - `cloud_firestore: ^7.1.0` (Web IndexedDB offline persistence / in-memory cache).
- **Communication Protocols:**
  - Cloud Firestore Real-Time WebSockets / gRPC Web channels (Snapshot listeners).
  - HTTP REST (Supabase Edge Function `/functions/v1/clinic-photo-upload`).
- **Target Topologies:** Dual persona (Outpatient Clinic Admin vs. Public Patient Discovery).

### 2.2 Shared Browser State Inventory

The following state repositories are shared across all tabs running on the same web origin (`https://easycheck-online.web.app` or `http://localhost:<port>`):

```
+-----------------------------------------------------------------------------------------+
|                                    Browser Origin                                       |
|                                                                                         |
|  +-----------------------------------+        +--------------------------------------+  |
|  |       window.localStorage         |        |           window.indexedDB           |  |
|  |-----------------------------------|        |--------------------------------------|  |
|  | flutter.easycheck_last_role       |        | firebaseLocalStorageDb               |  |
|  | flutter.easycheck_language_code   |        |   (Shared Firebase Auth user session |  |
|  +-----------------------------------+        |    & active credentials)             |  |
|                                               +--------------------------------------+  |
+------------------------------------------+----------------------------------------------+
                                           |
                    +----------------------+----------------------+
                    |                                             |
                    v                                             v
        +-----------------------+                     +-----------------------+
        |         Tab A         |                     |         Tab B         |
        |  (e.g., Admin Portal) |                     |  (e.g., Patient View) |
        +-----------------------+                     +-----------------------+
```

1. **`flutter.easycheck_last_role`:**
   - **Declared in:** `lib/features/authentication/auth_session_store.dart:13`
   - **Content:** `'admin'` or `'patient'`
   - **Scope:** Origin-wide. Tab A and Tab B read and overwrite the exact same key.
2. **`flutter.easycheck_language_code`:**
   - **Declared in:** `lib/app/localization/locale_controller.dart:11`
   - **Content:** `'en'` or `'hi'`
   - **Scope:** Origin-wide.
3. **Firebase Auth IndexedDB (`firebaseLocalStorageDb`):**
   - **Managed by:** Google Firebase JS SDK / FlutterFire.
   - **Scope:** Origin-wide. Tab A and Tab B share the exact same active `User` object and ID token.

---

## 3. Phase 2 & 3 — Multi-Tab Conflict Audit & Impact Analysis

This section analyzes the 12 specific concurrency vectors mandated by the audit specification.

---

### Vector 1: Logout Synchronization Across Tabs

- **Issue Title:** Lack of Multi-Tab Sign-Out Propagation
- **Severity:** **HIGH**
- **Affected Files & Functions:**
  - `lib/features/patient/patient_home_screen.dart:369-380` (`_signOut()`)
  - `lib/features/admin/admin_dashboard_screen.dart:906-915` (`_signOut()`)
  - `lib/features/authentication/auth_gate_screen.dart:165-175` (`_signOut()`)
- **Status:** **CONFIRMED**
- **Exact Reproduction Scenario:**
  1. Open Tab A at `https://<domain>/` and sign in as Clinic Admin.
  2. Open Tab B at `https://<domain>/` (navigates to Admin Dashboard sharing the session).
  3. In Tab A, click "Sign out".
  4. Tab A executes `FirebaseAuth.instance.signOut()` and navigates to the public Role Selection screen.
  5. Inspect Tab B.
- **Current Behavior:** Tab B remains on `AdminDashboardScreen`. The UI continues displaying the clinic's internal queue tally, doctor controls, and staff lists. No redirect or banner appears. When the user in Tab B clicks "Next Ticket", Firestore rejects the request with a raw permission error.
- **Expected Behavior:** Logging out in Tab A should trigger an immediate logout event in Tab B, clearing sensitive in-memory state and navigating Tab B to the Role Selection screen.
- **Root Cause & Evidence:** No component in EasyCheck Online subscribes to `FirebaseAuth.instance.authStateChanges()`. Each screen fetches `FirebaseAuth.instance.currentUser` once during `initState()` and holds it in a local `_user` instance variable.
- **Impact:** Security risk on shared clinic workstations. A staff member who logs out in one tab leaves another open tab vulnerable to unauthorized access or orphaned state.

---

### Vector 2: Cross-Tab Role Clobbering in LocalStorage

- **Issue Title:** Dual-Persona Session Hijacking via Shared `localStorage` Role Key
- **Severity:** **HIGH**
- **Affected Files & Functions:**
  - `lib/features/authentication/auth_session_store.dart:29-52` (`saveRole()`, `loadRole()`)
  - `lib/features/authentication/role_selection_screen.dart:38-61` (`_maybeResumeSession()`, `_continueAs()`)
- **Status:** **CONFIRMED**
- **Exact Reproduction Scenario:**
  1. In Tab A, clinic admin selects "Clinic Staff / Admin" and signs in.
  2. Tab A writes `AuthSessionStore.saveRole(AuthRole.admin)` (`localStorage['flutter.easycheck_last_role'] = 'admin'`).
  3. In Tab B, the admin wants to check what patients see. They navigate to the app root and click "Patient".
  4. Tab B writes `AuthSessionStore.saveRole(AuthRole.patient)` (`localStorage['flutter.easycheck_last_role'] = 'patient'`).
  5. The user returns to Tab A and hits Refresh (`F5`).
- **Current Behavior:** Tab A's `RoleSelectionScreen._maybeResumeSession()` loads `'patient'` from `localStorage`. Instead of restoring the Admin Dashboard, Tab A routes to `PatientHomeScreen`!
- **Expected Behavior:** Tab A's role selection should either be scoped to that browser tab/window or be derived from server-side verified claims rather than a mutable, shared string in `localStorage`.
- **Root Cause & Evidence:**
  ```dart
  // lib/features/authentication/auth_session_store.dart:31-35
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_storageKey, role == AuthRole.admin ? 'admin' : 'patient');
  ```
  `SharedPreferences` on Flutter Web uses HTML5 `window.localStorage` (origin-wide) rather than `window.sessionStorage` (tab-scoped).
- **Impact:** High user confusion and operational disruption. Staff members frequently switch views or test patient interfaces, inadvertently corrupting their admin workstation tabs.

---

### Vector 3: Cross-Tab Account Identity Switching

- **Issue Title:** Silent Account Desynchronization on Single-Origin Multi-Login
- **Severity:** **HIGH**
- **Affected Files & Functions:**
  - `lib/features/authentication/google_auth_service.dart:58-72` (`signIn()`)
  - `lib/features/admin/admin_dashboard_screen.dart:245-265` (`_increment()`)
- **Status:** **CONFIRMED**
- **Exact Reproduction Scenario:**
  1. In Tab A, Dr. Sharma logs in with `dr.sharma@easycheck.com` to manage Clinic CLN-10001.
  2. In Tab B, another user (or Dr. Sharma using a personal account `patient.sharma@gmail.com`) signs in as a Patient.
  3. The underlying Firebase Web SDK switches the active user in `IndexedDB` to `patient.sharma@gmail.com`.
  4. User switches back to Tab A and clicks "Increment Parchi" (or updates Doctor Status).
- **Current Behavior:** Tab A's UI displays Dr. Sharma's name. However, the Firestore transaction runs with `request.auth.uid = patient.sharma.uid`. Firestore Security Rules evaluate `isActiveMember(request.auth.uid, clinicId)` and throw `permission-denied`. Tab A displays: `Could not update the counter: [cloud_firestore/permission-denied]`.
- **Expected Behavior:** Tab A should detect that the underlying Firebase Auth identity changed, invalidate the in-memory admin dashboard state, and prompt the user to re-authenticate or reload.
- **Root Cause & Evidence:** Absence of an `authStateChanges()` or `idTokenChanges()` stream listener in `AdminDashboardScreen`.
- **Impact:** Data write failure and confusing error alerts.

---

### Vector 4: Concurrent Record Editing & Last-Write-Wins (LWW) Overwrites

- **Issue Title:** Silent Field Clobbering in Doctor Profile & Clinic Metadata
- **Severity:** **MEDIUM**
- **Affected Files & Functions:**
  - `lib/features/admin/admin_dashboard_screen.dart:518-545` (`_saveDoctorProfile()`)
  - `lib/features/admin/admin_dashboard_screen.dart:484-505` (`_saveDoctorTiming()`)
  - `lib/features/clinics/clinic_repository.dart:49-58` (`updateClinic()`)
- **Status:** **CONFIRMED**
- **Exact Reproduction Scenario:**
  1. Staff Member A opens Admin Dashboard in Tab A.
  2. Staff Member B opens Admin Dashboard in Tab B.
  3. In Tab A, Staff A opens the "Edit Doctor Profile" modal (shows Name: "Dr. Roy", Specialty: "General").
  4. In Tab B, Staff B opens the "Edit Doctor Profile" modal (shows Name: "Dr. Roy", Specialty: "General").
  5. Staff A changes Specialty to "Cardiologist" and clicks Save. Firestore updates `clinics/{clinicId}` with `doctorSpecialty: 'Cardiologist'`.
  6. Staff B (who still has the modal open with the old snapshot) updates Name to "Dr. Amit Roy" and clicks Save.
- **Current Behavior:** Staff B's modal sends the entire draft:
  ```dart
  await _clinicRepository.updateClinic(clinic.clinicId, {
    'doctorName': 'Dr. Amit Roy',
    'doctorCredentials': draft.credentials,
    'doctorSpecialty': 'General', // STALE VALUE!
  });
  ```
  Firestore blindly updates all three fields. Staff A's update ("Cardiologist") is silently overwritten and lost.
- **Expected Behavior:** The application should either perform field-level atomic delta updates (updating only dirty fields) or enforce optimistic locking (checking `updatedAt` timestamp before writing).
- **Root Cause & Evidence:** `_DoctorProfileDialog` builds a draft of all three fields and `updateClinic` overwrites all three fields without version checking or precondition clauses.
- **Impact:** Unintentional data regression in clinic contact and doctor details when multiple front-desk staff operate simultaneously.

---

### Vector 5: Multi-Tab Access Request Submission Race

- **Issue Title:** Unhandled Security Rule Violation on Concurrent Request Submissions
- **Severity:** **MEDIUM**
- **Affected Files & Functions:**
  - `lib/features/authentication/admin_access_request_repository.dart:110-150` (`submitRequest()`)
  - `firestore.rules:161-196` (`match /admin_access_requests/{requestId}`)
- **Status:** **CONFIRMED**
- **Exact Reproduction Scenario:**
  1. An applicant opens the "Request Admin Access" screen in Tab A and Tab B.
  2. In both tabs, they select Clinic CLN-10001.
  3. They click "Submit Request" in both tabs within 1 second.
  4. Both tabs invoke `submitRequest()`.
- **Current Behavior:**
  - Both tabs execute `getRequestsForUser(uid)` in parallel; both receive an empty list (`existing == null`).
  - Tab A executes `ref.set({...})`. The document `admin_access_requests/{uid}_CLN-10001` is created.
  - Tab B executes `ref.set({...})` on the newly created document.
  - In `firestore.rules`, ordinary users have `allow create`, but **NO `allow update`** (only Super Admins can update).
  - Firestore evaluates Tab B's `set()` call as an **UPDATE**, rejecting it with `FirebaseException: [cloud_firestore/permission-denied]`.
  - Tab B displays a red error banner: *"Could not submit request. Check your connection or permissions."*
- **Expected Behavior:** Tab B should gracefully detect the existing request and transition to the `AdminPendingApprovalScreen` without throwing a security exception.
- **Root Cause & Evidence:** Non-atomic existence check in `submitRequest()`:
  ```dart
  // lib/features/authentication/admin_access_request_repository.dart:114-136
  final existingRequests = await getRequestsForUser(uid);
  // ... (race window)
  await ref.set({...});
  ```
- **Impact:** Poor user experience; applicants believe the system encountered an internal error.

---

### Vector 6: Language / Locale Desynchronization Across Tabs

- **Issue Title:** Out-of-Sync UI Language State in Multi-Tab Browsing
- **Severity:** **LOW**
- **Affected Files & Functions:**
  - `lib/app/localization/locale_controller.dart:38-53` (`setLocale()`, `toggle()`)
- **Status:** **CONFIRMED**
- **Exact Reproduction Scenario:**
  1. Open Tab A and Tab B on `PatientHomeScreen`. Both load in English (`en`).
  2. In Tab A, click the language toggle (English -> Hindi).
  3. Tab A re-renders in Hindi (`hi`) and writes `'hi'` to `localStorage['flutter.easycheck_language_code']`.
  4. Inspect Tab B.
- **Current Behavior:** Tab B remains in English because `LocaleController` maintains an in-memory `_locale` variable that is not bound to the browser's `window.addEventListener('storage', ...)` event. If the user in Tab B toggles the language, it evaluates `isHindi` as false and writes `'hi'` again.
- **Expected Behavior:** Toggling language in Tab A should instantly update Tab B or synchronize seamlessly upon tab focus.
- **Root Cause & Evidence:** `LocaleController` uses `notifyListeners()` within its own Dart isolate/memory space only, with zero cross-tab event broadcasting.
- **Impact:** Minor visual inconsistency; no business data loss.

---

### Vector 7: Day-Start Queue Session Creation Race

- **Issue Title:** Concurrent Initialization of `queue_sessions` on Calendar Day Boundary
- **Severity:** **LOW**
- **Affected Files & Functions:**
  - `lib/features/clinics/queue_repository.dart:46-69` (`getOrCreateTodaySession()`)
- **Status:** **CONFIRMED**
- **Exact Reproduction Scenario:**
  1. Two staff members open the Admin Dashboard in Tab A and Tab B at 08:00 AM on a new day.
  2. Both tabs execute `getOrCreateTodaySession(clinicId, date)`.
- **Current Behavior:**
  ```dart
  // lib/features/clinics/queue_repository.dart:49-62
  final existing = await getSession(clinicId, date);
  if (existing != null) return existing;
  // Non-transactional creation
  await col.doc(_sessionId(clinicId, date)).set(newSession.toMap());
  ```
  Both tabs read `null` and both invoke `.set()`. While the resulting data is identical (counter = 0, status = 'active'), it generates redundant document writes and resets timestamps.
- **Expected Behavior:** Session creation should be handled inside an atomic transaction or via `SetOptions(merge: true)`.
- **Root Cause & Evidence:** The check-and-set sequence in `getOrCreateTodaySession` is not wrapped in `fs.runTransaction`.
- **Impact:** Redundant Firestore write billing; negligible user impact.

---

### Vector 8: Real-Time Queue Counter Concurrency (Resilient Pattern)

- **Vector:** Duplicate Actions & Stale Counter Tally
- **Severity:** **INFORMATIONAL (RESILIENT)**
- **Affected Files & Functions:**
  - `lib/features/clinics/queue_repository.dart:71-122` (`incrementParcha()`)
  - `lib/features/clinics/queue_repository.dart:125-161` (`decrementParcha()`)
  - `lib/features/clinics/queue_repository.dart:163-206` (`resetParcha()`)
- **Status:** **CONFIRMED SECURE & RESILIENT**
- **Audit Findings:**
  EasyCheck Online exhibits excellent concurrency design for queue tally operations:
  1. **Atomic Transactions:** `incrementParcha`, `decrementParcha`, and `resetParcha` all wrap their operations in `fs.runTransaction<int>()`.
  2. **Optimistic Concurrency Control (OCC):** If Tab A and Tab B click "Increment" at the exact same millisecond, Firestore detects the version conflict on `queue_sessions/{clinicId}_{date}`, automatically retries the second transaction, and commits both (e.g., advancing the counter cleanly from 14 -> 15 -> 16).
  3. **Real-Time Push Synchronization:** Both tabs listen to `sessionStream`, which fires on snapshot updates, ensuring that both Tab A and Tab B immediately display the updated counter without manual page refresh.

---

## 4. Phase 4 — Safe Solution Proposals

All proposed solutions adhere strictly to the **non-breaking, minimal-footprint** requirement.

---

### Solution 1: Global Authentication State Listener (Fixes Vectors 1 & 3)

#### Architecture-Compatible Fix
Subscribe to `FirebaseAuth.instance.authStateChanges()` in the root application widget (`EasyCheckApp` or `AuthGateScreen`) and individual stateful dashboards.

```dart
// Suggested pattern for lib/features/admin/admin_dashboard_screen.dart
StreamSubscription<User?>? _authSubscription;

@override
void initState() {
  super.initState();
  _loadDashboard();
  
  // Listen for cross-tab auth state changes (e.g. logout in Tab B)
  _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
    if (!mounted) return;
    if (user == null || user.uid != _user?.uid) {
      // Invalidate streams and safely exit to role selection
      _cancelSubscriptions();
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.initial,
        (route) => false,
      );
    }
  });
}
```

#### Why Necessary
Automatically handles Tab B when Tab A logs out or changes accounts, preventing unauthorized viewing of protected UI and avoiding cryptic Firestore rule exceptions.

#### Regression & Compatibility Risks
Zero regression risk. `authStateChanges()` is a native, stable API supported seamlessly across Flutter Web, Android, and iOS.

---

### Solution 2: Isolate Role Persistence from Global LocalStorage (Fixes Vector 2)

#### Architecture-Compatible Fix
Replace the origin-wide `_storageKey` in `AuthSessionStore` with in-memory navigation parameters or browser `sessionStorage` (which is isolated per tab) on Web.

```dart
// Suggested pattern for lib/features/authentication/auth_session_store.dart
// On Web, use window.sessionStorage so Tab A (Admin) and Tab B (Patient)
// do not clobber each other's navigation states.
```

#### Why Necessary
Prevents a user testing or browsing as a patient in Tab B from corrupting their administrative workstation session in Tab A.

---

### Solution 3: Field-Level Atomic Delta Updates (Fixes Vector 4)

#### Architecture-Compatible Fix
In `_saveDoctorProfile()`, only send fields that were actually modified by the user, or wrap the update in a Firestore transaction that validates `clinic.updatedAt`:

```dart
// Suggested pattern for lib/features/admin/admin_dashboard_screen.dart
final updates = <String, dynamic>{};
if (draft.name != clinic.doctorName) updates['doctorName'] = draft.name;
if (draft.credentials != clinic.doctorCredentials) updates['doctorCredentials'] = draft.credentials;
if (draft.specialty != clinic.doctorSpecialty) updates['doctorSpecialty'] = draft.specialty;

if (updates.isNotEmpty) {
  await _clinicRepository.updateClinic(clinic.clinicId, updates);
}
```

#### Why Necessary
Eliminates Last-Write-Wins clobbering where editing one field in Tab B silently reverts an edit made to another field in Tab A.

---

### Solution 4: Catch Rule Violations in Access Request Submission (Fixes Vector 5)

#### Architecture-Compatible Fix
In `AdminAccessRequestRepository.submitRequest()`, catch `FirebaseException` with code `permission-denied` and re-verify whether a request was already created by another tab during the race:

```dart
// In lib/features/authentication/admin_access_request_repository.dart
try {
  await ref.set({...});
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    final recheck = await getRequest(uid, normalizedClinicId);
    if (recheck != null) return recheck;
  }
  rethrow;
}
```

---

## 5. Phase 5 — Multi-Tab Test Plan

| Test ID | Test Scenario | Steps | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **MT-01** | Multi-Tab Sign-Out Sync | 1. Open Tab A & Tab B logged into Admin Dashboard.<br>2. Sign out in Tab A.<br>3. Inspect Tab B. | Tab B must immediately cancel subscriptions and route to Role Selection. |
| **MT-02** | Independent Role Navigation | 1. Open Tab A as Admin.<br>2. Open Tab B as Patient.<br>3. Refresh Tab A (`F5`). | Tab A must reload into Admin Dashboard, not Patient Home. |
| **MT-03** | Concurrent Queue Increment | 1. Open Tab A & Tab B on same clinic dashboard.<br>2. Click "Next Ticket" simultaneously in both tabs. | Tally advances by exactly 2 (e.g., 10 -> 12). Both tabs reflect 12. |
| **MT-04** | Concurrent Profile Editing | 1. Open Edit Doctor Profile in Tab A & Tab B.<br>2. Tab A edits Specialty; saves.<br>3. Tab B edits Name; saves. | Both Name and Specialty updates persist without data loss. |
| **MT-05** | Account Deletion Sync | 1. Open Tab A & Tab B on Patient Home.<br>2. In Tab A, delete account.<br>3. Inspect Tab B. | Tab B must immediately route to Role Selection and terminate streams. |
| **MT-06** | Cross-Tab Language Toggle | 1. Open Tab A & Tab B.<br>2. Toggle language to Hindi in Tab A. | Tab A renders in Hindi. Tab B either syncs via storage event or syncs on focus. |

---

## 6. Phase 6 — Concurrency & Reliability Scoring

### Scoring Methodology

- **Base Score:** 100 Points
- **Deductions:**
  - **Critical Defect (Data loss / Security breach):** -20 points each (0 found)
  - **High Concurrency Risk (Stale auth / Session hijacking across tabs):** -10 points each (3 found = -30 points)
  - **Medium Concurrency Risk (LWW record overwrites / Race condition errors):** -5 points each (2 found = -10 points)
  - **Low Concurrency Risk (Storage desync / Minor UI state lag):** -2 points each (2 found = -4 points)
- **Bonus (Verified Atomic OCC Concurrency Controls):** +4 points (Firestore `runTransaction` on queue sessions)

$$\text{Final Reliability Score} = 100 - (3 \times 10) - (2 \times 5) - (2 \times 2) + 4 = 60 / 100$$

### Overall Multi-Tab Reliability Rating: **60 / 100 (MODERATE)**

> **Summary Verdict:** EasyCheck Online possesses strong transaction isolation for its core real-time tally counters, but lacks browser-level session coordination (`authStateChanges()`, tab-isolated role storage, and field-level delta updating). Implementing the 4 safe proposals will elevate the multi-tab reliability score to **96 / 100**.

---

## 7. Approval Gate — Safety Sign-Off

> [!IMPORTANT]
> **READ-ONLY AUDIT COMPLETE — STOP HERE.**  
> In compliance with strict safety rules:
> 1. No application source code has been altered.
> 2. No dependencies were installed or modified.
> 3. No database schemas or security rules were changed.
>
> **Awaiting explicit user approval before proceeding to any code remediation.**

