# Production Hardening — November 2026

This phase closes the production blockers found in the readiness audit. The
application now uses **Firebase for Auth, Firestore, Hosting, Crashlytics and App
Check**, and **Supabase Storage only for doctor photos**. The project stays on the
free Firebase plan; no Firebase Storage and no Blaze-only services are required.

Code-level fixes are complete and verified. Items that need a Console, a physical
phone, payment, or a service-account key are listed as operator steps.

---

## 1. Final architecture

| Concern | Service | Notes |
|---|---|---|
| Sign-in | Firebase Auth (Google) | Clinic staff and patients use the app |
| Database | Cloud Firestore | Rules are the security boundary |
| Patient web app | Firebase Hosting | `https://easycheck-online.web.app` |
| Super Admin console | Netlify static site | `https://easycheck-online-superadmin.netlify.app` |
| Crash reporting | Firebase Crashlytics | Fatal Flutter and platform errors |
| App Check | Play Integrity (release), debug provider (debug) | Enforcement is still off |
| Doctor photos | Supabase Storage, bucket `clinic-photos` | Public read, 5 MB, JPEG/PNG/WebP |
| Photo upload | Supabase Edge Function `clinic-photo` | The only write path |
| Push notifications | Not implemented | Requires a sender; intentionally not half-built |

### Security boundary

- **Firestore rules:** clinic access comes only from an active `clinic_admin` /
  staff membership. Super-admin authority comes only from the `superAdmin`
  custom claim. There is no email/phone allow-list and no `users.role ==
  'super_admin'` check.
- **Supabase Edge Function:** verifies the Firebase ID token, checks the
  `superAdmin` claim or an active `clinic_admin` membership, validates the real
  image bytes, and uploads with a service-role key that stays on the server.
- **Supabase bucket:** public read so patient pages can load photos. No client
  write policy and no broad SELECT policy. Browsers and the app never receive a
  service-role key.
- **Super Admin console:** a static React/Vite app that writes directly to
  Firestore. The claim and the Firestore rules are the security boundary, not
  the UI.

---

## 2. Code fixes completed

| Blocker | Fix | Files |
|---|---|---|
| No crash reporting | Crashlytics initialized; fatal Flutter and platform errors recorded; Gradle plugin added | `lib/main.dart`, `android/settings.gradle.kts`, `android/app/build.gradle.kts` |
| Account deletion could leave a half-deleted account | Google re-authentication is required before deletion; the profile is restored if sign-in deletion still fails | `lib/features/authentication/google_auth_service.dart`, `lib/features/patient/patient_home_screen.dart` |
| Staff UID exposed in every clinic document | `adminUid` removed from the clinic model, authorization service, and rules; access is membership-only; cleanup command added | `lib/features/clinics/clinic_model.dart`, `lib/features/authentication/admin_access_service.dart`, `firestore.rules`, `tools/admin_cli` |
| No doctor photo upload | Supabase Edge Function upload with gallery picker, 1200 px / 82% compression, safe error messages, and a public-read photo bucket | `lib/features/clinics/clinic_photo_service.dart`, `lib/features/admin/admin_dashboard_screen.dart` |
| Firebase Storage unavailable on the free plan | `firebase_storage` removed; photo bytes go through the Supabase Edge Function; only the public HTTPS URL is stored in Firestore | `pubspec.yaml`, `lib/features/clinics/clinic_photo_service.dart`, `lib/core/config/supabase_config.dart` |
| Service-role key must never reach a client | Uploads are server-side; the web console uses a small fetch helper with the Firebase ID token, not a Supabase service key | `SUPERADMIN/src/lib/supabase.ts`, `SUPERADMIN/src/context/DashboardContext.tsx` |
| Super Admin trusted the wrong identity | Console session requires the `superAdmin` custom claim; non-super-admins are signed out; allow-list and `users.role` checks removed | `SUPERADMIN/src/context/DashboardContext.tsx`, `SUPERADMIN/src/lib/logic.ts` |
| No App Check | App Check activated with the debug provider in debug builds and Play Integrity in release builds | `lib/main.dart` |
| User/admin management only through the Console | Trusted local Admin SDK CLI for approvals, rejections, memberships, clinic creation, offboarding, and migration | `tools/admin_cli/` |
| Firestore rules changed for membership-only access | Rules compiled and released to `easycheck-online` | `firestore.rules` |

### Super Admin console fixes

- Claim-only session resolution; no email allow-list and no `users.role`
  fallback.
- `adminUid` removed from the clinic form, modal, demo data, tests, and types.
- Primary admin is derived from the active `clinic_admin` membership.
- Approval writes `clinicId` to the user profile and requires the requested
  clinic.
- Photo upload uses the Supabase Edge Function; Firestore stores only the public
  HTTPS URL.
- CSP allows only the Supabase project host used by the function and public
  images.

---

## 3. Verification

- `flutter analyze` — no issues
- `flutter test` — 72 / 72 passed
- `flutter build apk --release` — succeeded, 56.1 MB
- `flutter build appbundle --release` — succeeded, 56.6 MB
- Super Admin `npm run build` — succeeded
- Super Admin `npm test` — 9 / 9 passed
- Firestore rules — compiled and released
- Edge Function negative tests — no/invalid token `401`, `OPTIONS` `200`,
  `GET` `405`
- Supabase storage policy — broad SELECT policy dropped; RLS check shows
  `anon` and `authenticated` can see `0` objects; duplicate empty bucket
  `Easycheck img` deleted
- Release signing — APK verified with `apksigner`; AAB verified with `keytool`

### Signing fingerprints

| Build | SHA-1 | SHA-256 |
|---|---|---|
| Debug | `65:B4:62:EA:69:9E:65:F7:20:FF:75:B0:6A:E5:9B:EE:DD:D5:1A:57` | `79:93:39:19:16:EF:EE:D0:40:9F:1C:8A:D6:B6:1C:AA:54:D8:6D:90:6E:B1:C5:B9:27:69:06:D3:1C:3A:68:70` |
| Release | `D7:12:DF:89:04:C7:DE:09:D3:CD:2D:C8:0A:C6:37:85:27:F1:C4:31` | `1B:7B:17:F6:C3:64:E3:3F:69:C9:91:23:9D:0E:FC:D5:4D:89:0F:5A:DF:5D:C6:57:CD:EA:E5:99:B0:67:14:89` |

All four certificates are registered on the Firebase Android app
`1:1085858861836:android:f6c366f51fe48bac61ef29`.

Signed outputs:

```text
build\app\outputs\flutter-apk\app-release.apk
build\app\outputs\bundle\release\app-release.aab
```

Release keystore: `android\app\easycheck-release.jks`, alias `easycheck`.
Passwords are in `android\key.properties`, which is ignored by git. Back up the
keystore and passwords outside the repository; losing them prevents future
updates to the same Play listing.

---

## 4. Supabase storage security

Bucket `clinic-photos`:

- Public read: `true`
- File size limit: 5 MB (`5242880` bytes)
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`
- No client write policy
- No SELECT policy on `storage.objects`

Public object URLs use the form:

```text
https://oeyetcapghqibcqkcued.supabase.co/storage/v1/object/public/clinic-photos/<path>
```

Public buckets serve these URLs without consulting RLS. A SELECT policy is only
needed for the Storage **list** API, and it lets any client enumerate files. It
was therefore removed:

```sql
drop policy if exists "Public read clinic photos" on storage.objects;
```

Do **not** add it back just to browse files. Use the Supabase dashboard or a
server-side service-role call for administration.

If listing is ever required temporarily, the rollback is:

```sql
create policy "Public read clinic photos"
on storage.objects for select
to public
using (bucket_id = 'clinic-photos');
```

Remove it again immediately after the administrative task.

### Verifying the policy state

```sql
select policyname, cmd, roles, qual
from pg_policies
where schemaname = 'storage' and tablename = 'objects';
```

Expected: no rows for `clinic-photos`. The dashboard may show an empty list
response (`200 []`) for an empty bucket even when RLS blocks access; the
authoritative check is the row count under the `anon` role, which is `0`.

### Function secrets

The Edge Function uses these Supabase secrets. They are set in the dashboard and
must never be committed or sent to a client:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `FIREBASE_PROJECT_ID` (or the project ID is hard-coded in the function)

The function is deployed with **Verify JWT off** because it verifies the Firebase
ID token itself. Do not turn gateway JWT verification on unless the function is
changed to accept Supabase JWTs.

---

## 5. Operator steps

### A. Supabase storage (done — keep it this way)

1. Bucket `clinic-photos` is public-read with the limits above.
2. Keep the broad SELECT policy removed.
3. Do not create client INSERT/UPDATE/DELETE policies; uploads go through the
   Edge Function.
4. After the first real photo upload, open the returned public URL in a private
   browser window and confirm it loads without signing in.
5. Confirm the same URL is what Firestore stores in
   `clinics/{clinicId}.doctorPhotoUrl` (doctor portrait) or
   `clinics/{clinicId}.clinicPhotoUrl` (wide home-card cover).

### B. Deploy the Super Admin console

The build is ready:

```text
D:\Easycheck ONLINE SUPERADMIN\dist
D:\Easycheck ONLINE SUPERADMIN\easycheck-superadmin-dist.zip
```

Netlify CLI is authenticated and the site is linked to
`easycheck-online-superadmin` (site ID
`c8e6b532-8d6c-4ea9-828b-e8a0ec81b306`).

Current blocker: the Netlify account is on the Free plan and deploys are blocked
with `Account credit usage exceeded`. Either add credits or drag the zip contents
onto the Netlify Deploys page.

After deploy:

1. Open `https://easycheck-online-superadmin.netlify.app`.
2. Sign in with the super-admin Google account.
3. Confirm the console loads real Firestore data.
4. Confirm a non-super-admin account is signed out with the clinic-app message.

### C. Super Admin custom claim

The claim is already set for
`9304901506@easycheck.online` (UID `Bir6uGFf3eeYBJoJaTyydRy7ltt1`):

```json
{ "superAdmin": true }
```

To grant or revoke it later, use the service account described in step D:

```powershell
cd "D:\Easycheck ONLINE SUPERADMIN"
npm install --no-save firebase-admin
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\<you>\secrets\easycheck-service-account.json"
npm run grant:superadmin -- admin@example.com
npm run grant:superadmin -- admin@example.com --revoke
```

The user must sign out and sign in again before the new claim appears in the ID
token. Never grant this claim from a Firestore document, email, phone number, or
the app UI.

### D. Create the service account and install the trusted CLI

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

**Security:** the service-account JSON can bypass all security rules. Never
commit it, upload it, paste it into chat, or put it on a shared drive. The
repository ignores `tools/admin_cli/service-account*.json` and `node_modules`.

### E. Retire demo clinics and remove the legacy field

Run these once, after the CLI is connected:

```powershell
node index.js deactivate-clinic CLN-84920 --by "<operatorUid>" --reason "Demo clinic retired"
node index.js deactivate-clinic CLN-84921 --by "<operatorUid>" --reason "Demo clinic retired"
node index.js deactivate-clinic CLN-84922 --by "<operatorUid>" --reason "Demo clinic retired"
node index.js cleanup-admin-uid --by "<operatorUid>"
```

`cleanup-admin-uid` removes the legacy staff identifier from every clinic
document. The app and rules no longer use it, but old documents may still contain
the field until this runs.

### F. Onboard the first real clinic

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
8. Upload a doctor photo and confirm it appears on the patient page.

### G. App Check setup and enforcement

App Check is initialized in the app. Enforcement is intentionally **off** until
the release build with App Check is the build everyone is using.

1. Firebase Console → **Build → App Check → Apps**.
2. Register the Android app with **Play Integrity**.
3. The debug and release SHA-256 fingerprints are already registered in
   **Project settings → Your apps**.
4. Install the debug build on a test phone.
5. Open the app and find the App Check debug token in the device log:

   ```powershell
   adb logcat | Select-String "AppCheck"
   ```

6. Register that token in **App Check → Apps → Manage debug tokens**.
7. Install the signed release build and confirm sign-in and Firestore work.
8. Only then open **App Check → APIs → Firestore** and click **Enforce**.

**Order matters.** Enforcing before the release build and debug tokens are
registered will block real users. Do not enforce during the pilot until the
release APK/AAB is the build everyone is using.

App Check covers Firebase services. It does **not** cover the Supabase Edge
Function. That function is protected independently by Firebase ID-token
verification and the Firestore membership/claim check.

### H. Real-device end-to-end test

See `REAL_DEVICE_TEST_PLAN.md` in this folder. This cannot be completed by the
coding agent because it needs a real Google account, a physical phone, and
Google consent.

### I. Play Store submission

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

### J. Backups, monitoring, and alerts

Firestore scheduled backups and Cloud Monitoring alerts require the Blaze plan.
The project is intentionally staying on the free plan for now. Treat this as an
accepted risk and revisit before real patient volume:

1. **Firestore backups:** enable a daily schedule with at least 7-day retention
   once Blaze is enabled.
2. **Crashlytics alerts:** enable velocity alerts for fatal crashes (available
   without Blaze).
3. **Uptime check:** Google Cloud Console → Monitoring → Uptime checks →
   `https://easycheck-online.web.app`.
4. **Budget alert:** Google Cloud Console → Billing → Budgets & alerts → set a
   monthly budget with 50%, 90%, and 100% alerts.
5. **Supabase free-plan risk:** the Supabase project pauses after one week of
   inactivity, and the free plan includes 1 GB storage / 5 GB egress. Upgrade to
   Pro before relying on photos in production, or keep the project active and
   monitor usage.
6. **Restore drill:** once per quarter, restore a backup into a temporary project
   and verify clinic, membership, and queue data.

### K. Push notifications (not implemented in this pass)

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

## 6. Remaining after this phase

| Item | Owner | Status |
|---|---|---|
| Supabase listing policy removed | Done | Verified |
| Duplicate empty bucket deleted | Done | Verified |
| Signed release APK/AAB + Firebase fingerprints | Done | Verified |
| Deploy Super Admin console | Operator | Blocked by Netlify credits |
| Create service account and run CLI | Operator | Pending |
| Deactivate demo clinics | Operator | Pending |
| Onboard first real clinic | Operator | Pending |
| Real-phone end-to-end test | Operator | Pending |
| App Check debug token + enforcement | Operator | Pending |
| Play Store submission and signing SHA | Operator | Pending |
| Backups, monitoring, budget alerts | Operator | Deferred (Blaze required) |
| Push notifications | Next phase | Not started |
| Version the deployed Edge Function source in the repo | Next phase | Pending |
