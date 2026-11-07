# Next Phase Readiness

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 5, 2026

---

## 1. Readiness Status

| Area | Status |
|------|--------|
| Role selection UI | ✅ Ready |
| Patient Google login | ✅ Ready (provider enabled) |
| Patient profile bootstrap | ✅ Ready |
| Doctor/staff Google login | ✅ Ready (provider enabled) |
| Admin authorization resolution | ✅ Ready |
| Access request form and screens | ✅ Ready |
| Firestore rules | ✅ Deployed and probed |
| Google-only auth | ✅ Enforced |
| Doctor timing | ✅ Implemented and tested |
| Branding / launcher icons | ✅ Regenerated; release APK installed and logo verified |
| Legal pages | ✅ In-app full screen + public `/privacy.html`, `/terms.html`, `/delete-account.html` |
| Account deletion | ✅ Patient self-delete with real Firestore/Auth calls |
| Hosting security headers | ✅ CSP, HSTS, COOP, `X-Frame-Options`, `nosniff`, `Referrer-Policy`, `Permissions-Policy` |
| Web hosting deployment | ✅ Latest build and legal pages deployed |
| Android release artifacts | ✅ Signed release APK and AAB built |
| Play Store assets | ✅ 512 × 512 icon and 1024 × 500 feature graphic |
| Super Admin approval backend | ❌ Not implemented (Task 24) |
| Initial clinic admin provisioning | ❌ Not done (blocked on trusted backend/Console) |
| Interactive Google sign-in verification | ⚠️ Native account picker verified; real-account consent still manual |
| Play Console submission | ❌ Not started |

**Overall:** Task 23 implementation is complete within its stated scope and the Android artifacts are ready for phone testing. Task 24 should not begin until the user approves and the Super Admin backend is planned.

---

## 2. What Task 24 Needs

### 2.1 Super Admin dashboard / backend

Minimum requirements:

1. Trusted operator authentication independent of the Flutter client.
2. List pending requests with applicant, clinic, contact number and submitted time.
3. Approve action that atomically:
   - sets request `status: 'approved'`, `reviewedAt`, `reviewedBy`;
   - creates/activates `clinic_members/{uid}_{clinicId}` with a valid role.
4. Reject action that sets `status: 'rejected'`, `reviewedAt`, `reviewedBy`, optional `rejectionReason`.
5. Audit log of every approval/rejection (operator UID, request ID, timestamp, decision).
6. Server-side authorization; no client-supplied role or email is trusted.

### 2.2 Initial administrator provisioning

Before any admin can use the app, create memberships for the three seeded clinics.

Example (Admin SDK / Console):

```text
clinic_members/{ADMIN_UID}_CLN-84920
  userId: ADMIN_UID
  clinicId: CLN-84920
  role: clinic_admin
  permissions: [update_tally, update_status, reset_tally, manage_staff, view_queue]
  isActive: true
  joinedAt: <server timestamp>
  assignedBy: <trusted operator id>
```

Optionally set `clinics/CLN-84920.adminUid = ADMIN_UID` for the primary owner.

Repeat for `CLN-84921` and `CLN-84922` as needed.

### 2.3 Manual verification checklist

- [ ] Google sign-in consent on the signed Android release APK (native picker already verified).
- [ ] Google sign-in on hosted web app in Chrome.
- [ ] Patient profile created once; second login does not duplicate or overwrite.
- [ ] Doctor/staff with no request sees the access request form.
- [ ] Request submission creates a pending document with the correct UID and clinic.
- [ ] Duplicate submission is blocked.
- [ ] Pending screen appears on the next sign-in.
- [ ] Super Admin approval provisions membership and opens the dashboard.
- [ ] Super Admin rejection shows the rejected screen.
- [ ] Normal patient cannot open the admin panel.
- [ ] Admin edits doctor timing; patient home and clinic details update live.
- [ ] Launcher icon and in-app logo look correct on a real device.
- [ ] Web icons and manifest look correct after deployment.

---

## 3. Recommended Task 24 Scope

1. Build the Super Admin backend (Cloud Functions or trusted server) with:
   - `approveAccessRequest`
   - `rejectAccessRequest`
   - membership provisioning transaction
   - audit logging
2. Build the Super Admin web dashboard.
3. Provision the first administrators for the seeded clinics.
4. Add end-to-end tests for approval → membership → dashboard.
5. Optionally add email notifications.
6. Consider Firebase App Check before public launch.

---

## 4. Constraints to Preserve

- Do not reintroduce self-claim or client-side membership writes.
- Do not trust the role selected on the entry screen.
- Keep the admin dashboard fail-closed.
- Keep Google-only authentication unless the product decision changes.
- Preserve the Stitch visual system.
- Keep approval and membership provisioning atomic.
- Do not fabricate approvals, reviewers, timestamps, or success states.

---

## 5. Approval Gate

Per the task instruction, work stops after Task 23. Task 24 must not begin until the user reviews:

- `TEST_REPORT.md`
- `SECURITY_AUDIT.md`
- `KNOWN_ISSUES.md`
- this readiness document

and explicitly approves the next phase.
