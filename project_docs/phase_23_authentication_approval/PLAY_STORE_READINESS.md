# Play Store Readiness

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 5, 2026  
**Status:** Android release artifacts, store graphics, legal pages and security hardening are ready. Play Console submission is **not** complete.

---

## 1. App Identity

| Field | Value |
|-------|-------|
| App name | EasyCheck Online |
| Package name | `com.easycheck.online.easycheck_online` |
| Version name | `1.0.0` |
| Version code | `1` |
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
| Play Store upload bundle | `build/app/outputs/bundle/release/app-release.aab` | 55.2 MB |
| Direct-install release APK | `build/app/outputs/flutter-apk/app-release.apk` | 55.0 MB |
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` | — |

The release APK/AAB are signed with the EasyCheck upload key:

```text
CN=EasyCheck Online, OU=Mobile, O=EasyCheck Online, L=Lahore, ST=Punjab, C=PK
SHA-1: d712df8904c7de09d3cd2dc80ac6378527f1c431
```

`google-services.json` contains both the release SHA-1 and the debug SHA-1. The keystore and `key.properties` are gitignored and are **not** inside the APK/AAB.

### Rebuild commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
flutter build apk --release
```

---

## 3. Public URLs

| Purpose | URL | Status |
|---------|-----|--------|
| Privacy Policy | `https://easycheck-online.web.app/privacy.html` | ✅ HTTP 200 |
| Terms of Use | `https://easycheck-online.web.app/terms.html` | ✅ HTTP 200 |
| Account deletion | `https://easycheck-online.web.app/delete-account.html` | ✅ HTTP 200 |
| App | `https://easycheck-online.web.app` | ✅ Live |

All three legal pages return `Cache-Control: no-cache, must-revalidate` and do not name Firebase, Firestore, Google, Flutter, Dart or other internal technology.

Support email used on the legal pages: `bipulkumarsiwan6262@gmail.com`. Replace it with a dedicated support address before public launch if one is available.

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

Complete the form from the actual behavior of the app. The app has no analytics, advertising or crash-reporting SDK. The likely declarations are:

| Question | Suggested answer |
|----------|------------------|
| Does your app collect or share any required user data types? | Yes |
| Personal info → Name | Collected; used for account management and clinic access review |
| Personal info → Email address | Collected; used for sign-in and support |
| Personal info → Photos | Collected only if the Google profile photo is stored; used for profile display |
| Personal info → User IDs | Collected; used to authorise clinic access |
| App activity → Other actions | Collected for queue updates and audit records |
| App info and performance → Diagnostics | Not collected by an in-app SDK; confirm hosting/provider logs before declaring |
| Is data shared with third parties? | Shared with the clinic the user follows or works for, and with service providers that host and secure the service |
| Is data encrypted in transit? | Yes |
| Can users request deletion? | Yes — in-app Settings and the public deletion URL |
| Is data collection optional? | Sign-in data is required to use the account features; patients can use limited clinic browsing only after sign-in in the current build |

Do not declare “no data collected”. The app stores a patient profile and clinic access requests.

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

### Before upload

- [ ] Decide whether to use Play App Signing (recommended).
- [ ] Create the app in Play Console with package `com.easycheck.online.easycheck_online`.
- [ ] Upload `app-release.aab` to an internal-testing track first.
- [ ] Add the **Play App Signing certificate SHA-1** to Firebase Authentication → Google → Android app.
- [ ] If Firebase generates a new OAuth client, download the updated `google-services.json` and rebuild the AAB.
- [ ] Re-test Google Sign-In from the internal-testing build, not only the local release APK.
- [ ] Increment `version` in `pubspec.yaml` for every future upload.

### Store listing

- [ ] App name, short description and full description.
- [ ] App icon 512 × 512.
- [ ] Feature graphic 1024 × 500.
- [ ] At least 2 phone screenshots.
- [ ] Privacy Policy URL.
- [ ] Account deletion URL.
- [ ] Support email.
- [ ] Category and tags.
- [ ] Medical disclaimer.

### App content

- [ ] Privacy Policy declaration.
- [ ] Data safety form.
- [ ] Content rating questionnaire.
- [ ] Target audience and ads declaration.
- [ ] News app declaration: No.
- [ ] COVID-19 contact-tracing declaration: No.
- [ ] Government app declaration: No.
- [ ] Financial features declaration: No.
- [ ] Health declaration: answer truthfully; the app is clinic operations, not diagnosis or treatment.

### Review access

- [ ] Create a reviewer Google account.
- [ ] Provision a `clinic_members/{uid}_{clinicId}` membership for the reviewer so the doctor dashboard can be reviewed.
- [ ] Put the reviewer email and exact test steps in “App access” → “Instructions”.
- [ ] Explain that a normal patient account sees only the patient experience.
- [ ] Provide the patient test account too, if the reviewer needs to see both roles.

> **Current blocker:** no Super Admin approval backend and no initial clinic membership exist. The reviewer cannot see the doctor dashboard until the trusted operator provisions one. Do not fake approval in the client.

---

## 11. Post-Upload Verification

1. Install the build from the internal-testing track on a real phone.
2. Sign in with Google and confirm Patient Home opens.
3. Sign in as the provisioned reviewer admin and confirm the clinic dashboard opens.
4. Confirm the launcher icon and launch screen.
5. Open Privacy Policy, Terms of Use and Delete account from the app.
6. Delete a patient test account and confirm it disappears from Firebase Auth and `users`.
7. Check Play Console pre-launch report for crashes, accessibility issues and policy warnings.
8. Promote to closed testing, then production after sign-off.

---

## 12. Remaining Blockers

| Blocker | Owner | Notes |
|---------|-------|-------|
| Super Admin approval backend | Task 24 | Requests cannot be approved yet |
| Initial clinic membership | Trusted operator | Dashboard cannot open without it |
| Reviewer test account + membership | Release owner | Required for Play review |
| Play App Signing SHA-1 in Firebase | Release owner | Google Sign-In can fail on Play-installed builds otherwise |
| Data safety and content rating | Release owner | Complete in Play Console |
| Real-device Google consent test | Release owner | Agent could not complete a real Google login |
| Final screenshots from real phone | Release owner | Current screenshots are valid emulator captures |

---

## 13. Verdict

The app is **ready for phone testing and internal-track upload**, not yet ready for public production review until the reviewer admin path is provisioned and the Play Console forms are completed. The release bundle is signed, the legal pages are live, and no private keys or environment files are bundled.
