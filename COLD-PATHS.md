# COLD-PATHS.md — EasyCheck Online Cold Path Analysis

## 1. Purpose

This document provides a comprehensive, repository-wide inventory and architectural analysis of **cold execution paths** across the **EasyCheck Online** codebase (Flutter + Cloud Firestore + Firebase Authentication).

### Why Cold Paths Matter
Cold paths represent source code, routes, branches, exception handlers, and fallback mechanisms that execute rarely, conditionally, or under anomalous circumstances rather than during typical user happy-path journeys. Because these paths are seldom traversed during routine development, they are disproportionately prone to:
- **Bitrot & Stale Contracts:** Data schemas mutating without updating seldom-used error recovery or admin screens.
- **Cascading Failures:** Unhandled edge cases in fallback branches causing silent UI freezes or unrecoverable exception loops.
- **Security & Authorization Bypasses:** Rare administrative or elevation routes left unprotected or inconsistent with Firestore Security Rules.
- **Accidental Premature Deletion:** Developers mistaking rarely executed disaster-recovery, offline-mode, or audit logic for dead code.

---

## 2. Repository Context

- **Application:** EasyCheck Online (`easycheck_online`)
- **Technology Stack:** Flutter (SDK `^3.13.0`), Dart (SDK `^3.5.0`), Cloud Firestore (`^7.1.0`), Firebase Auth (`^7.0.1`), Google Sign-In (`^7.2.0`), `flutter_dotenv` (`^6.0.1`).
- **Target Platforms:** Android (primary production target via Gradle), Web (configured via Firebase Hosting).
- **Core Architecture:**
  - **Presentation Layer:** Dual design system ("Clinical Clarity" for patients, "Clinical Precision" for clinic staff/administrators) routed through [`lib/app/app.dart`](file:///d:/Easycheck%20ONLINE/lib/app/app.dart) via `RoleSelectionScreen`.
  - **Authentication & Security:** Real Google OAuth via Credential Manager / Google Sign-In, gated by [`AuthGateScreen`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/auth_gate_screen.dart) and server-backed [`AdminAccessService`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_access_service.dart).
  - **Data Layer:** Cloud Firestore repositories (`ClinicRepository`, `QueueRepository`, `UserProfileRepository`, `ClinicMembershipRepository`, `AdminAccessRequestRepository`).
- **Scanned Modules:** All 36 Dart source files under `lib/`, native Android build files (`build.gradle.kts`, `AndroidManifest.xml`), configuration files (`.env`, `firebase.json`, `firestore.rules`), and test files under `test/`.

---

## 3. Cold Path Classification

| Category | Definition | Repository Relevance |
| :--- | :--- | :--- |
| **Rarely Used Features** | Valid features accessed only under specific user actions or edge conditions | Account deletion, legal modals, staff access requests, helpdesk dialogs. |
| **Optional Functionality** | Modules that execute only when explicitly configured or navigated | Reset studio preview scenarios, doctor timing editor dialogs. |
| **Fallback Paths** | Alternative execution triggered when primary subsystems are unavailable | Firebase offline UI-only mode, `.env` loading fallbacks, route argument fallbacks. |
| **Error Recovery Paths** | Exception handlers, retry handlers, and failure boundary controllers | Google Sign-In cancellation mapping, `runZonedGuarded`, network retry logic. |
| **Admin-Only Paths** | Privileged workflows restricted to authorized staff/doctors | Queue increment/decrement/reset, clinic online toggles, access requests. |
| **Feature-Flagged Paths** | Logic conditioned on runtime flags or operational states | Clinic `isActive` / `isOnline` toggling, reduced-motion accessibility flags. |
| **Scheduled & Lazy Paths** | Periodic or on-demand operations not tied to continuous user interactions | Daily queue session creation (lazy on-demand date rollover). |
| **Conditional Paths** | Deep branches triggered by specific data shapes or route arguments | `toDisplayModel()` status mapping, search string filtering, route argument casting. |
| **Legacy & Dead Paths** | Superseded, unreferenced, or orphaned classes/methods | Uncalled repository CRUD helpers, unused UI widgets, unlinked studio routes. |

---

## 4. Confirmed Cold Paths

### 4.1 Account Deletion Workflow
- **Path:** [`lib/features/patient/patient_home_screen.dart#L185-L224`](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart#L185-L224) → `_confirmDeleteAccount()`
- **Trigger Condition:** User navigates to Settings tab in `PatientHomeScreen` and explicitly confirms permanent account deletion.
- **Execution Mechanism:**
  1. Prompts modal confirmation dialog.
  2. Calls `_profileRepository.deleteProfile(user.uid)` (deletes `users/{uid}` in Firestore).
  3. Calls `user.delete()` in Firebase Authentication.
  4. Redirects to `AppRoutes.initial` with `pushNamedAndRemoveUntil`.
- **Classification Reason:** High-impact, irreversible lifecycle action performed rarely by patients.
- **Dependencies:** [`UserProfileRepository.deleteProfile`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/user_profile_repository.dart#L117), `FirebaseAuth.currentUser.delete()`.
- **Failure Impact:** If `FirebaseAuthException` occurs with code `requires-recent-login`, the user must be prompted to re-authenticate before retrying. If Firestore rules forbid deletion, account remains partially orphaned.
- **Evidence:** `patient_home_screen.dart:185-224`, `user_profile_repository.dart:117-127`.

---

### 4.2 Clinic Staff Access Elevation & Approval Journey
- **Paths:**
  - [`lib/features/authentication/admin_access_request_screen.dart#L90-L165`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_access_request_screen.dart#L90-L165) → `_submit()`
  - [`lib/features/authentication/admin_pending_approval_screen.dart`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_pending_approval_screen.dart) → `AdminPendingApprovalScreen`
  - [`lib/features/authentication/admin_rejected_screen.dart`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_rejected_screen.dart) → `AdminRejectedScreen`
  - [`lib/features/authentication/admin_request_submitted_screen.dart`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_request_submitted_screen.dart) → `AdminRequestSubmittedScreen`
  - [`lib/features/authentication/admin_unauthorized_screen.dart`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_unauthorized_screen.dart) → `AdminUnauthorizedScreen`
- **Trigger Condition:** User signs in as "Doctor/Staff" but has no existing active clinic membership in `clinic_members`.
- **Execution Mechanism:**
  1. [`AuthGateScreen#L105-L107`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/auth_gate_screen.dart#L105-L107) calls `AdminAccessService.resolve(user)`.
  2. If resolution is `none` → navigates to `adminAccessRequest` to select clinic and submit justification.
  3. If resolution is `pending` → navigates to `adminPendingApproval` with refresh and sign-out controls.
  4. If resolution is `rejected` → navigates to `adminRejected` displaying review rejection reason.
  5. If resolution is `inconsistent` → navigates to `adminUnauthorized` asking user to contact admin.
- **Classification Reason:** Traversed only during first-time clinic staff onboarding or authorization state transitions.
- **Dependencies:** [`AdminAccessRequestRepository`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_access_request_repository.dart), [`AdminAccessService`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_access_service.dart), Firestore collection `admin_access_requests`.
- **Failure Impact:** If request submission fails or validation fails (`CLN-XXXXX` regex), staff cannot onboard and cannot access the admin dashboard.
- **Evidence:** `auth_gate_screen.dart:119-157`, `admin_access_service.dart:71-130`.

---

### 4.3 End-of-Day Parchi Tally Reset
- **Path:** [`lib/features/admin/admin_dashboard_screen.dart#L268-L286`](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L268-L286) → `_confirmReset()`
- **Trigger Condition:** Clinic receptionist/administrator taps "Reset Counter" action button in the dashboard and confirms reset dialog.
- **Execution Mechanism:**
  1. Displays modal warning confirming daily parchi count reset.
  2. Executes [`QueueRepository.resetParcha(clinicId, dateKey, uid)`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L163) inside an atomic Firestore transaction.
  3. Records audit entry in `queue_history` collection with action `'reset'`.
  4. Updates UI state to `_count = 0`.
- **Classification Reason:** Executed at most once per operating day per clinic, outside typical token issuance flow.
- **Dependencies:** `QueueRepository.resetParcha`, Cloud Firestore transaction on `queue_sessions/{clinicId}_{date}`.
- **Failure Impact:** If Firestore transaction fails or network is disconnected, queue remains at current count; audit log entry is not written.
- **Evidence:** `admin_dashboard_screen.dart:270-286`, `queue_repository.dart:163-206`.

---

### 4.4 Doctor Operating Timing & Schedule Update
- **Path:** [`lib/features/admin/admin_dashboard_screen.dart#L312-L365`](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L312-L365) → `_editDoctorTiming()` & `_saveDoctorTiming()`
- **Trigger Condition:** Clinic admin taps edit button on doctor timing card in dashboard.
- **Execution Mechanism:**
  1. Opens modal dialog with pre-populated timing string.
  2. Sanitizes input and updates `clinics/{clinicId}` with `{'doctorTiming': timing}` via [`ClinicRepository.updateClinic`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_repository.dart#L49).
  3. Propagates changes in real-time to patient clinic details cards via Firestore stream.
- **Classification Reason:** Infrequent administrative metadata update.
- **Dependencies:** `ClinicRepository.updateClinic`, Firestore `clinics` collection.
- **Failure Impact:** If update fails, outdated clinic hours remain rendered to patients.
- **Evidence:** `admin_dashboard_screen.dart:312-365`.

---

### 4.5 Legal Documents Bottom Sheet Modal
- **Path:** [`lib/features/legal/legal_screen.dart`](file:///d:/Easycheck%20ONLINE/lib/features/legal/legal_screen.dart) → `LegalScreen`
- **Trigger Condition:** User taps "Privacy Policy" or "Terms of Service" links on `RoleSelectionScreen`, `PatientLoginScreen`, `AdminLoginScreen`, or `PatientHomeScreen`.
- **Execution Mechanism:** Invokes `showModalBottomSheet(context: ..., builder: (_) => LegalScreen(document: LegalDocument.privacyPolicy / termsOfService))`.
- **Classification Reason:** Ancillary compliance screen accessed rarely during initial exploration.
- **Dependencies:** Static legal text data in `legal_screen.dart`.
- **Failure Impact:** Low; purely informational UI display.
- **Evidence:** `patient_login_screen.dart:94`, `admin_login_screen.dart:859`, `role_selection_screen.dart:250`, `patient_home_screen.dart:1052`.

---

## 5. Potential Cold Paths

### 5.1 Clinic Search Query Filtering
- **Path:** [`lib/features/patient/patient_home_screen.dart#L125-L138`](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart#L125-L138) → `get _filtered`
- **Trigger Condition:** Patient types into the search bar (`_searchQuery.isNotEmpty`).
- **Execution Condition:** Filters in-memory clinic list against clinic name, address, city, doctor name, and specialty.
- **Why Potential Cold Path:** When the search input is empty (default state on launch), `_filtered` returns `_clinics` directly without executing string normalization and multi-field substring matching loops.
- **Evidence:** `patient_home_screen.dart:125-138`.

---

### 5.2 Doctor Leave / Delay Status Propagation
- **Path:** [`lib/features/clinics/clinic_model.dart#L153-L178`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_model.dart#L153-L178) → `toDisplayModel()` switch branches
- **Trigger Condition:** Clinic administrator sets doctor status to `'delayed'` or `'offDuty'` in `AdminDashboardScreen._setDoctorStatus()`.
- **Execution Condition:**
  - Case `'delayed'`: maps to `ClinicStatus.delayed` and `DoctorStatus.delayed`.
  - Case `'offDuty'`: maps to `ClinicStatus.unavailable` and `DoctorStatus.offDuty`.
- **Why Potential Cold Path:** Most clinics operate in normal `'available'` status; delay and leave notices are conditional exception states.
- **Evidence:** `clinic_model.dart:154-177`, `admin_dashboard_screen.dart:288-310`.

---

### 5.3 Reduced Motion Accessibility Mode
- **Path:** [`lib/core/widgets/live_dot.dart#L52-L65`](file:///d:/Easycheck%20ONLINE/lib/core/widgets/live_dot.dart#L52-L65) → `_syncAnimation()`
- **Trigger Condition:** Android OS setting "Remove animations" / "Reduced motion" is enabled on the client device.
- **Execution Condition:** `MediaQuery.maybeOf(context)?.disableAnimations` evaluates to `true`.
- **Why Potential Cold Path:** The `AnimationController.repeat(reverse: true)` loop is halted and reset to static 0 only on devices with accessibility motion reduction enabled.
- **Evidence:** `live_dot.dart:52-65`.

---

## 6. Fallback and Recovery Paths

### 6.1 Application Startup Firebase Absence Fallback
- **Path:** [`lib/main.dart#L16-L20`](file:///d:/Easycheck%20ONLINE/lib/main.dart#L16-L20)
- **Trigger:** `Firebase.initializeApp` throws an exception (e.g. running in headless unit tests, missing `google-services.json`, or unsupported platform).
- **Behavior:** The `catch (_)` block absorbs the failure silently. The app boots into UI-only mode without crashing.
- **Downstream Impact:** Repositories (`ClinicRepository._fs`, `QueueRepository._fs`, `UserProfileRepository._fs`) detect `Firebase.apps.isEmpty` and return empty streams or throw descriptive `ServerFailure` messages instead of raw platform crashes.
- **Evidence:** `main.dart:16-20`, `test/widget_test.dart:29-37`.

---

### 6.2 Global Uncaught Asynchronous Error Handler
- **Path:** [`lib/main.dart#L22-L26`](file:///d:/Easycheck%20ONLINE/lib/main.dart#L22-L26)
- **Trigger:** An unhandled asynchronous exception escapes the Flutter framework event loop.
- **Behavior:** Captured by `runZonedGuarded` error handler: `(Object error, StackTrace stackTrace) { debugPrint('Uncaught error: $error'); }`.
- **Downstream Impact:** Prevents process-level native crash; prints error to console.
- **Evidence:** `main.dart:22-26`.

---

### 6.3 Environment Configuration Asset Missing Fallback
- **Path:** [`lib/core/config/env_config.dart#L9-L15`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L9-L15)
- **Trigger:** `.env` asset file is missing from bundle, corrupt, or unreadable.
- **Behavior:** Catches load exception; all `EnvConfig` getters fall back to compile-time flags (`String.fromEnvironment`) or hardcoded defaults.
- **Evidence:** `env_config.dart:9-15`.

---

### 6.4 Route Arguments Missing / Type Mismatch Fallback
- **Path:** [`lib/app/app.dart#L60-L71`](file:///d:/Easycheck%20ONLINE/lib/app/app.dart#L60-L71)
- **Trigger:** `Navigator.pushNamed(context, AppRoutes.patientClinicDetails)` is called without passing a valid `ClinicModel` in `arguments`.
- **Behavior:** If `arguments` is neither `display_clinic.ClinicModel` nor `firestore_clinic.ClinicModel`, the route builder falls back to returning `const PatientHomeScreen()`.
- **Evidence:** `app.dart:60-71`.

---

### 6.5 Google Sign-In Provider Fallback
- **Path:** [`lib/features/authentication/google_auth_service.dart#L52-L61`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/google_auth_service.dart#L52-L61)
- **Trigger:** Device or platform does not support native Credential Manager authentication (`!GoogleSignIn.instance.supportsAuthenticate()`).
- **Behavior:** Bypasses native account picker and delegates to Firebase Auth's provider popup/redirect flow (`auth.signInWithProvider(GoogleAuthProvider())`).
- **Evidence:** `google_auth_service.dart:52-61`.

---

### 6.6 Authentication Error Code Mapping & User Recovery
- **Path:** [`lib/features/authentication/auth_error_mapper.dart#L13-L83`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/auth_error_mapper.dart#L13-L83)
- **Trigger:** Firebase Auth or Google Sign-In throws an exception during authentication.
- **Behavior:** Maps granular technical codes (`popup-closed-by-user`, `network-request-failed`, `user-disabled`, `too-many-requests`, `invalid-credential`, `clientConfigurationError`, etc.) into non-alarming, actionable user guidance without leaking backend internals.
- **Evidence:** `auth_error_mapper.dart:13-83`.

---

### 6.7 Network Stream Disconnection Graceful Counter Fallback
- **Path:** [`lib/features/clinic/clinic_details_screen.dart#L47-L49`](file:///d:/Easycheck%20ONLINE/lib/features/clinic/clinic_details_screen.dart#L47-L49)
- **Trigger:** Firestore real-time stream subscription on `queue_sessions/{clinicId}_{today}` emits an error due to connectivity interruption.
- **Behavior:** The `onError: (_)` handler leaves `_liveCount` unchanged, allowing `_displayCount` to gracefully fall back to the last known count or the clinic profile's baseline tally.
- **Evidence:** `clinic_details_screen.dart:47-49, 58`.

---

### 6.8 Brand Mark Asset Error Fallback
- **Path:** [`lib/core/widgets/brand_mark.dart#L53-L58`](file:///d:/Easycheck%20ONLINE/lib/core/widgets/brand_mark.dart#L53-L58)
- **Trigger:** Logo asset image fails to load from bundle.
- **Behavior:** `Image.asset.errorBuilder` renders a medical cross fallback icon (`Icons.local_hospital_rounded`).
- **Evidence:** `brand_mark.dart:53-58`.

---

## 7. Feature Flags and Optional Modules

### 7.1 Clinic Operational Availability Flag (`isOnline`)
- **Location:** [`lib/features/clinics/clinic_model.dart:16`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_model.dart#L16), [`admin_dashboard_screen.dart:295`](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L295).
- **Behavior:** When `isOnline == false`, the clinic is rendered as offline/closed on patient screens, and parchi token updates are paused.
- **Activation:** Toggled by clinic administrators in `AdminDashboardScreen._setDoctorStatus()`.

---

### 7.2 Clinic Master Activation Flag (`isActive`)
- **Location:** [`firestore.rules:78`](file:///d:/Easycheck%20ONLINE/firestore.rules#L78), [`clinic_repository.dart:73`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_repository.dart#L73).
- **Behavior:** Only clinics with `isActive == true` are queryable by authenticated patients. Deactivating a clinic immediately removes it from discovery feeds across all devices.

---

### 7.3 Membership Activation Flag (`isActive`)
- **Location:** [`lib/features/clinics/clinic_membership_model.dart:10`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_membership_model.dart#L10), [`admin_access_service.dart:76`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_access_service.dart#L76).
- **Behavior:** If a staff member's record in `clinic_members` has `isActive == false`, `AdminAccessService` blocks dashboard access and routes to `AdminUnauthorizedScreen`.

---

## 8. Background and Scheduled Execution

### 8.1 Daily Queue Session On-Demand Rollover
- **Path:** [`lib/features/clinics/queue_repository.dart#L46-L69`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L46-L69) → `getOrCreateTodaySession(clinicId, date)`
- **Nature of Execution:** **Lazy On-Demand Rollover (Not a Cron Job)**.
- **Trigger:** First time a clinic administrator opens `AdminDashboardScreen` on any calendar day (`YYYY-MM-DD`).
- **Mechanism:**
  1. Checks if document `queue_sessions/{clinicId}_{date}` exists.
  2. If missing, automatically creates a new session document initialized with `currentParchaNumber: 0` and `status: 'active'`.
- **Cold Path Characteristic:** Executes exactly once per day per active clinic. If no staff opens the dashboard, the document is not initialized until accessed.
- **Evidence:** `admin_dashboard_screen.dart:150-153`, `queue_repository.dart:46-69`.

---

## 9. Legacy, Orphaned, and Potentially Dead Code

The following components exist in the repository but have zero incoming references from production execution flows:

| Component / Function | File Location | Intended Purpose | Current Reference Status | Risk / Recommendation |
| :--- | :--- | :--- | :--- | :--- |
| `AppUtils.formatTokenSequence` | [`lib/core/utils/app_utils.dart:6-8`](file:///d:/Easycheck%20ONLINE/lib/core/utils/app_utils.dart#L6-L8) | Formats token int to `"Seq: P-012"` | **0 callers** in `lib/` and `test/` | Safe utility; retain for future token printing / receipt features. |
| `AdminUserModel` | [`lib/shared/models/clinic_model.dart:47-63`](file:///d:/Easycheck%20ONLINE/lib/shared/models/clinic_model.dart#L47-L63) | Mock admin profile model from Stitch prototype | **0 callers**; superseded by `UserProfile` | Retain; do not remove without deprecation notice. |
| `StatusButton` | [`lib/shared/widgets/shared_widgets.dart:82-134`](file:///d:/Easycheck%20ONLINE/lib/shared/widgets/shared_widgets.dart#L82-L134) | Status toggle button widget | **0 callers** in `lib/` and `test/` | Dead UI component; retain or consolidate into design system. |
| `LiveStatusPill` | [`lib/shared/widgets/shared_widgets.dart:6-51`](file:///d:/Easycheck%20ONLINE/lib/shared/widgets/shared_widgets.dart#L6-L51) | Alternative status pill widget | **0 callers**; screens use `StatusPill` from `core/` | Superseded by `lib/core/widgets/status_pill.dart`. |
| `AdminResetStudioScreen` | [`lib/features/admin/admin_reset_studio_screen.dart`](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_reset_studio_screen.dart) | Prototype scenario testing studio | Route `/admin/reset-studio` registered in `app.dart:76` & tested in `widget_test.dart:300`, but **0 screens navigate to it** | **Orphaned Route**. Keep as internal debug/QA harness; do not delete. |
| `ClinicRepository.createClinic` | [`lib/features/clinics/clinic_repository.dart:39`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_repository.dart#L39) | Creates clinic document in Firestore | **0 callers** in UI (clinics created via Console) | Retain for Super Admin portal. |
| `ClinicRepository.clinicStream` | [`lib/features/clinics/clinic_repository.dart:60`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_repository.dart#L60) | Stream single clinic document | **0 callers** in UI (screens use active stream or getClinic) | Retain for individual clinic listeners. |
| `ClinicRepository.isClinicActive` & `isClinicOnline` | [`lib/features/clinics/clinic_repository.dart:95, 107`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_repository.dart#L95) | One-shot boolean status checks | **0 callers** in UI | Retain for background sanity checks. |
| `ClinicMembershipRepository.createMembership`, `updateMembership`, `deactivateMembership`, `hasPermission` | [`lib/features/clinics/clinic_membership_repository.dart:41, 53, 98, 109`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_membership_repository.dart#L41) | Full CRUD for staff memberships | **0 callers** in UI (memberships provisioned via backend/Console) | Retain for future staff management screen. |
| `UserProfileRepository.createProfile`, `updateProfile`, `profileStream`, `profileExists` | [`lib/features/authentication/user_profile_repository.dart:90, 101, 130, 140`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/user_profile_repository.dart#L90) | Generic user profile CRUD | **0 callers**; superseded by atomic `ensurePatientProfile` | Retain; useful for profile editing extensions. |
| `QueueRepository.getHistory`, `activeSessionsStream`, `updateSessionStatus`, `getSession` | [`lib/features/clinics/queue_repository.dart:23, 208, 236, 274`](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L23) | Batch queue session/history queries | **0 callers** in UI (screens use stream variants) | Retain for dashboard reporting. |

---

## 10. Dependencies and Impact Analysis

```
                              [RoleSelectionScreen]
                                       │
                      ┌────────────────┴────────────────┐
                      ▼                                 ▼
             [PatientLoginScreen]              [AdminLoginScreen]
                      │                                 │
                      └────────────────┬────────────────┘
                                       ▼
                              [AuthGateScreen] ◄── [GoogleAuthService / Firebase Auth]
                                       │
                      ┌────────────────┴────────────────┐
                      ▼                                 ▼
              (Role: Patient)                    (Role: Admin)
                      │                                 │
                      ▼                                 ▼
           [UserProfileRepository]             [AdminAccessService]
         (ensurePatientProfile)                         │
                      │                   ┌─────────────┼─────────────┐
                      ▼                   ▼             ▼             ▼
             [PatientHomeScreen]      (Approved)    (Pending)     (Rejected)
                      │                   │             │             │
                      ▼                   ▼             ▼             ▼
           [ClinicDetailsScreen]    [AdminDashboard]  [Pending]   [Rejected]
                                          │
                                          ▼
                                 [QueueRepository]
                               (increment/reset/stream)
```

### Critical Cross-Cutting Impacts
1. **Authentication Gate Dependency (`AuthGateScreen`):**
   - Every single authenticated patient and staff journey passes through `AuthGateScreen`.
   - If `AdminAccessService.resolve()` encounters an unhandled Firestore exception, the user is diverted into the error recovery cold path (`_buildError()`).
2. **Transactional Queue Counter Integrity (`QueueRepository`):**
   - Counter increments and resets execute inside `runTransaction`.
   - Modifying transaction preconditions in `QueueRepository` without updating `firestore.rules` will cause silent rollback failures in production.
3. **Account Deletion Cascade:**
   - Deleting a patient profile removes the `users/{uid}` document and deletes the `FirebaseAuth` record. It deliberately preserves historical `queue_history` audit records to prevent breaking daily clinic tally reports.

---

## 11. Verification Gaps

The following behaviors cannot be validated through static code analysis alone and require runtime telemetry or emulator test verification:

1. **`QueueRepository.resetParcha()` vs. Firestore Security Rules:**
   - *Status:* **Requires Runtime Rules Emulator Verification**
   - *Detail:* In [`firestore.rules:142`](file:///d:/Easycheck%20ONLINE/firestore.rules#L142), the update rule requires `request.resource.data.currentParchaNumber == resource.data.currentParchaNumber + 1`. Calling `resetParcha()` resets `currentParchaNumber` to `0`. If deployed with this rule active, client-side reset operations will trigger a runtime `PERMISSION_DENIED` exception.
2. **Physical Device Google Sign-In Credential Manager Availability:**
   - *Status:* **Requires Physical Device Testing**
   - *Detail:* Whether `GoogleSignIn.instance.supportsAuthenticate()` resolves to `true` or falls back to `signInWithProvider` depends on the Google Play Services version on the target Android handset.
3. **Account Re-Authentication on Deletion:**
   - *Status:* **Requires User Session Testing**
   - *Detail:* If a user remains signed in for more than 5 minutes before tapping "Delete Account", Firebase Auth may throw `requires-recent-login`. The error message is handled, but requires end-to-end user confirmation.

---

## 12. Safety Recommendations

1. **Preserve All Uncalled Repository Methods:**
   - Do **not** delete uncalled methods in `ClinicRepository`, `ClinicMembershipRepository`, `QueueRepository`, or `UserProfileRepository`. They represent domain boundary APIs necessary for future admin tools and super-admin portals.
2. **Retain `AdminResetStudioScreen` as Internal Harness:**
   - The route `/admin/reset-studio` should not be purged; it serves as a valuable visual regression and scenario testing surface.
3. **Synchronize Firestore Security Rules for Queue Reset:**
   - Update `firestore.rules` on `queue_sessions` to explicitly permit authorized staff with `reset_tally` permission to set `currentParchaNumber = 0`.
4. **Implement Automated Logging on Fallback Catch Blocks:**
   - Replace empty `catch (_)` blocks in `EnvConfig.initialize()` and `GoogleAuthService.signOut()` with non-fatal telemetry or structured debug logs to ensure silent degradation is detectable in production.

---

## 13. Analysis Limitations

1. **Static Analysis Boundary:** Analysis was performed strictly on static code references without executing live Firebase mutations against production databases.
2. **External Cloud Functions Absence:** The repository contains no server-side Cloud Functions or Admin SDK backend code; all operations are direct client-to-Firestore interactions.
3. **Operating System Specifics:** Analysis inspected Android native Gradle configurations; iOS or desktop native configurations were not evaluated as Android is the primary declared MVP target.

---

## 14. Last Analysis

- **Analysis Timestamp:** 2026-11-06T12:41:00Z
- **Auditor Role:** Senior Software Architect & Repository Analyst
- **Scope:** Complete repository inspection (`lib/`, `test/`, `android/`, configurations, and project documentation)
- **Status:** All findings verified against current repository source code.

