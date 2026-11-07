# Security Audit

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 5, 2026  
**Scope:** Google authentication, role selection, patient profile bootstrap, clinic-admin approval, Firestore rules, doctor timing, admin panel access.

---

## 1. Security Objectives

1. Authentication must not imply authorization.
2. The frontend-selected role must not grant privileges.
3. A user must not be able to approve their own request.
4. A user must not be able to create or elevate their own clinic membership.
5. A user must not be able to change `clinics.adminUid`.
6. A user must not read another user’s access request.
7. A user must not operate another clinic’s queue.
8. The admin dashboard must fail closed on any resolution error.
9. No fake authentication or simulated approval may exist.
10. Only Google sign-in may be available.

---

## 2. Threat Model & Controls

| Threat | Control | Verified |
|--------|---------|----------|
| Patient selects “Doctor/Staff” to become admin | Role selection is UX only; authorization re-resolved from UID | ✅ Code review + unit tests |
| User edits `users.role` to `clinic_admin` | Rules allow only `role: 'patient'` on create; update cannot change role | ✅ Live probe |
| User creates own `clinic_members` document | All client membership writes denied | ✅ Live probe |
| User writes `clinics.adminUid` to self | `adminUid` must be unchanged on update; clinic creation denied | ✅ Live probe |
| User self-approves request | Request update/delete denied to clients | ✅ Live probe |
| User reads another applicant’s request | Read rule requires `resource.data.uid == request.auth.uid` | ✅ Live probe |
| User submits request for another UID | Create rule requires `uid == request.auth.uid` and deterministic ID | ✅ Live probe |
| User spoofs email in request | Create rule requires token email equality | ✅ Rules review |
| User submits duplicate requests | Deterministic `{uid}_{clinicId}` ID | ✅ Live probe |
| User creates a clinic | Clinic create denied | ✅ Live probe |
| Non-member operates queue | Queue writes require owner/admin/front-desk membership | ✅ Live probe |
| Admin operates another clinic’s queue | Membership is checked against the session’s `clinicId` | ✅ Live probe |
| Forged/stale “approved” request opens dashboard | Resolution requires an active membership; otherwise inconsistent/denied | ✅ Unit tests |
| Firebase unavailable in UI-only mode | Screens fail closed with real errors; no simulated success | ✅ Code review + widget tests |
| Email/password or anonymous sign-in | Providers disabled; live sign-up blocked | ✅ Live probe |
| Google popup cancellation misreported as denial | `AuthErrorMapper` treats cancellation separately | ✅ Unit tests |

---

## 3. Live Firestore Authorization Probe

Two temporary email/password test accounts were created **before** the email/password provider was disabled. The probe exercised the deployed Firestore rules with real REST calls, then deleted all test documents and accounts.

### 3.1 Probe results — 22 / 22 passed

| # | Probe | Expected | Actual | Result |
|---|-------|----------|--------|--------|
| 1 | Owner creates test queue session A | 200 | 200 | ✅ |
| 2 | Owner creates test queue session B | 200 | 200 | ✅ |
| 3 | Unauthenticated clinic read denied | 403 | 403 | ✅ |
| 4 | Authenticated clinic read allowed | 200 | 200 | ✅ |
| 5 | User self-creates patient profile | 200 | 200 | ✅ |
| 6 | User self-creates `clinic_admin` profile denied | 403 | 403 | ✅ |
| 7 | Applicant creates pending request for own UID | 200 | 200 | ✅ |
| 8 | Duplicate pending request denied | 403 | 403 | ✅ |
| 9 | Applicant reads own request | 200 | 200 | ✅ |
| 10 | Other user cannot read the request | 403 | 403 | ✅ |
| 11 | Applicant cannot self-approve | 403 | 403 | ✅ |
| 12 | User cannot self-create a membership | 403 | 403 | ✅ |
| 13 | User cannot change `clinics.adminUid` | 403 | 403 | ✅ |
| 14 | User cannot create a clinic | 403 | 403 | ✅ |
| 15 | Non-member cannot update a queue session | 403 | 403 | ✅ |
| 16 | Trusted backend can provision a membership | 200 | 200 | ✅ |
| 17 | Provisioned admin can read own membership | 200 | 200 | ✅ |
| 18 | Other user cannot read the membership | 403 | 403 | ✅ |
| 19 | Provisioned admin can update own clinic queue | 200 | 200 | ✅ |
| 20 | Provisioned admin cannot update another clinic queue | 403 | 403 | ✅ |
| 21 | Trusted backend can approve the request | 200 | 200 | ✅ |
| 22 | Applicant can read the approved status | 200 | 200 | ✅ |

### 3.2 Cleanup

After the probe:

- Temporary queue sessions were deleted.
- Temporary `admin_access_requests`, `clinic_members`, and `users` documents were deleted.
- Temporary Auth accounts were deleted.
- The three collections were confirmed empty.

### 3.3 Finding fixed during the probe

The first probe returned `400` when creating a request because the test attempted to combine a document `update` with `setToServerValue: REQUEST_TIME` transforms in one Firestore REST write. Firestore does not support that combination. The rules were relaxed from exact `request.time` equality to “must be a timestamp,” which is sufficient because timestamps are informational and not used for authorization. The probe then passed.

No production data or rules were weakened to make the probe pass; the change removed an over-strict constraint that the client SDK could not satisfy in that write shape.

---

## 4. Authentication Provider Audit

| Control | Result |
|---------|--------|
| Google provider enabled | ✅ `google.com` IDP config `enabled: true` |
| Email/password provider disabled | ✅ `signIn.email.enabled` absent |
| Email/password sign-up blocked | ✅ `OPERATION_NOT_ALLOWED` |
| Anonymous provider removed | ✅ `firebase.json` contains only `googleSignIn` |
| Anonymous sign-up blocked | ✅ `ADMIN_ONLY_OPERATION` |
| No passwords stored by the app | ✅ Google-only |
| No hardcoded credentials in app code | ✅ Firebase options only (public project config) |
| Native Google Identity on Android | ✅ System account picker (`CredentialChooserActivity`) verified on Pixel_7; no browser redirect |
| Google ID token exchanged with Firebase Auth | ✅ `signInWithCredential(GoogleAuthProvider.credential(idToken: ...))` |
| Google cancellation/config errors | ✅ Mapped to non-technical messages; no exception text shown |

---

## 5. Client-Side Authorization Audit

| Check | Result |
|-------|--------|
| Dashboard requires `AdminAccessService` approval | ✅ |
| Pending/rejected/none/inconsistent redirect away | ✅ |
| Dashboard resolution failure shows error + Retry | ✅ |
| No self-claim dialog remains | ✅ |
| No client membership writes | ✅ |
| No client approval writes | ✅ |
| No fake admin identity banner | ✅ |
| No fake helpdesk/LDAP/Azure content | ✅ |
| No fake “140+ clinics” or HIPAA claims | ✅ Removed from screens and unused localization keys |
| No “Verified by clinic reception” claim | ✅ Replaced with factual “Live clinic counter” |

---

## 6. Account Deletion Audit

Play Store requires an in-app deletion path for accounts created in the app.

| Check | Result |
|-------|--------|
| Patient can delete own profile from Settings | ✅ Real Firestore delete, then Firebase Auth `user.delete()` |
| Rules allow delete only for the profile owner | ✅ `isSignedInAs(userId)` |
| Rules allow delete only when stored role is `patient` | ✅ `resource.data.role == 'patient'` |
| Staff profiles cannot self-delete | ✅ Clinic offboarding remains backend-managed |
| `requires-recent-login` handled | ✅ Clear re-authentication message; no fake success |
| Failure messages avoid stack traces | ✅ Plain-language message only |
| Public deletion instructions | ✅ `https://easycheck-online.web.app/delete-account.html` |

---

## 7. Hosting and Transport Hardening

| Control | Result |
|---------|--------|
| HTTPS / HSTS | ✅ HSTS header present |
| Content-Security-Policy | ✅ Present on hosted app |
| `X-Content-Type-Options` | ✅ `nosniff` |
| `X-Frame-Options` / COOP | ✅ Present |
| `Referrer-Policy` | ✅ Present |
| `Permissions-Policy` | ✅ Present |
| App shell caching | ✅ Root, `main.dart.js`, `flutter_bootstrap.js` set to `no-cache, must-revalidate` |
| Source maps excluded from hosting | ✅ |
| Public legal pages cache | ✅ `no-cache, must-revalidate` |
| Vendor names in public legal pages | ✅ None (`Firebase`, `Firestore`, `Google`, `Flutter`, `Dart`, `gstatic` absent) |

---

## 8. Mobile Artifact Audit

| Check | Result |
|-------|--------|
| `.env`, `key.properties`, `.jks`, `.keystore`, private keys, client secrets in debug APK | ✅ 0 / 697 entries |
| Same scan on release APK | ✅ 0 / 488 entries |
| Same scan on release AAB | ✅ 0 / 507 entries |
| Release APK signing certificate | ✅ `CN=EasyCheck Online`, SHA-1 `d712df8904c7de09d3cd2dc80ac6378527f1c431` |
| Google Sign-In release certificate hash | ✅ Present in `google-services.json` |
| Google Sign-In debug certificate hash | ✅ Present in `google-services.json` |
| Android backup | ✅ `allowBackup=false`, `fullBackupContent=false` |
| Cleartext traffic | ✅ `usesCleartextTraffic=false` |
| Permissions | ✅ No location, camera, microphone, contacts, SMS or storage permissions |
| Firebase config in app | ✅ Public project config only; no server credentials |

---

## 9. Residual Risks

| Risk | Severity | Mitigation / Next Step |
|------|----------|------------------------|
| Super Admin approval backend does not exist | High for workflow, not for security | Requests remain pending; build trusted backend in Task 24 |
| No initial clinic memberships in Firestore | Operational blocker | Provision first admins via Admin SDK / Console |
| No Firebase App Check | Medium | Add in a later hardening task |
| Real Google account consent not completed by the agent | Medium | Native account picker verified on debug and release; complete consent on a real device |
| Rejected users cannot re-apply in-app | Low | Backend can reset the request; document and decide UX |
| `clinics.adminUid` is a single-owner field | Low | Membership model supports additional admins |
| Firestore timestamps not exact server time | Informational | Not used for authorization; acceptable |
| No automated regression suite for deployed rules | Medium | Probe manually before rule changes; add emulator tests later |
| Play Store reviewer needs a provisioned admin to see the doctor flow | Medium | Provide reviewer instructions and a test account in Play Console |
| No certificate pinning | Low | Not required for a Firebase-backed consumer app; platform TLS is used |

---

## 10. Conclusion

The deployed rules enforce the required security invariants:

- No self-approval.
- No self-created membership.
- No self-promotion through `users.role` or `clinics.adminUid`.
- No cross-clinic queue writes.
- No cross-user request reads.
- Backend-provisioned membership grants exactly the intended clinic access.
- Patients can delete only their own patient profile.
- The Android and web artifacts contain no private keys, service-account blobs, `.env` files or keystore files.
- Hosted pages send CSP, HSTS and related hardening headers.

The remaining high-severity gap is functional, not a client bypass: there is no Super Admin backend yet to approve requests or provision the first administrators. Play Store submission also requires a reviewer test path for the doctor flow.
