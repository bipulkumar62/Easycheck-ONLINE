# Closed Testing Playbook — Play Console Requirements

**App:** EasyCheck Online (`com.easycheck.online.easycheck_online`)
**Rejected:** 11 November 2026
**Rejection reason:** Play Console Requirements — new personal developer account closed-testing gate
**Requirement:** at least **12 testers opted in for 14 continuous days** before applying for production access
**Earliest production application:** 14 days after the 12th tester opts in (for example, 26 November 2026 if the test starts on 12 November 2026)

---

## 1. What the rejection means

This is not an app crash or a policy defect in the code. Google requires new **personal**
developer accounts to prove the app has been tested by real users before it can be
released to production. Until the gate is met, Play Console will keep rejecting a
production release under **Play Console Requirements**.

Organization accounts are exempt. If this developer account is personal, the only
compliant path is to run the closed test.

---

## 2. Non-negotiable pre-flight checks

Do these **before** inviting testers. If Google Sign-In fails, the 14-day window is
wasted because testers cannot use the app.

### 2.1 Register all three Play app-signing fingerprints

Play installs are signed by Google's **app signing keys**, not the upload key that signs
the local AAB. New apps use **quantum-ready hybrid signing**, so the Play Console
publishes **three app signing keys**:

| Key | SHA-1 |
|---|---|
| Play app signing key 1 | `35:67:87:04:3D:3E:50:FA:CA:2A:5D:3F:CF:30:42:04:8A:C7:A0:F7` |
| Play app signing key 2 | `03:F8:7F:8E:50:CC:69:DF:1C:C1:80:8F:C9:07:93:39:A0:A0:62:E2` |
| Play app signing key 3 | `32:D3:D2:5B:6A:9E:64:E5:7F:F1:99:53:6F:79:E6:C6:63:41:4F:83` |

The Play Console labels the three keys by signing role; the order shown can differ,
so register **every** SHA-1 listed under **App signing key**. Google's Play App
Signing documentation requires **all three** fingerprints to be registered with API
providers. All three were added to Firebase on **12 November
2026**, together with the existing upload and debug keys:

| Fingerprint | Purpose | Status |
|---|---|---|
| `D7:12:DF:89:04:C7:DE:09:D3:CD:2D:C8:0A:C6:37:85:27:F1:C4:31` | Upload/release key | ✅ Registered |
| `65:B4:62:EA:69:9E:65:F7:20:FF:75:B0:6A:E5:9B:EE:DD:D5:1A:57` | Debug key | ✅ Registered |
| `35:67:87:04:…:A0:F7` | Play app signing key 1 | ✅ Registered |
| `03:F8:7F:8E:…:62:E2` | Play app signing key 2 | ✅ Registered |
| `32:D3:D2:5B:…:4F:83` | Play app signing key 3 | ✅ Registered |

Steps to verify or repeat:

1. Play Console → **Protected with Play → Play Store protection → Manage Play app signing**
   (older consoles: **Test and release → Setup → App integrity → App signing**).
2. Scroll to **App signing key** and copy the **SHA-1** for each of the three keys.
3. Add each SHA-1 in Firebase Console → **Project settings → Your apps → Easycheck
   ONLINE (Android)** → **Add fingerprint** → **Save**.
4. Download the updated `google-services.json` and replace
   `android/app/google-services.json` in this repository.
5. Rebuild: `flutter build appbundle --release`.
6. Upload the new bundle to closed testing.
7. Install from the Play testing link on a real phone and confirm Google Sign-In works.

> CLI equivalent:
>
> ```powershell
> firebase apps:android:sha:create 1:1085858861836:android:f6c366f51fe48bac61ef29 35:67:87:04:3D:3E:50:FA:CA:2A:5D:3F:CF:30:42:04:8A:C7:A0:F7 --project easycheck-online
> firebase apps:android:sha:create 1:1085858861836:android:f6c366f51fe48bac61ef29 03:F8:7F:8E:50:CC:69:DF:1C:C1:80:8F:C9:07:93:39:A0:A0:62:E2 --project easycheck-online
> firebase apps:android:sha:create 1:1085858861836:android:f6c366f51fe48bac61ef29 32:D3:D2:5B:6A:9E:64:E5:7F:F1:99:53:6F:79:E6:C6:63:41:4F:83 --project easycheck-online
> firebase apps:sdkconfig android 1:1085858861836:android:f6c366f51fe48bac61ef29 --project easycheck-online > android/app/google-services.json
> ```
>
> Run these one at a time; parallel Firebase CLI calls can crash on Windows.

### 2.2 Version code

`pubspec.yaml` is now `1.0.1+2`. Every upload needs a higher version code. If Play
already accepted version code 1 for a closed test, version code 2 is safe. If Play
reports a duplicate, bump to `1.0.1+3`.

### 2.3 Legal URLs

Verified live on 12 November 2026:

| Page | URL | Status |
|---|---|---|
| Privacy Policy (Play listing) | `https://sites.google.com/view/easycheck-online/home` | Live |
| Privacy Policy (backup) | `https://easycheck-online.web.app/privacy.html` | Live |
| Terms of Use | `https://easycheck-online.web.app/terms.html` | Live |
| Account deletion | `https://easycheck-online.web.app/delete-account.html` | Live |
| Patient web app | `https://easycheck-online.web.app` | Live |
| Super Admin console | `https://easycheck-superadmin.web.app` | Live |

Support email on the legal pages: `moderndeveloper943@gmail.com`.

### 2.4 App access instructions

Play needs a way to review every login-gated area.

1. Create a dedicated Google account for review, for example
   `easycheck.reviewer@gmail.com`, with a strong password and **no 2FA**.
2. Add it as a closed tester.
3. Sign in once as that account so the patient profile exists.
4. For the clinic-admin flow, provision a real clinic membership:
   - `clinic_members/{uid}_{clinicId}` with role `owner` or `admin`
   - an active clinic owned by that membership
5. In Play Console → **App content → App access**, choose **All or some functionality
   is restricted**, and enter:
   - the reviewer email and password
   - the exact steps: role selection → Doctor/Staff → Google sign-in → dashboard tabs
   - a note that a normal patient account sees only the patient experience
6. Never fake approval inside the client. The reviewer must pass the same Firestore
   authorization checks as a real clinic admin.

### 2.5 Data safety form

The app enables **Firebase Crashlytics** and **Firebase App Check** in release. The
form must declare them. Suggested answers:

| Section | Answer |
|---|---|
| Personal info → Name | Collected; account management and clinic access review |
| Personal info → Email | Collected; sign-in, support and access review |
| Personal info → Photos | Collected if the Google profile photo is stored; profile display |
| Personal info → User IDs | Collected; authorization and clinic membership |
| App activity → Other actions | Collected; queue updates and audit records |
| App info and performance → Crash logs | Collected by Firebase Crashlytics; app stability |
| App info and performance → Diagnostics | Collected; crash and performance diagnostics |
| Device or other IDs | Collected by Crashlytics/App Check; security and diagnostics |
| Data shared with third parties | Service providers only: Google Firebase (auth, database, crash reporting, App Check) and Supabase (image storage); never sold |
| Encrypted in transit | Yes |
| Deletion request | Yes — in-app Settings and the public deletion URL |
| Data collection optional | Account data is required for account features; browsing clinics requires sign-in in this build |

Do **not** submit "No data collected" and do **not** repeat the old "no crash-reporting
SDK" claim from the earlier readiness document.

---

## 3. Set up the closed test

1. Play Console → **Test and release → Testing → Closed testing**.
2. Create a track (for example **Alpha**) if one does not exist.
3. Create a release:
   - Upload `build/app/outputs/bundle/release/app-release.aab`.
   - Add release notes describing the patient and clinic-admin flows.
   - Roll out to the closed track.
4. Open the **Testers** tab:
   - Create an email list or use a Google Group.
   - Add **15–20 testers** to absorb drop-offs; the minimum is 12.
   - Copy the **opt-in URL** and send it to every tester.
5. Confirm each tester:
   - opens the opt-in URL while signed in to the Google account you added
   - accepts the invitation
   - installs EasyCheck from the Play Store link
   - signs in with Google successfully
6. Keep the track, tester list and app installed for **14 continuous days**.

> Removing a tester, asking them to opt out, or replacing the tester list can reset the
> continuous-opt-in clock for those accounts. Recruit a buffer and keep the list stable.

---

## 4. Tester script

Send this to every tester so the feedback is useful for the production-access
application.

1. Install from the Play testing link.
2. Open the app and choose **Patient**; sign in with Google.
3. Check the welcome card, language toggle (हिंदी / EN), clinic search and clinic cards.
4. Open a clinic and confirm live parchi count and doctor timing.
5. Open Settings → Privacy Policy, Terms of Use and Delete account.
6. Switch the language to Hindi and back; confirm the choice survives an app restart.
7. If you were given clinic-admin access: choose **Doctor/Staff**, open the dashboard,
   tap + and − on the counter, change doctor availability, and upload/crop a photo.
8. Report any crash, stuck screen, wrong translation or login failure with a screenshot.

Keep a simple log:

| Date | Tester | Opted in? | Installed? | Signed in? | Notes |
|---|---|---|---|---|---|
| 12 Nov 2026 | | | | | |
| 13 Nov 2026 | | | | | |
| … | | | | | |
| 25 Nov 2026 | | | | | |

---

## 5. Apply for production access

After **14 continuous days with at least 12 opted-in testers**:

1. Play Console → **Testing → Closed testing**.
2. Click **Apply for production access**.
3. Answer the questions honestly:
   - how many testers participated
   - what feedback you received
   - what you changed because of the feedback
   - why the app is ready for production
4. Submit. Google reviews the application; this can take several days.
5. After approval, create a production release with a new version code and roll out.

---

## 6. Common pitfalls

| Pitfall | Prevention |
|---|---|
| Testers only sideload the APK | They must install from the Play testing link so Play records the opt-in |
| Tester opts out or uninstalls permanently | Keep 15–20 testers and check the count daily |
| Google Sign-In fails on Play builds | Register all three Play app-signing SHA-1s in Firebase before inviting testers |
| Reviewer cannot access the admin dashboard | Provision a real clinic membership and document the steps |
| Data safety says "no data collected" | Declare Crashlytics, App Check, account data and queue activity |
| Same version code uploaded twice | Increment `version` in `pubspec.yaml` for every upload |
| Legal URL returns a console or 404 | Keep `privacy.html`, `terms.html` and `delete-account.html` deployed on the patient site |
| Production applied too early | Wait until Play Console shows the 14-day requirement is met |

---

## 7. Current artifacts

| Artifact | Value |
|---|---|
| Closed-test bundle | `build/app/outputs/bundle/release/app-release.aab` |
| Bundle size | 60,901,272 bytes |
| Bundle SHA-256 | `F3096FBC3A8994DD956020713F78D48359292127FBB108D58A8DC9C047B78A74` |
| Direct-install APK | `build/app/outputs/flutter-apk/app-release.apk` |
| APK size | 60,608,718 bytes |
| APK SHA-256 | `775F8DFC4BD5B44BCDA169869B961A542299222D2E01BED97CBD33ACC9DA4D75` |
| Version | `1.0.1+2` |
| Signing certificate | Upload key `D7:12:DF:89:04:C7:DE:09:D3:CD:2D:C8:0A:C6:37:85:27:F1:C4:31` |

Both artifacts were rebuilt on **12 November 2026** after `google-services.json` was
regenerated with all three Play app-signing SHA-1s. The bundle is ready to upload to
closed testing. After installation from Play, verify Google Sign-In on a real phone
before inviting all testers.
