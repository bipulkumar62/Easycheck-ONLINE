# Play Store Readiness

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 12, 2026  
**Status:** Android release artifacts, store graphics, legal pages and security hardening are ready. The app was rejected on **11 November 2026** under **Play Console Requirements** because the new personal developer account has not completed the mandatory closed test. See `project_docs/phase_25_play_closed_testing/CLOSED_TESTING_PLAYBOOK.md`.

---

## 1. App Identity

| Field | Value |
|-------|-------|
| App name | EasyCheck Online |
| Package name | `com.easycheck.online.easycheck_online` |
| Version name | `1.0.1` |
| Version code | `2` |
| Minimum Android | API 24 (Android 7.0) |
| Target Android | API 36 |
| Category | Medical (confirm in Play Console) |
| Pricing | Free |
| Ads | No |
| In-app purchases | No |
| Sign-in | Google only, native Android account picker |

---

## 2. Release Artifacts

| Artifact | Path | Size |
|----------|------|------|
| Play Store upload bundle | `build/app/outputs/bundle/release/app-release.aab` | 60,901,272 bytes (58.1 MB) |
| Direct-install release APK | `build/app/outputs/flutter-apk/app-release.apk` | 60,608,718 bytes (57.8 MB) |
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` | — |

The release APK/AAB are signed with the EasyCheck upload key:

```text
CN=EasyCheck Online, OU=Mobile, O=EasyCheck Online, L=Lahore, ST=Punjab, C=PK
SHA-1: d712df8904c7de09d3cd2dc80ac6378527f1c431
```

New apps use **Play App Signing**, so Play-installed builds are signed by Google's app-signing keys, not the upload key. The app uses **quantum-ready hybrid signing**, which publishes three app signing keys. All three SHA-1 fingerprints were registered in Firebase on 12 November 2026:

| Key | SHA-1 |
|-----|-------|
| Play app signing key 1 | `35:67:87:04:3D:3E:50:FA:CA:2A:5D:3F:CF:30:42:04:8A:C7:A0:F7` |
| Play app signing key 2 | `03:F8:7F:8E:50:CC:69:DF:1C:C1:80:8F:C9:07:93:39:A0:A0:62:E2` |
| Play app signing key 3 | `32:D3:D2:5B:6A:9E:64:E5:7F:F1:99:53:6F:79:E6:C6:63:41:4F:83` |

The upload key (`D7:12:DF:…`) and debug key (`65:B4:62:…`) remain registered. `google-services.json` was regenerated and both artifacts were rebuilt after registration.

Current bundle fingerprints:

| Artifact | SHA-256 |
|----------|---------|
| `app-release.aab` | `F3096FBC3A8994DD956020713F78D48359292127FBB108D58A8DC9C047B78A74` |
| `app-release.apk` | `775F8DFC4BD5B44BCDA169869B961A542299222D2E01BED97CBD33ACC9DA4D75` |

The keystore and `key.properties` are gitignored and are **not** inside the APK/AAB.

### Rebuild commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
flutter build apk --release
```

All three Play app-signing SHA-1s are already registered. If the signing keys rotate, repeat:

```powershell
firebase apps:android:sha:create 1:1085858861836:android:f6c366f51fe48bac61ef29 <PLAY_SHA1_KEY_1> --project easycheck-online
firebase apps:android:sha:create 1:1085858861836:android:f6c366f51fe48bac61ef29 <PLAY_SHA1_KEY_2> --project easycheck-online
firebase apps:android:sha:create 1:1085858861836:android:f6c366f51fe48bac61ef29 <PLAY_SHA1_KEY_3> --project easycheck-online
firebase apps:sdkconfig android 1:1085858861836:android:f6c366f51fe48bac61ef29 --project easycheck-online > android/app/google-services.json
flutter build appbundle --release
```

---

## 3. Public URLs

| Purpose | URL | Status |
|---------|-----|--------|
| Privacy Policy (Play listing) | `https://sites.google.com/view/easycheck-online/home` | ✅ Live |
| Privacy Policy (in-app / backup) | `https://easycheck-online.web.app/privacy.html` | ✅ Live |
| Terms of Use | `https://easycheck-online.web.app/terms.html` | ✅ Live |
| Account deletion | `https://easycheck-online.web.app/delete-account.html` | ✅ Live |
| Patient web app | `https://easycheck-online.web.app` | ✅ Live |
| Super Admin console | `https://easycheck-superadmin.web.app` | ✅ Live |

All three Firebase legal pages return `Cache-Control: no-cache, must-revalidate` and do not name Firebase, Firestore, Google, Flutter, Dart or other internal technology.

Support email used on the legal pages and store listing: `moderndeveloper943@gmail.com`. It must match the Play Console developer contact address.

---

## 4. Store Listing Copy

### Short description (80 characters max)

```text
Live parchi tracking and doctor timing for clinics and patients.
```

### Full description

```text
EasyCheck Online helps patients see what is happening at their clinic before they travel, and helps authorised clinic teams keep the queue clear and current.

FOR PATIENTS
• See live parchi counts for participating clinics.
• Check doctor timing entered by the clinic.
• Follow the clinics you visit.
• Sign in quickly with your Google account.
• Read the Privacy Policy and Terms of Use inside the app.

FOR CLINIC STAFF
• Request access to your clinic.
• Clinic access is verified before the dashboard opens.
• Update the live queue, doctor timing and today’s parchi count.
• Keep the front desk and patients on the same page.

IMPORTANT
EasyCheck is an operational clinic-information tool. It is not a hospital, medical practice or emergency service, and it does not provide medical advice, diagnosis or treatment. Always confirm important details with the clinic and contact local emergency services when urgent help is needed.

Account deletion is available inside the app under Settings, and instructions are published at the account-deletion link on this listing.
```

Do not add “HIPAA compliant”, “trusted by 140+ clinics”, “verified by reception”, or similar claims unless they become true and verifiable.

---

## 5. Store Graphics

| Asset | Requirement | File | Status |
|-------|-------------|------|--------|
| App icon | 512 × 512, 32-bit PNG | `store_assets/app_icon_512.png` | ✅ 89.5 KB |
| Feature graphic | 1024 × 500, no transparency | `store_assets/feature_graphic_1024x500.png` | ✅ 105.8 KB |
| Phone screenshot 1 | 1080 × 1920 | `store_assets/screenshots/phone_01_role_selection.png` | ✅ 286.6 KB |
| Phone screenshot 2 | 1080 × 1920 | `store_assets/screenshots/phone_02_patient_login.png` | ✅ 898.8 KB |

Play Store requires at least 2 phone screenshots. These two are real app captures from the Pixel_7 emulator, padded to a valid 9:16 canvas. Recapture after the final phone test if you want the screenshots to show your own device status bar.

Optional but recommended:

- 7-inch tablet screenshots (2).
- 10-inch tablet screenshots (2).
- A short promotional video (30–120 seconds).

---

## 6. Data Safety Form — Suggested Answers

Complete the form from the actual behavior of the app. The release build initializes **Firebase Crashlytics** and **Firebase App Check**, so the form must declare crash logs, diagnostics and device identifiers. Do **not** submit “No data collected” and do **not** repeat the old “no crash-reporting SDK” claim.

| Question | Suggested answer |
|----------|------------------|
| Does your app collect or share any required user data types? | Yes |
| Personal info → Name | Collected; used for account management and clinic access review |
| Personal info → Email address | Collected; used for sign-in, support and access review |
| Personal info → Photos | Collected only if the Google profile photo or a clinic/doctor photo is stored; used for profile display |
| Personal info → User IDs | Collected; used to authorise clinic access |
| App activity → Other actions | Collected for queue updates and audit records |
| App info and performance → Crash logs | Collected by Firebase Crashlytics; used for app stability and crash diagnosis |
| App info and performance → Diagnostics | Collected; crash and performance diagnostics |
| Device or other IDs | Collected by Crashlytics/App Check; used for security, abuse prevention and diagnostics |
| Is data shared with third parties? | Shared only with service providers: Google Firebase (authentication, database, crash reporting, App Check) and Supabase (image storage), plus the clinic the user follows or works for. Never sold. |
| Is data encrypted in transit? | Yes |
| Can users request deletion? | Yes — in-app Settings and the public deletion URL |
| Is data collection optional? | Account data is required for account features; clinic browsing requires sign-in in the current build |

---

## 7. Content Rating and Audience

Suggested answers for the content-rating questionnaire:

| Topic | Answer |
|-------|--------|
| Violence, sexual content, profanity, drugs, gambling | No |
| User-generated content shared publicly | No (access requests are visible only to the applicant and trusted reviewers) |
| Users can interact online | No public chat or social feed |
| Shares precise location | No |
| Medical content | Informational clinic queue/timing only; no diagnosis or treatment |
| Target age | 18+ recommended; clinic staff and adult patients |

Add the medical disclaimer from the store description in the listing and keep it in the app.

---

## 8. Permissions

The release APK requests:

- `INTERNET`
- `ACCESS_NETWORK_STATE`
- `USE_BIOMETRIC` / `USE_FINGERPRINT` (from the local-auth plugin; no biometric flow is currently exposed)
- `com.google.android.providers.gsf.permission.READ_GSERVICES` (Google Play services)
- The app’s own dynamic-receiver permission

No location, camera, microphone, contacts, SMS or external-storage permission is requested.

---

## 9. Account Deletion

| Requirement | Implementation |
|-------------|----------------|
| In-app deletion path | Patient Home → Settings → Delete account |
| Deletes profile | ✅ Firestore `users/{uid}` |
| Deletes sign-in account | ✅ Firebase Auth `user.delete()` |
| Handles recent-login requirement | ✅ Clear message; user signs in again |
| Public instructions | ✅ `https://easycheck-online.web.app/delete-account.html` |
| Staff deletion | Managed by clinic offboarding, documented on the public page |

---

## 10. Play Console Submission Checklist

### Closed-testing gate (new personal developer account)

- [ ] Confirm the developer account is **personal** (organization accounts are exempt).
- [ ] Recruit **15–20 testers** so at least 12 remain opted in.
- [ ] Upload the AAB to **Closed testing**, not production.
- [ ] Send every tester the Play opt-in link and confirm they install from Play.
- [ ] Keep at least **12 testers opted in for 14 continuous days**.
- [ ] Only then use **Apply for production access** and answer the feedback questions.
- [ ] Do not resubmit to production before Play Console shows the requirement is met; it will be rejected again.

### Before upload

- [x] Register all three Play app-signing SHA-1s (quantum-ready hybrid signing) in Firebase.
- [x] Regenerate `google-services.json` and rebuild the AAB.
- [ ] Upload `app-release.aab` (`1.0.1+2`) to closed testing.
- [ ] Re-test Google Sign-In from the Play-installed build, not only the local release APK.
- [ ] Increment `version` in `pubspec.yaml` for every future upload.
- [ ] If Play reports a duplicate version code, bump to `1.0.1+3`.

### Store listing

- [ ] App name, short description and full description.
- [ ] App icon 512 × 512.
- [ ] Feature graphic 1024 × 500.
- [ ] At least 2 phone screenshots.
- [ ] Privacy Policy URL: `https://sites.google.com/view/easycheck-online/home`.
- [ ] Account deletion URL: `https://easycheck-online.web.app/delete-account.html`.
- [ ] Support email: `moderndeveloper943@gmail.com`.
- [ ] Category and tags.
- [ ] Medical disclaimer.

### App content

- [ ] Privacy Policy declaration.
- [ ] Data safety form (declare Crashlytics and App Check).
- [ ] Content rating questionnaire.
- [ ] Target audience and ads declaration.
- [ ] News app declaration: No.
- [ ] COVID-19 contact-tracing declaration: No.
- [ ] Government app declaration: No.
- [ ] Financial features declaration: No.
- [ ] Health declaration: answer truthfully; the app is clinic operations, not diagnosis or treatment.

### Review access

- [ ] Create a reviewer Google account with no 2FA.
- [ ] Add it as a closed tester.
- [ ] Provision a `clinic_members/{uid}_{clinicId}` membership for the reviewer so the doctor dashboard can be reviewed.
- [ ] Put the reviewer email and exact test steps in “App access” → “Instructions”.
- [ ] Explain that a normal patient account sees only the patient experience.
- [ ] Provide the patient test account too, if the reviewer needs to see both roles.

> **Current blocker:** no reviewer Google account or clinic membership has been provisioned. The reviewer cannot see the doctor dashboard until the trusted operator creates one. Do not fake approval in the client.

---

## 11. Post-Upload Verification

1. Install the build from the closed-testing track on a real phone.
2. Sign in with Google and confirm Patient Home opens.
3. Sign in as the provisioned reviewer admin and confirm the clinic dashboard opens.
4. Confirm the launcher icon and launch screen.
5. Open Privacy Policy, Terms of Use and Delete account from the app.
6. Delete a patient test account and confirm it disappears from Firebase Auth and `users`.
7. Check Play Console pre-launch report for crashes, accessibility issues and policy warnings.
8. Keep 12+ testers opted in for 14 continuous days, then apply for production access.

---

## 12. Remaining Blockers

Resolved on 12 November 2026: all three Play app-signing SHA-1s are registered in Firebase and both artifacts were rebuilt with the updated config.

| Blocker | Owner | Notes |
|---------|-------|-------|
| Closed test (12 testers, 14 days) | Release owner | Calendar-bound; earliest production application ~26 November 2026 if testers start 12 November 2026 |
| Reviewer test account + clinic membership | Release owner | Required for Play review |
| Data safety and content rating | Release owner | Complete in Play Console |
| Super Admin authorized domain | Release owner | Add `easycheck-superadmin.web.app` in Firebase Auth → Settings → Authorized domains for Google popup sign-in |
| Real-device Google consent test | Release owner | Agent could not complete a real Google login |
| Final screenshots from real phone | Release owner | Current screenshots are valid emulator captures |

---

## 13. Verdict

The app is **ready to upload to closed testing**, not yet eligible for production. The rejection is the new personal-account testing gate, not a code defect. All three Play app-signing SHA-1s are registered in Firebase, `google-services.json` was regenerated, and both artifacts were rebuilt so Google Sign-In works on Play-installed builds. The legal pages, patient web app and Super Admin site are live, the release bundle is signed, and no private keys or environment files are bundled. The remaining work is the 12-tester/14-day closed test, reviewer access provisioning, and the Play Console forms.
