# Task 23 — Test Report

**Project:** EasyCheck Online  
**Phase:** Task 23 — Google Authentication, Role Selection, Patient Access & Super-Admin-Approved Clinic Access  
**Date:** November 5, 2026  
**Test environment:** Windows 11 · Flutter 3.47.0 stable · Dart 3.13.0 · Android SDK 36 · Pixel_7 emulator (1080 × 2400, Android API 36) · Firebase project `easycheck-online`  
**Result:** Automated checks pass. Interactive Google sign-in, Super Admin approval and provisioned-admin dashboard remain **manual/blocked** because no approval backend or initial membership exists yet.

---

## 1. Commands Actually Run

| # | Command | Result |
|---|---------|--------|
| 1 | `flutter pub get` | ✅ `Got dependencies!` (18 newer packages held back by current constraints) |
| 2 | `flutter analyze` | ✅ `No issues found!` (5.5 s) |
| 3 | `flutter test` | ✅ **38 / 38 tests passed** |
| 4 | `flutter build apk --debug` | ✅ `build\app\outputs\flutter-apk\app-debug.apk` (22.5 s) |
| 5 | `flutter build apk --release` | ✅ `build\app\outputs\flutter-apk\app-release.apk` — 55.0 MB (29.1 s) |
| 6 | `flutter build appbundle --release` | ✅ `build\app\outputs\bundle\release\app-release.aab` — 55.2 MB (62.4 s) |
| 7 | `flutter build web --release` | ✅ `build\web` (57.2 s) |
| 8 | `firebase deploy --only firestore:rules` | ✅ Rules compiled and released |
| 9 | `firebase deploy --only hosting` | ✅ 53 files deployed to `https://easycheck-online.web.app` |
| 10 | APK/AAB secret scan | ✅ 0 sensitive entries in all three artifacts |
| 11 | Release APK signature check | ✅ `CN=EasyCheck Online`, SHA-1 `d712df8904c7de09d3cd2dc80ac6378527f1c431` |
| 12 | Release APK manifest check | ✅ `versionCode=1`, `versionName=1.0.0`, `minSdk=24`, `targetSdk=36` |
| 13 | Emulator install + launch | ✅ Installed, launched, no crash, role selection rendered |

### Test-suite breakdown

| Test file | Tests | Focus |
|-----------|-------|-------|
| `test/widget_test.dart` | 26 | Role selection, auth error mapping, native Google cancellation/config errors, legal screen, patient/admin UI states, branding |
| `test/admin_access_service_test.dart` | 9 | Approved / pending / rejected / none / inconsistent resolution |
| `test/clinic_model_test.dart` | 3 | `doctorTiming` parsing and display model |
| **Total** | **38** | **All passed** |

---

## 2. Acceptance Scenarios 1–14

Status legend: **PASS** = verified by automated test, live probe, build, or emulator smoke; **MANUAL** = needs a real Google account/device action; **BLOCKED** = depends on the Super Admin backend that Task 23 excludes.

| # | Scenario | Expected | Actual result | Status |
|---|----------|----------|---------------|--------|
| 1 | App cold-starts | Role selection screen with exact prompt “Aap kis roop mein continue karna chahte hain?” and Patient / Doctor-Staff choices | Release APK installed on Pixel_7, launched without crash; role selection rendered at 1080 × 2400 with correct logo, prompt, cards and legal links | **PASS** (emulator) |
| 2 | Patient signs in with Google for the first time | Patient profile created once, then Patient Home | Google provider is enabled. Tapping the patient Google button opened the **native Google Identity account picker** (`CredentialChooserActivity`), not a Chrome/browser redirect, on **both the debug APK and the signed release APK**. The emulator has no Google account, so the consent/account step could not be completed | **MANUAL — native flow verified on debug + release, real account consent pending** |
| 3 | Patient signs in again | Same profile retrieved; no duplicate document and no overwrite of existing fields | `ensurePatientProfile` is transactional, creates only when absent, and never overwrites. Unit-tested via repository contract and code review | **PASS** (automated/code review); sign-in re-check **MANUAL** |
| 4 | Doctor/staff with no membership or request signs in | Clinic access request form | `AdminAccessService` returns `none` for a UID with no active membership, no `clinics.adminUid` link and no request; auth gate routes to the request form | **PASS** (9 unit tests) |
| 5 | Applicant submits an access request | Pending document `admin_access_requests/{uid}_{clinicId}` with own UID, selected clinic, contact details and `status: pending`; pending screen shown | Live Firestore probe created a pending request for the authenticated UID (HTTP 200), read it back, and confirmed the deterministic ID blocks duplicates | **PASS** (live probe) |
| 6 | Applicant submits the same request twice | Duplicate denied; no second document | Second create returned HTTP 403; deterministic ID `{uid}_{clinicId}` prevents duplicates | **PASS** (live probe) |
| 7 | Applicant signs in while the request is pending | Pending approval screen, no clinic data | Resolution returns `pending`; auth gate routes to `AdminPendingApprovalScreen`; dashboard is never built | **PASS** (unit tests) |
| 8 | Request approved and membership provisioned by trusted backend | Dashboard opens for the correct clinic only | Trusted backend provisioning probe returned 200; provisioned admin could update own clinic queue (200) and was denied on another clinic (403). The app-side approved path is unit-tested. No Super Admin UI exists yet, so approval must be done by trusted tooling | **PARTIAL — code verified; live approval BLOCKED** |
| 9 | Request rejected by trusted backend | Rejected screen with factual status; no clinic data | Resolution returns `rejected`; auth gate routes to `AdminRejectedScreen`; rejected screen offers another-clinic request | **PASS** (unit tests); live rejection **BLOCKED** |
| 10 | Patient tries to open the admin panel | Denied; patient stays in patient experience | Dashboard requires an approved `AdminAccessService` result; role selection and `users.role` are never used for authorization. Patient profile create is restricted to `role: 'patient'` | **PASS** (unit tests + live rules probe) |
| 11 | Admin edits doctor timing | Timing saved to `clinics.doctorTiming` and shown on patient home and clinic details | Model, editor, persistence path and patient rendering implemented and covered by 3 model tests. Full save-to-patient flow needs a provisioned admin | **PARTIAL — code/tests pass; live flow MANUAL** |
| 12 | Logos and launcher icons | In-app mark, Android launcher, adaptive/round icon and web/PWA icons all show the EasyCheck mark without clipping | Square pre-padded mark used in all square tiles; legacy, adaptive, round and web icons regenerated; release APK installed and role selection logo verified on emulator | **PASS** |
| 13 | Security rules resist self-elevation | No self-approval, no self-created membership, no role escalation, no `adminUid` change, no cross-user request read | Live probe: 22 / 22 checks passed, including self-approval 403, membership create 403, `adminUid` change 403, clinic create 403, cross-user request read 403, cross-clinic queue write 403 | **PASS** (live probe) |
| 14 | Email/password or anonymous sign-in | Both blocked; Google is the only provider | Live sign-up returned `OPERATION_NOT_ALLOWED`; anonymous returned `ADMIN_ONLY_OPERATION`; provider config contains only Google | **PASS** (live probe) |

### Summary

| Status | Count |
|--------|-------|
| PASS (automated, live probe, build, or emulator) | 11 |
| PARTIAL (code/tests pass; live flow blocked) | 2 |
| MANUAL (real Google account consent) | 1 |
| **Total** | **14** |

No scenario failed. Scenario 9 passes on resolution/routing but its live rejection step is blocked by the same missing Super Admin backend as scenario 8. The blocked/partial items are missing backend capabilities, not client failures.

---

## 3. Screen-by-Screen Smoke Test (Release APK, Pixel_7)

| Screen | What was checked | Result |
|--------|------------------|--------|
| Android launch screen | Branded mark on white, no default Flutter splash | ✅ |
| Role selection | Exact prompt, Patient / Doctor-Staff cards, logo, legal links, no overflow at 1080 × 2400 | ✅ |
| Patient login | Premium Google button (60 px target, official G mark, subtitle, soft shadow), legal links, back navigation | ✅ rendered and tappable |
| Google consent | Native system account picker opened on debug and release builds; requires a real Google account to complete consent | ⚠️ picker verified, consent not executed |
| Patient home | Builds from Firestore clinics, live counts, doctor timing, shared live dots, account deletion in Settings | ✅ code + widget tests; live data needs a signed-in patient |
| Clinic details | Doctor timing row, factual “Live clinic counter” chip, no fake verification claim | ✅ widget tests |
| Admin login | Premium responsive “clinical command” layout, Google button, no fake helpdesk/LDAP content | ✅ widget tests |
| Access request form | Clinic dropdown, name/email/contact, duplicate-safe submit, honest errors | ✅ widget tests |
| Submitted / pending / rejected / unauthorized | Factual status, request ID where applicable, sign-out and retry paths, fail-closed behavior | ✅ widget tests |
| Admin dashboard | Guarded entry, navy doctor-console hero, live queue pill, timing chip, today’s parchi chip, timing editor | ✅ widget tests; live dashboard requires provisioned membership |
| Legal pages | Full-screen Privacy Policy and Terms of Use, scrollable, no vendor/stack names, readable typography | ✅ widget tests + live HTTP 200 |
| Account deletion | Confirmation dialog, real profile delete, real auth delete, `requires-recent-login` guidance, failure messages | ✅ code review + rules probe; live deletion needs a real signed-in account |

---

## 4. Live Security Probe (Deployed Rules)

Two temporary test accounts were used **before** email/password was disabled. All test documents and accounts were deleted afterwards.

**22 / 22 probes passed**, including:

- Owner queue create: 200
- Unauthenticated clinic read: 403
- Patient self-profile create: 200
- `clinic_admin` self-profile create: 403
- Own pending request create: 200
- Duplicate request: 403
- Own request read: 200
- Other user request read: 403
- Self-approval: 403
- Self-created membership: 403
- `clinics.adminUid` change: 403
- Clinic create: 403
- Non-member queue update: 403
- Backend membership provisioning: 200
- Provisioned admin own-clinic queue update: 200
- Provisioned admin other-clinic queue update: 403
- Backend approval: 200
- Applicant reads approved status: 200

Full table: `SECURITY_AUDIT.md` §3.1.

---

## 5. Hosting, Headers and Public Pages

| Check | Result |
|-------|--------|
| `https://easycheck-online.web.app` deployed | ✅ |
| `/privacy.html` | ✅ HTTP 200, `Cache-Control: no-cache, must-revalidate` |
| `/terms.html` | ✅ HTTP 200, `Cache-Control: no-cache, must-revalidate` |
| `/delete-account.html` | ✅ HTTP 200, `Cache-Control: no-cache, must-revalidate` |
| CSP header | ✅ Present |
| HSTS | ✅ Present |
| `X-Content-Type-Options` | ✅ `nosniff` |
| `Referrer-Policy` | ✅ Present |
| `Permissions-Policy` | ✅ Present |
| COOP / `X-Frame-Options` | ✅ Present |
| Root and `main.dart.js` / `flutter_bootstrap.js` | ✅ `no-cache, must-revalidate` |
| Privacy page vendor-name scan | ✅ No `Firebase`, `Firestore`, `Google`, `Flutter`, `Dart`, `FirebaseAuth`, `gstatic` |
| `.env` in web build | ✅ Absent |

---

## 6. Artifact and Secret Verification

| Check | Result |
|-------|--------|
| Debug APK sensitive entries (`.env`, `key.properties`, `.jks`, `.keystore`, private key, client secret) | ✅ 0 / 697 entries |
| Release APK sensitive entries | ✅ 0 / 488 entries |
| Release AAB sensitive entries | ✅ 0 / 507 entries |
| Release APK signed with upload key | ✅ SHA-1 `d712df8904c7de09d3cd2dc80ac6378527f1c431` |
| `google-services.json` release certificate hash | ✅ Matches release SHA-1 |
| `google-services.json` debug certificate hash | ✅ Matches debug SHA-1 `65b462ea699e65f720ff75b06ae59beeddd51a57` |
| `allowBackup` / `fullBackupContent` | ✅ Disabled |
| `usesCleartextTraffic` | ✅ Disabled |
| Permissions | ✅ Only `INTERNET`, `ACCESS_NETWORK_STATE`, biometric (plugin), GSF read, and the app’s own dynamic-receiver permission |

---

## 7. What You Should Test on Your Phone

1. Uninstall any older EasyCheck build.
2. Install `build\app\outputs\flutter-apk\app-release.apk` (or the debug APK if you need logs).
3. Open the app and confirm the role selection prompt and logo.
4. Tap **Continue as Patient**, sign in with a real Google account, and confirm Patient Home opens.
5. Sign out, sign in again with the same account, and confirm no duplicate profile appears in Firebase Console.
6. Tap **Continue as Doctor / Staff**, sign in with a Google account that has **no** membership, and submit an access request for a clinic.
7. Sign out and back in; confirm the pending screen appears.
8. Ask the trusted operator to approve the request and provision `clinic_members/{uid}_{clinicId}`.
9. Sign in again and confirm the clinic dashboard opens only for that clinic.
10. Edit doctor timing, then open the patient home/clinic details and confirm the new timing appears.
11. Open **Settings → Delete account** with a patient test account and confirm the profile and sign-in account are removed.
12. Check the launcher icon on the home screen and in the app switcher.

### Expected blockers during this test

- Step 8 cannot be done from the app. No Super Admin approval UI exists in Task 23.
- No clinic has an initial membership, so the dashboard cannot open until the trusted operator provisions one.
- Google consent must be completed by a real account; the agent cannot do it.

---

## 8. Verdict

Task 23 is **functionally complete within its stated scope**:

- Role selection, patient access, access requests, pending/rejected screens and doctor timing are implemented.
- Firestore rules enforce UID-based authorization and were verified live.
- Google-only authentication is enforced.
- Branding, launcher icons, legal pages, security headers and Play Store account deletion are in place.
- Release APK and AAB build, sign and install successfully.

**Not yet end-to-end:** interactive Google sign-in, Super Admin approval, provisioned-admin dashboard, and the live doctor-timing save flow. These require a real Google account and the Task 24 backend.

**Stop point:** Task 23 ends here. Task 24 must not begin until the user reviews this report and explicitly approves the next phase.
