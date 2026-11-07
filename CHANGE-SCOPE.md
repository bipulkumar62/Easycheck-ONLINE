# CHANGE-SCOPE.md

## Purpose

This file defines exactly which files, folders, modules, components, services, database objects, configuration files, and other project resources an AI coding agent is allowed to modify for the current task.

The goal is to prevent unnecessary changes, scope creep, accidental regressions, unrelated refactoring, and modifications outside the current task.

---

## 1. CORE RULE

For the current task, ONLY explicitly allowed files/modules/resources may be modified.

Treat this file as a hard change boundary.

Do not assume that a file is allowed to change merely because:
- it is related to the feature
- it imports the affected code
- changing it would be cleaner
- changing it would improve the architecture
- it contains duplicated code
- it has an existing bug
- it is outdated
- the AI believes it should be refactored
- the change would make implementation easier

If a required change falls outside the declared scope, STOP and request approval before modifying it.

---

## 2. CURRENT TASK

**Current task:**
Fix application startup failure (screens not loading / blank screen on boot) and verify all 7 screens against their Stitch designs (3 Patient screens + 4 Admin screens), ensuring lint and build validation pass without regressions.

**Task objective:**
1. Ensure the app boots reliably without crashing on launch if Firebase initialization encounters errors or if running in offline/unsupported environments.
2. Resolve `flutter analyze` warnings/lint issues in `lib/app/app.dart`, `lib/features/patient/patient_home_screen.dart`, and `lib/features/authentication/admin_login_screen.dart`.
3. Verify all 7 screens conform to the design systems:
   - Patient Screen 01 (Google Login): `stitch_easycheck_clinic_mobile_ui/google_login_easycheck_online/code.html`
   - Patient Screen 02 (Home): `stitch_easycheck_clinic_mobile_ui/home_easycheck_online/code.html`
   - Patient Screen 03 (Clinic Details): `stitch_easycheck_clinic_mobile_ui/clinic_details_easycheck_online/code.html`
   - Admin Screen 01 (Login): `stitch_easycheck_clinic_admin/google_authentication/code.html`
   - Admin Screen 02 (Dashboard): `stitch_easycheck_clinic_admin/clinic_admin_dashboard/code.html`
   - Admin Screen 03 (Reset Studio): `stitch_easycheck_clinic_admin/reset_confirmation_account_state/code.html`
   - Admin Screen 04 (Unauthorized): `stitch_easycheck_clinic_admin/unauthorized_security_states/code.html`
4. Confirm successful Android build with `flutter build apk --debug` and clean `flutter analyze`.

---

## 3. ALLOWED CHANGE SCOPE

The following resources are explicitly allowed to be modified:

### Files
- `CHANGE-SCOPE.md`
- `lib/main.dart`
- `lib/app/app.dart`
- `lib/features/patient/patient_home_screen.dart`
- `lib/features/authentication/admin_login_screen.dart`

### Directories
- `lib/app/` (only `app.dart`)
- `lib/features/patient/` (only `patient_home_screen.dart`)
- `lib/features/authentication/` (only `admin_login_screen.dart`)

### Modules / Components / Services
- App bootstrap and safe Firebase initialization handling
- Unused import / declaration cleanup in scoped screens
- Public API typing for `ClinicData` in `patient_home_screen.dart`

### Database Resources
- None (read-only)

### API Resources
- None (read-only)

### Configuration / Infrastructure
- None (pubspec.yaml, android configuration, etc. remain unchanged)

---

## 4. EVERYTHING OUTSIDE THE SCOPE IS READ-ONLY

Any resource not explicitly allowed above must be treated as read-only.
This includes:
- `pubspec.yaml` and `pubspec.lock`
- `lib/firebase_options.dart`
- `lib/core/` (all files)
- `lib/shared/` (all files)
- `lib/features/admin/` (all existing files)
- `android/` native files

---

## 5. DEPENDENCY RULE

If a change is required outside this scope:
1. Identify the required external file/resource.
2. Explain why it must change.
3. Explain what would break if it is not changed.
4. Show the exact proposed change.
5. STOP and ask for approval.

---

## 6. MINIMAL CHANGE PRINCIPLE

Make the smallest change required to correctly complete the task.
Do not refactor working code or change styling arbitrarily.
Prefer: «Minimum necessary change + complete task correctness + no unrelated modifications.»

---

## 7. SCOPE VALIDATION CHECKLIST

Before modifying:
- [x] Read CHANGE-SCOPE.md
- [x] Identify exact target files inside allowed list
- [x] Inspect dependencies without modifying them
- [x] Verify no unauthorized file is touched
