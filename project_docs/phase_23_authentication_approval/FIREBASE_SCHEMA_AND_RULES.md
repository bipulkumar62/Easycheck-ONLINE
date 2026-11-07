# Firebase Schema & Security Rules

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 5, 2026  
**Firebase project:** `easycheck-online` (`1085858861836`)  
**Firestore location:** `asia-south1`

---

## 1. Collections

### 1.1 `users`

Document ID: Firebase Auth UID.

| Field | Type | Notes |
|-------|------|-------|
| `email` | string | From Google account |
| `displayName` | string? | From Google account |
| `photoUrl` | string? | From Google account |
| `role` | string | `patient` only on client create |
| `createdAt` | timestamp | Set on create |
| `updatedAt` | timestamp | Set on create/update |
| `isActive` | bool | Must be `true` on create |

Rules:

- Read: only the owner (`request.auth.uid == userId`).
- Create: only the owner, only `role == 'patient'`, only `isActive == true`.
- Update: only the owner, and `role` and `isActive` must be unchanged.
- Delete: denied.

### 1.2 `clinics`

Document ID: `CLN-XXXXX`.

| Field | Type | Notes |
|-------|------|-------|
| `name`, `address`, `city`, `region`, `phone`, `email` | string | Clinic profile |
| `description` | string? | Optional |
| `adminUid` | string | Backend-provisioned primary administrator |
| `isActive` | bool | Clinic availability |
| `isOnline` | bool | Live desk state |
| `doctorName`, `doctorCredentials`, `doctorSpecialty`, `doctorPhotoUrl` | string | Doctor display |
| `doctorStatus` | string | `available`, `delayed`, `offDuty` |
| `doctorTiming` | string | Manually entered OPD hours |
| `todayParchiCount` | int | Live count |
| `yesterdayParchiCount` | int | Previous day |
| `createdAt`, `updatedAt` | timestamp | Audit |

Rules:

- Read: any authenticated user (patient discovery).
- Create: denied.
- Update: authenticated, `adminUid` unchanged, and caller is the clinic owner (`adminUid`) or an active `clinic_admin`.
- Delete: denied.

### 1.3 `clinic_members`

Document ID: `{userId}_{clinicId}`.

| Field | Type | Notes |
|-------|------|-------|
| `userId` | string | Firebase Auth UID |
| `clinicId` | string | Clinic ID |
| `role` | string | `clinic_admin`, `front_desk_lead`, `triage_coordinator` |
| `permissions` | list | Operational permissions |
| `isActive` | bool | Must be true for access |
| `joinedAt` | timestamp | Provisioning time |
| `assignedBy` | string | Trusted backend identifier |

Rules:

- Read: the member themself, or a clinic owner/`clinic_admin` for the same clinic.
- Create, update, delete: **denied to all clients**. Only the Admin SDK / Firebase Console can provision memberships.

### 1.4 `admin_access_requests`

Document ID: `{uid}_{clinicId}`.

| Field | Type | Notes |
|-------|------|-------|
| `uid` | string | Must equal `request.auth.uid` |
| `email` | string | Must equal token email |
| `displayName` | string | Minimum 2 characters |
| `requestedClinicId` | string | `^CLN-[0-9]{5}$`, active clinic |
| `contactNumber` | string | Contact number |
| `status` | string | `pending` on create |
| `createdAt`, `updatedAt` | timestamp | Required timestamps |
| `reviewedAt`, `reviewedBy`, `rejectionReason` | null on create | Backend-only afterwards |

Rules:

- Read: only the applicant.
- Create: only the applicant, deterministic ID, `pending`, exact field allow-list, active clinic, review fields null.
- Update, delete: denied.
- Approval/rejection and membership provisioning: Admin SDK only.

### 1.5 `queue_sessions`

Document ID: `{clinicId}_{YYYY-MM-DD}`.

| Field | Type | Notes |
|-------|------|-------|
| `clinicId` | string | Clinic ID |
| `date` | string | `YYYY-MM-DD` |
| `currentParchaNumber` | int | `>= 0` |
| `status` | string | `active`, `paused`, `closed` |
| `updatedAt` | timestamp | Last update |

Rules:

- Read: any authenticated user.
- Create/update: clinic owner, active `clinic_admin`, or active `front_desk_lead`.
- Delete: denied.

### 1.6 `queue_history`

Immutable audit trail.

| Field | Type | Notes |
|-------|------|-------|
| `clinicId` | string | Clinic ID |
| `performedBy` | string | Must equal caller UID |
| `action` | string | `increment`, `correction`, `reset` |
| Other fields | — | Existing audit fields |

Rules:

- Read: clinic owner or active member of that clinic.
- Create: queue manager, `performedBy == request.auth.uid`, allowed actions.
- Update, delete: denied.

---

## 2. Helper Functions

| Function | Purpose |
|----------|---------|
| `isAuthenticated()` | `request.auth != null` |
| `isSignedInAs(uid)` | Authenticated and UID matches |
| `isValidClinicId(clinicId)` | `^CLN-[0-9]{5}$` |
| `isActiveClinic(clinicId)` | Clinic exists and `isActive == true` |
| `isActiveMember(uid, clinicId)` | Membership exists and `isActive == true` |
| `isClinicAdmin(uid, clinicId)` | Active member with role `clinic_admin` |
| `isClinicOwner(uid, clinicId)` | Clinic `adminUid == uid` |
| `isClinicManager(uid, clinicId)` | Owner or `clinic_admin` |
| `canManageClinic(uid, clinicId)` | Owner, `clinic_admin`, or `front_desk_lead` |
| `canViewClinic(uid, clinicId)` | Owner or active member |

---

## 3. Deny-by-Default

The rules end with:

```rules
match /{document=**} {
  allow read, write: if false;
}
```

Any collection not explicitly matched is inaccessible.

---

## 4. Deployment

Commands executed:

```powershell
firebase deploy --only firestore:rules --project easycheck-online --non-interactive
```

Result:

- Rules compiled successfully.
- Rules released to `cloud.firestore`.
- No index changes were required for the UID-filtered request query.

---

## 5. Seed Data

| Clinic ID | Name | Doctor timing |
|-----------|------|---------------|
| `CLN-84920` | Al-Shifa Family Health Clinic | Mon–Sat · 9:00 AM – 5:00 PM |
| `CLN-84921` | Crescent Memorial Hospital | Mon–Fri · 10:00 AM – 6:00 PM |
| `CLN-84922` | St. Jude Community Medicare | Mon–Sat · 8:30 AM – 2:00 PM |

Seed changes:

- `adminClaimCode` removed from all three documents.
- `doctorTiming` added with correct Unicode (en dash U+2013, middle dot U+00B7).
- `tools/seed_firestore.ps1` updated to write ASCII timing strings to avoid PowerShell 5.1 encoding corruption on re-seed.

---

## 6. Authentication Provider Configuration

`firebase.json`:

```json
{
  "auth": {
    "providers": {
      "googleSignIn": {
        "oAuthBrandDisplayName": "EasyCheck Online",
        "supportEmail": "bipulkumarsiwan6262@gmail.com"
      }
    }
  }
}
```

Deployment and verification:

| Check | Result |
|-------|--------|
| `firebase deploy --only auth` | ✅ Google sign-in enabled |
| `defaultSupportedIdpConfigs/google.com` | ✅ `enabled: true` |
| Email/password sign-up attempt | ✅ Blocked with `OPERATION_NOT_ALLOWED` |
| Anonymous sign-up attempt | ✅ Blocked with `ADMIN_ONLY_OPERATION` |

---

## 7. Notes and Constraints

- Firestore REST cannot combine a document `update` with a `setToServerValue: REQUEST_TIME` transform in a single write. The rules therefore require timestamps to be timestamps but do **not** enforce exact equality with `request.time`. Timestamps are informational; they are not an authorization control.
- `clinic_members` client writes are denied entirely. This is intentional: the first administrators must be provisioned by trusted tooling.
- `clinics.adminUid` cannot be changed by clients, so it cannot be used for self-promotion.
- The request query is filtered by `uid` so it satisfies the read rule and does not require a composite index.
