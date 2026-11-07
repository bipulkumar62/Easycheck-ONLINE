# Known Issues & Limitations

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 5, 2026

---

## 1. Blocking / High Impact

### 1.1 Super Admin approval backend does not exist

- **Impact:** Clinic access requests remain `pending` indefinitely.
- **Why:** Task 23 explicitly excludes the Super Admin dashboard/backend. Approval and membership provisioning must be done by trusted tooling.
- **Current behavior:** Applicants see the pending screen; no client can approve or reject.
- **Resolution:** Build the Super Admin backend in Task 24 using the Admin SDK and the runbook in `ADMIN_ACCESS_APPROVAL_FLOW.md`.

### 1.2 No initial clinic memberships

- **Impact:** No one can open the admin dashboard yet, including the three seeded clinics’ staff.
- **Why:** Self-claim (`adminClaimCode`) was retired and client membership writes are denied.
- **Resolution:** Provision the first administrator for each clinic in the Firebase Console or with the Admin SDK. See `NEXT_PHASE_READINESS.md`.

### 1.3 Interactive Google sign-in not verified end-to-end

- **Impact:** The agent verified the Google provider configuration and the native Android account picker, but did not complete a real Google account consent flow.
- **Why:** The Pixel_7 emulator has no Google account configured, and the agent cannot enter real Google credentials.
- **Current behavior:** Tapping the patient Google button opens the native Google Identity account picker (`CredentialChooserActivity`), not a browser redirect. The account/consent step remains manual.
- **Resolution:** Perform the manual device test in `TEST_REPORT.md` with a real Google account before sign-off.

---

## 2. Medium Impact

### 2.1 Rejected users cannot re-apply in-app

- **Impact:** A rejected request keeps the deterministic `{uid}_{clinicId}` document, so the client blocks re-submission for that clinic.
- **Current behavior:** The rejected screen offers “Request access for another clinic.”
- **Options:** Backend resets the existing request to `pending`, or a future task adds an audited re-application endpoint.

### 2.2 No Firebase App Check

- **Impact:** The Firebase project relies on Security Rules and provider configuration, not attestation.
- **Resolution:** Add App Check in a later hardening task. Not required for Task 23.

### 2.3 Email/password test accounts no longer available

- **Impact:** Future REST-based security probes cannot create temporary users via the client API because the provider is disabled.
- **Resolution:** Use the Admin SDK with service-account credentials, or create temporary Google test accounts.

### 2.4 Doctor timing manual verification pending

- **Impact:** The model, admin editor, Firestore field and patient rendering are implemented and unit/widget tested, but the full admin-save → patient-sees flow was not exercised with a provisioned admin account.
- **Resolution:** Provision an admin and run the steps in `DOCTOR_TIMING_INTEGRATION.md`.

### 2.5 Play Store submission is not complete

- **Impact:** The signed AAB is ready, but the app is not published.
- **Why:** Play Console still needs the store listing, screenshots, data-safety form, content rating, privacy-policy URL, deletion URL, and reviewer instructions.
- **Current behavior:** The privacy, terms and deletion pages are live and return HTTP 200.
- **Resolution:** Follow `PLAY_STORE_READINESS.md` and upload `build/app/outputs/bundle/release/app-release.aab`.

### 2.6 Play Store reviewers cannot see the doctor flow without provisioning

- **Impact:** A reviewer who signs in as Doctor/Staff will see the access request or pending screen, not the clinic dashboard.
- **Why:** No Super Admin approval backend or initial membership exists yet.
- **Resolution:** Provision a reviewer test admin and provide credentials/instructions in the Play Console review notes. Do not fake approval inside the app.

### 2.7 Account deletion may require a fresh sign-in

- **Impact:** If the Google session is old, Firebase may reject `user.delete()` with `requires-recent-login`.
- **Current behavior:** The app shows a clear message asking the patient to sign out, sign in again and retry.
- **Resolution:** Expected platform security behavior; no client bypass is appropriate.

---

## 3. Low Impact

| Issue | Notes |
|-------|-------|
| Android launcher icon cache | Reinstall the app or clear the launcher cache to see new icons |
| Web hosting is current | The latest web build and legal pages are deployed; redeploy after future UI changes |
| `clinics.adminUid` is a single owner | Additional admins are supported through `clinic_members` |
| Firestore timestamps not exact server time | Timestamps are informational, not authorization |
| No Firebase Emulator integration suite | Rules are verified with a live REST probe instead |
| Role selection always shown | Deliberate product decision; authenticated users still choose a role |
| Google-only sign-in | Users without a Google account cannot sign in; no email/password fallback |
| Release AAB is version 1 | Increment `version` in `pubspec.yaml` before every future Play upload |
| No physical-device test | Verified on Pixel_7 emulator; the user should test on their own phone |

---

## 4. Explicitly Not Implemented

- Super Admin dashboard, approval UI, or Cloud Function.
- Automatic membership creation on approval.
- Email notifications for approval/rejection.
- Audit log collection for Super Admin actions (recommended for Task 24).
- Firebase App Check.
- Multi-clinic switching UI for one user with memberships in several clinics (the service resolves the first active membership).

---

## 5. Things That Are Not Bugs

- Admin dashboard fails closed without a provisioned membership.
- Pending/rejected users are redirected instead of seeing clinic data.
- A signed-in Google account does not automatically become an admin.
- The role selection does not remember the previous choice; it always asks.
- Empty doctor timing hides the patient row.
