# Admin Access Approval Flow

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 5, 2026

---

## 1. Purpose

This document defines how a doctor/staff account requests clinic access, how the client is prevented from approving itself, and what the future trusted Super Admin backend must do to approve or reject a request safely.

---

## 2. Collections

### 2.1 `admin_access_requests`

Document ID: `{uid}_{clinicId}`  
Example: `k3J9..._CLN-84920`

| Field | Type | Written by | Description |
|-------|------|------------|-------------|
| `uid` | string | Applicant | Firebase Auth UID; must equal `request.auth.uid` |
| `email` | string | Applicant | Must equal the Google token email |
| `displayName` | string | Applicant | Minimum 2 characters |
| `requestedClinicId` | string | Applicant | Must match `^CLN-[0-9]{5}$` and reference an active clinic |
| `contactNumber` | string | Applicant | Contact number |
| `status` | string | Applicant on create only | Must be `pending` on create |
| `createdAt` | timestamp | Applicant | Required timestamp |
| `updatedAt` | timestamp | Applicant | Required timestamp |
| `reviewedAt` | null / timestamp | Super Admin backend | Must be `null` on create |
| `reviewedBy` | null / string | Super Admin backend | Must be `null` on create |
| `rejectionReason` | null / string | Super Admin backend | Must be `null` on create |

### 2.2 `clinic_members`

Document ID: `{uid}_{clinicId}`

| Field | Type | Description |
|-------|------|-------------|
| `userId` | string | Firebase Auth UID |
| `clinicId` | string | Clinic ID |
| `role` | string | `clinic_admin`, `front_desk_lead`, or `triage_coordinator` |
| `permissions` | list | Operational permissions |
| `isActive` | bool | Must be `true` for access |
| `joinedAt` | timestamp | Provisioning time |
| `assignedBy` | string | Trusted backend identifier |

---

## 3. Request Lifecycle

```
none
  │  applicant submits form
  ▼
pending ── Super Admin rejects ──► rejected
  │
  └──── Super Admin approves + provisions membership ──► approved
                                                          │
                                                          ▼
                                                   active membership
                                                          │
                                                          ▼
                                                   admin dashboard
```

### 3.1 Create (`pending`)

- The client may create only a request whose ID is its own UID plus the requested clinic ID.
- `status` must be `pending`.
- `uid` must equal the authenticated UID.
- `email` must equal the authenticated Google token email.
- Review fields must be `null`.
- Only the listed fields are accepted (`hasOnly`).
- The clinic must exist and be active.
- Duplicate creation is denied by the deterministic document ID.

### 3.2 Read

- The applicant may read only requests where `resource.data.uid == request.auth.uid`.
- The Super Admin backend uses the Admin SDK, which bypasses client rules.

### 3.3 Approve / Reject

- **Clients cannot update or delete requests.** `allow update, delete: if false`.
- Only the trusted Super Admin backend (Admin SDK / Cloud Function) can:
  1. Set `status` to `approved` or `rejected`.
  2. Set `reviewedAt`, `reviewedBy`, and optional `rejectionReason`.
  3. On approval, create or activate the matching `clinic_members/{uid}_{clinicId}` document.

The current task does **not** implement this backend. Requests remain `pending` until it exists.

---

## 4. Why Approval and Membership Must Be Atomic

The client resolves access from active memberships and `clinics.adminUid` first, then requests. An `approved` request without a membership resolves to **inconsistent** and is denied. Therefore the future Super Admin backend must:

1. Approve the request.
2. Provision the membership in the same trusted operation (ideally a Firestore transaction or a Cloud Function).

If step 2 fails, the user sees the unauthorized screen rather than a false success. This is deliberate fail-closed behavior.

---

## 5. Super Admin Backend Requirements (Future Task)

### 5.1 Authentication

The backend must authenticate operators independently of the Flutter client. Acceptable options:

- Firebase Admin SDK running in a trusted environment (Cloud Functions, Cloud Run, server).
- A separate Super Admin web app whose operators are verified server-side.
- Custom claims such as `superAdmin: true`, set only by trusted tooling.

The backend must never accept a role, email, or approval flag from the client as proof of authority.

### 5.2 Provisioning runbook (Admin SDK, Node.js)

The following is the required behavior; it is **not yet deployed**.

```js
const admin = require('firebase-admin');
const db = admin.firestore();

async function approveRequest({ requestId, reviewerUid }) {
  const requestRef = db.collection('admin_access_requests').doc(requestId);

  await db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef);
    if (!requestSnap.exists) throw new Error('Request not found');

    const request = requestSnap.data();
    if (request.status !== 'pending') {
      throw new Error('Request is not pending');
    }

    const membershipRef = db
      .collection('clinic_members')
      .doc(`${request.uid}_${request.requestedClinicId}`);

    tx.set(membershipRef, {
      userId: request.uid,
      clinicId: request.requestedClinicId,
      role: 'clinic_admin',
      permissions: [
        'update_tally',
        'update_status',
        'reset_tally',
        'manage_staff',
        'view_queue',
      ],
      isActive: true,
      joinedAt: admin.firestore.FieldValue.serverTimestamp(),
      assignedBy: reviewerUid,
    });

    tx.update(requestRef, {
      status: 'approved',
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy: reviewerUid,
      rejectionReason: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function rejectRequest({ requestId, reviewerUid, reason }) {
  await db.collection('admin_access_requests').doc(requestId).update({
    status: 'rejected',
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    reviewedBy: reviewerUid,
    rejectionReason: reason || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
```

### 5.3 Rejection behavior

- Set `status: 'rejected'`.
- Set `reviewedAt`, `reviewedBy`.
- Optionally set `rejectionReason`.
- Do **not** create a membership.
- The applicant sees `AdminRejectedScreen` on the next resolution.

### 5.4 Re-application

The current client blocks re-submission for a rejected user/clinic pair because the deterministic document already exists. A future Super Admin flow may either:

- allow the backend to reset the existing request to `pending`, or
- add an explicit re-application action with an audited backend endpoint.

This is documented as a limitation in `KNOWN_ISSUES.md`.

---

## 6. Membership Provisioning Without a Request

The trusted backend may also provision a membership directly for an existing clinic owner or staff member. This is required for the initial administrators of the three seeded clinics, because self-claim was retired.

Required steps:

1. Obtain the user’s Firebase UID (from the Firebase Console or the user’s account).
2. Create `clinic_members/{uid}_{clinicId}` with `isActive: true` and a valid role.
3. Optionally set `clinics/{clinicId}.adminUid` to the owner’s UID for the primary administrator.

Client rules deny all membership writes, so this must be done with the Admin SDK or the Firebase Console.

---

## 7. Client Screens and Payloads

| Screen | Payload | Behavior |
|--------|---------|----------|
| Request form | — | Submits pending request |
| Submitted | `AdminAccessFlowArgs` | Shows real request ID/clinic |
| Pending | `AdminAccessFlowArgs` | Re-resolves on “Check status” |
| Rejected | `AdminAccessFlowArgs` | Shows reason when provided |
| Unauthorized | `String? message` | Fail-closed state |

`AdminAccessFlowArgs` carries the request and clinic so the transition does not need an extra read. If the payload is missing, each screen shows a safe fallback rather than fabricated details.

---

## 8. Security Invariants

1. A client can never create a request for another UID.
2. A client can never create a request with `approved` or `rejected` status.
3. A client can never update or delete a request.
4. A client can never read another user’s request.
5. A client can never create, update, or delete a clinic membership.
6. A client can never change `clinics.adminUid`.
7. An `approved` flag alone never grants dashboard access.
8. The dashboard re-resolves authorization on every load and fails closed.
9. The selected role on the entry screen has no authorization effect.
10. Email/password and anonymous sign-in are disabled; Google is the only provider.

These invariants were exercised against the deployed Firestore rules; see `SECURITY_AUDIT.md`.
