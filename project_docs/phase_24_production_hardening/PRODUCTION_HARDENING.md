# Production Hardening — November 2026

This phase fixes the production blockers found in the readiness audit. Code-level
fixes are complete and verified. Items that require the Firebase Console, Play
Console, a service-account key, billing, or a physical phone are listed as
operator steps.

---

## 1. Code fixes completed

| Blocker | Fix | Files |
|---|---|---|
| No crash reporting | Firebase Crashlytics initialized; fatal Flutter and platform errors are recorded; Gradle plugin added | `lib/main.dart`, `android/settings.gradle.kts`, `android/app/build.gradle.kts` |
| Account deletion could leave a half-deleted account | Google re-authentication is required before deletion; the profile is restored if sign-in deletion still fails | `lib/features/authentication/google_auth_service.dart`, `lib/features/patient/patient_home_screen.dart` |
| Staff UID exposed in every clinic document | `adminUid` removed from the clinic model, authorization service, and security rules; access is membership-only; migration command added | `lib/features/clinics/clinic_model.dart`, `lib/features/authentication/admin_access_service.dart`, `firestore.rules`, `tools/admin_cli` |
| No doctor photo upload | Firebase Storage upload with gallery picker, 1200 px / 82% compression, error fallback, and a clinic-admin-only storage rule | `lib/features/clinics/clinic_photo_service.dart`, `lib/features/admin/admin_dashboard_screen.dart`, `storage.rules`, `firebase.json` |
| No App Check | App Check activated with the debug provider in debug builds and Play Integrity in release builds | `lib/main.dart` |
| User/admin management only through the Console | Trusted local Admin SDK CLI for approvals, rejections, memberships, clinic creation, offboarding, and migration | `tools/admin_cli/` |
| Firestore rules changed for membership-only access | Rules compiled and released to `easycheck-online` | `firestore.rules` |

### Verification

- `flutter analyze` — no issues
- `flutter test` — 64 / 64 passed
- `flutter build apk --debug` — succeeded
- Firestore rules — compiled and released
- Storage rules — file added; deployment requires Storage to be enabled (step A)

---

## 2. Operator steps

### A. Enable Firebase Storage (required for doctor photo upload)

The upload button is already in the clinic admin **Clinic** tab, but Storage is
not enabled on the project yet.

1. Open Firebase Console → **Build → Storage**.
2. Click **Get Started**.
3. Choose the same region as Firestore (`asia-south1`) if prompted.
4. Start in production mode (the rules file will replace the default rules).
5. Deploy the rules from the project:

   ```powershell
   cd "D:\Easycheck ONLINE"
   firebase deploy --only storage --project easycheck-online
   ```

6. Sign in as a provisioned clinic admin, open **Clinic → Change photo**, pick an
   image, and confirm it appears on the patient clinic page.

If Storage is not enabled, the upload fails with a clear on-screen message and
no data is changed.

### B. Create the service account and install the trusted CLI

The CLI replaces manual Firestore document editing. It uses the Admin SDK and is
never bundled into the app.

1. Firebase Console → **Project settings → Service accounts**.
2. Click **Generate new private key**.
3. Save the JSON outside the repository, for example:

   ```text
   C:\Users\<you>\secrets\easycheck-service-account.json
   ```

4. Install dependencies and set the environment variable:

   ```powershell
   cd "D:\Easycheck ONLINE\tools\admin_cli"
   npm install
   $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\<you>\secrets\easycheck-service-account.json"
   ```

5. Verify the connection:

   ```powershell
   node index.js list-clinics
   ```

6. Read `tools/admin_cli/README.md` for every command.

**Security:** the service-account JSON can bypass all security rules. Never commit
it, never upload it, never paste it into chat, and never put it on a shared drive.
The repository ignores `tools/admin_cli/service-account*.json` and
`node_modules`.

### C. Retire demo clinics and remove the legacy field

Run these once, after the CLI is connected:

```powershell
node index.js deactivate-clinic CLN-84920 --by "<operatorUid>" --reason "Demo clinic retired"
node index.js deactivate-clinic CLN-84921 --by "<operatorUid>" --reason "Demo clinic retired"
node index.js deactivate-clinic CLN-84922 --by "<operatorUid>" --reason "Demo clinic retired"
node index.js cleanup-admin-uid --by "<operatorUid>"
```

`cleanup-admin-uid` removes the legacy staff identifier from every clinic
document. Until it runs, the field may still be present in old documents even
though the app and rules no longer use it.

### D. Onboard the first real clinic

1. The clinic owner signs in once in the app: **Doctor / Staff → Google**.
2. Copy their UID from Firebase Console → **Authentication → Users**.
3. Create the clinic and membership in one command:

   ```powershell
   node index.js create-clinic --id CLN-84923 --name "Clinic name" --city "City" --region "State" --phone "+91..." --email "clinic@example.com" --admin-uid "<uid>" --by "<operatorUid>" --doctor-name "Dr. Name" --doctor-timing "Mon–Sat · 9:00 AM – 5:00 PM"
   ```

4. Ask the owner to sign out and sign in again.
5. Confirm the dashboard opens.
6. Confirm the doctor timing appears on the patient clinic page.
7. Confirm queue increment, decrement, reset, and pause work.

### E. App Check setup and enforcement

App Check is initialized in the app. Enforcement is intentionally **off** until
the app is distributed with App Check support.

1. Firebase Console → **Build → App Check → Apps**.
2. Register the Android app with **Play Integrity**.
3. Add the debug SHA-256 and release SHA-256 in **Project settings → Your apps**.
4. Install the debug build on a test phone.
5. Open the app and find the App Check debug token in the device log:

   ```powershell
   adb logcat | Select-String "AppCheck"
   ```

6. Register that token in **App Check → Apps → Manage debug tokens**.
7. Install the signed release build and confirm sign-in and Firestore work.
8. Only then open **App Check → APIs → Firestore** and **Storage** and click
   **Enforce**.

**Order matters.** Enforcing before the release build and debug tokens are
registered will block real users. Do not enforce during the pilot until the
release APK/AAB with App Check is the build everyone is using.

### F. Real-device end-to-end test

See `REAL_DEVICE_TEST_PLAN.md` in this folder. This cannot be completed by the
coding agent because it needs a real Google account, a physical phone, and
Google consent.

### G. Play Store submission

Assets already exist:

```text
store_assets/app_icon_512.png
store_assets/feature_graphic_1024x500.png
store_assets/phone_1.png
store_assets/phone_2.png
build\app\outputs\bundle\release\app-release.aab
```

Steps:

1. Play Console → **Create app**.
2. Complete **App content**:
   - Privacy policy: `https://easycheck-online.web.app/privacy.html`
   - Account deletion: `https://easycheck-online.web.app/delete-account.html`
   - Data safety: account details (name, email, photo), clinic and queue data,
     app activity; encrypted in transit; deletion available.
   - Content rating questionnaire.
   - Target audience and ads declaration.
3. Create an **internal testing** release and upload the AAB.
4. Play App Signing will re-sign the app. After the first upload:
   - Play Console → **App integrity → App signing key certificate**.
   - Copy the SHA-1 and SHA-256.
   - Firebase Console → **Project settings → Your apps** → add both
     fingerprints.
   - Re-test Google Sign-In on the Play-installed build.
5. Provide **App access** instructions for reviewers:
   - Create a dedicated Google test account.
   - Sign in once in the app.
   - Provision it with the CLI (`create-clinic` or `add-member`).
   - Give the reviewer the account email and password and the exact steps.
6. Increment `versionCode` in `pubspec.yaml` before every upload.
7. Promote internal → closed → production only after the real-device test passes.

**Warning:** the current release keystore signs the upload bundle. Play App
Signing replaces it. Google Sign-In can fail until the Play signing SHA-1 is
added to Firebase and the app is rebuilt/re-uploaded.

### H. Backups, monitoring, and alerts

These require the Blaze (pay-as-you-go) plan.

1. **Firestore backups:** Firebase Console → Firestore → **Backups** → create a
   daily backup schedule with at least 7-day retention. Alternatively use
   `gcloud firestore backups schedules create` with the same retention.
2. **Crashlytics alerts:** Firebase Console → Crashlytics → enable velocity
   alerts for fatal crashes.
3. **Uptime check:** Google Cloud Console → Monitoring → Uptime checks →
   `https://easycheck-online.web.app`.
4. **Budget alert:** Google Cloud Console → Billing → Budgets & alerts → set a
   monthly budget with 50%, 90%, and 100% alerts.
5. **Firestore usage alert:** Cloud Monitoring → alert on reads/writes/deletes
   above the expected daily baseline.
6. **Restore drill:** once per quarter, restore a backup into a temporary project
   and verify clinic, membership, and queue data.

### I. Push notifications (not implemented in this pass)

Push notifications still require a sender. The app currently has an in-app
notification sheet placeholder, not FCM.

A complete implementation needs:

1. `firebase_messaging` in the app, Android 13+ notification permission, and
   device-token registration per signed-in user.
2. A server or Cloud Function that sends messages to the clinic's active admins.
3. In-app notification records so the notification list survives a push failure.
4. A scheduler if reminders must be automatic.

Cloud Functions require the Blaze plan. This was intentionally not half-built:
showing a notification toggle that cannot deliver would be fake functionality.

---

## 3. Remaining after this phase

| Item | Owner | Status |
|---|---|---|
| Enable Storage and deploy storage rules | Operator | Pending |
| Create service account and run CLI | Operator | Pending |
| Deactivate demo clinics | Operator | Pending |
| Onboard first real clinic | Operator | Pending |
| Real-phone end-to-end test | Operator | Pending |
| App Check debug token + enforcement | Operator | Pending |
| Play Store submission and signing SHA | Operator | Pending |
| Backups, monitoring, budget alerts | Operator | Pending |
| Push notifications | Next phase | Not started |
| Full Super Admin UI | Next phase | CLI is the trusted tool for now |
