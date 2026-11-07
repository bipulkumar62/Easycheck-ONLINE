# Real-Device End-to-End Test Plan

This test must be run on a physical Android phone with a real Google account.
The coding agent cannot complete it because Google consent, SMS/2FA, and a
physical device are required.

Use the signed release APK:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Record the result for every step. Do not mark a step passed if the expected
result was not observed.

## A. Install and launch

| # | Step | Expected result | Result |
|---|---|---|---|
| A1 | Uninstall any older EasyCheck build, then install the release APK | Install succeeds | |
| A2 | Open the app | Role selection shows “Aap kis roop mein continue karna chahte hain?” with Patient and Doctor/Staff | |
| A3 | Rotate the phone and use 200% font size | No horizontal overflow; buttons stay tappable | |

## B. Patient flow

| # | Step | Expected result | Result |
|---|---|---|---|
| B1 | Choose Patient → Continue with Google | Native Google account picker opens | |
| B2 | Pick a real account and approve | Patient Home opens; no crash | |
| B3 | Close and reopen the app | Session is reused; Patient Home opens without a second consent | |
| B4 | Confirm the clinic list | Only active clinics appear; demo clinics are hidden after deactivation | |
| B5 | Open a clinic | Doctor name, timing, status, and live parchi count match Firestore | |
| B6 | Check the profile avatar | Google photo or fallback icon renders | |
| B7 | Open Privacy Policy and Terms | Full documents open; no stack or vendor details | |

## C. Doctor/staff request flow

Use a second real Google account that has no membership.

| # | Step | Expected result | Result |
|---|---|---|---|
| C1 | Sign out → Doctor/Staff → Google | Account picker opens | |
| C2 | Sign in with the second account | Access request form opens | |
| C3 | Submit a request with a valid contact number | Request saves without the old “same mail” error; submitted screen opens | |
| C4 | Reopen the app | Pending screen opens; no duplicate request is created | |

## D. Approval and provisioning

Run the trusted CLI on the computer.

| # | Step | Expected result | Result |
|---|---|---|---|
| D1 | `node index.js list-requests --status pending` | The request from C3 is listed with the correct clinic | |
| D2 | `node index.js approve "<requestId>" --by "<operatorUid>"` | Command succeeds; membership is created | |
| D3 | On the phone, sign out and sign in again | Clinic admin dashboard opens | |
| D4 | Try to open the dashboard with an account that has no membership | It fails closed and shows the request screen | |

## E. Clinic admin flow

| # | Step | Expected result | Result |
|---|---|---|---|
| E1 | Open Live Queue | Clinic name, doctor greeting, status, and parchi count load | |
| E2 | Increment the parchi count | Count increases once; patient side updates live | |
| E3 | Decrement the count | Count decreases once; history records the correction | |
| E4 | Reset the queue and confirm | Count returns to zero; reset is recorded | |
| E5 | Pause and resume the queue | Status changes; patient side reflects it | |
| E6 | Edit doctor timing | Save succeeds; patient clinic page shows the new text | |
| E7 | Change doctor photo | Gallery opens; upload succeeds; patient page shows the new photo | |
| E8 | Open Staff | Active members are listed; no add/remove controls are exposed | |
| E9 | Open Clinic | Clinic details are read-only; sign out works | |

## F. Account deletion

Use a disposable patient account, not a real clinic owner.

| # | Step | Expected result | Result |
|---|---|---|---|
| F1 | Profile → Delete account → confirm | Google confirmation opens | |
| F2 | Approve the Google confirmation | Profile and sign-in account are deleted; app returns to role selection | |
| F3 | Sign in again with the same Google account | A new empty patient profile is created | |

## G. Failure handling

| # | Step | Expected result | Result |
|---|---|---|---|
| G1 | Turn on airplane mode, then open the app | A clear connection error appears; no crash | |
| G2 | Turn the network back on and retry | Data loads | |
| G3 | Deny notification permission (if prompted) | App continues normally | |
| G4 | Background the app during a queue update | No crash; state is consistent on return | |

## H. Crash reporting

| # | Step | Expected result | Result |
|---|---|---|---|
| H1 | Use the app for 10 minutes after the release build | Firebase Crashlytics shows the app as active | |
| H2 | Force a test crash in a debug build only | Crash appears in Crashlytics within a few minutes | |

## Sign-off

- Phone model:
- Android version:
- App version:
- Tester:
- Date:
- Overall result: PASS / FAIL
- Notes:
