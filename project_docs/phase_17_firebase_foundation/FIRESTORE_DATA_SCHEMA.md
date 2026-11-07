# Firestore Data Schema

**Phase:** Task 17 — Firebase Project Setup & Backend Architecture  
**Project:** EasyCheck Online  
**Date:** October 31, 2026  
**Database:** Cloud Firestore (default, asia-south1)

---

## 1. Schema Design Principles

| Principle | Application |
|-----------|-------------|
| Unique clinic identifier | Every clinic document has `clinicId` |
| Clinic-scoped data | All queue/session data associated with `clinicId` |
| Cross-clinic isolation | Admin can only access their assigned clinic's data |
| Historical preservation | Daily resets create new documents, never overwrite history |
| Logical consistency | Current parcha number and yesterday's count remain consistent |
| Minimal duplication | No redundant data; references via IDs |
| Query-optimized | Indexes designed around actual app screens |

---

## 2. Collection Structure

```
firestore-root/
├── users/                          # Authenticated users (patients + staff)
├── clinics/                        # Clinic profiles
├── clinic_members/                 # Staff-clinic assignments (RBAC)
├── queue_sessions/                 # Active daily sessions per clinic
├── queue_history/                  # Historical daily snapshots
└── subscriptions/                  # Future phase — clinic subscriptions
```

---

## 3. Collection Details

### 3.1 `users`

Stores authenticated user profiles (both patients and clinic staff).

**Document ID:** `{userId}` (Firebase Auth UID)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `uid` | string | Yes | Firebase Auth UID |
| `email` | string | Yes | User's email address |
| `displayName` | string | No | Display name |
| `role` | string | Yes | `patient` or `clinic_admin` |
| `phoneNumber` | string | No | Phone number |
| `photoUrl` | string | No | Profile photo URL |
| `createdAt` | timestamp | Yes | Account creation time |
| `updatedAt` | timestamp | Yes | Last update time |
| `lastLoginAt` | timestamp | No | Last authentication time |

**Indexes:** None required (single document reads by UID)

---

### 3.2 `clinics`

Stores clinic profiles with operational data.

**Document ID:** `{clinicId}` (e.g., `CLN-84920`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `clinicId` | string | Yes | Unique clinic identifier |
| `name` | string | Yes | Clinic display name |
| `address` | string | Yes | Clinic address |
| `city` | string | Yes | City (e.g., "Lahore") |
| `region` | string | Yes | Region/state (e.g., "Punjab") |
| `phone` | string | No | Contact phone |
| `email` | string | No | Contact email |
| `adminUid` | string | Yes | Primary admin user UID |
| `isActive` | boolean | Yes | Clinic active/inactive status |
| `isOnline` | boolean | Yes | Current online/offline status |
| `currentParchiCount` | integer | Yes | Today's issued token count (default: 0) |
| `yesterdayParchiCount` | integer | Yes | Previous day's verified count (default: 0) |
| `lastResetDate` | timestamp | Yes | Date of last daily reset |
| `timezone` | string | Yes | Clinic timezone (e.g., "Asia/Karachi") |
| `createdAt` | timestamp | Yes | Clinic registration time |
| `updatedAt` | timestamp | Yes | Last update time |

**Indexes:**
- `city` ASC, `isActive` ASC, `updatedAt` DESC
- `adminUid` ASC, `updatedAt` DESC

---

### 3.3 `clinic_members`

Maps staff users to their assigned clinics (RBAC enforcement).

**Document ID:** `{userId}_{clinicId}` (composite key)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | string | Yes | Firebase Auth UID |
| `clinicId` | string | Yes | Assigned clinic ID |
| `role` | string | Yes | `front_desk_lead`, `triage_coordinator`, `clinic_admin` |
| `permissions` | array<string> | Yes | Granted permissions (e.g., `["reset_tally", "update_status"]`) |
| `joinedAt` | timestamp | Yes | Assignment time |
| `isActive` | boolean | Yes | Membership active status |

**Indexes:**
- `userId` ASC, `clinicId` ASC (compound for lookups)
- `clinicId` ASC, `isActive` ASC (list staff by clinic)

---

### 3.4 `queue_sessions`

Stores the active daily queue session per clinic. One document per clinic per day.

**Document ID:** `{clinicId}_{date}` (e.g., `CLN-84920_2026-10-31`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `clinicId` | string | Yes | Associated clinic |
| `date` | string | Yes | Session date (YYYY-MM-DD) |
| `currentParchiNumber` | integer | Yes | Next token number to issue |
| `totalIssuedToday` | integer | Yes | Total tokens issued today |
| `doctorStatus` | string | Yes | `available`, `delayed`, `offDuty` |
| `doctorName` | string | No | Current doctor on duty |
| `doctorRoom` | string | No | Doctor's room number |
| `waitingCount` | integer | Yes | Patients currently waiting |
| `estimatedWaitMinutes` | integer | No | Estimated wait time |
| `lastUpdatedAt` | timestamp | Yes | Last session update |
| `updatedBy` | string | No | UID of staff who last updated |

**Indexes:**
- `clinicId` ASC, `date` ASC (compound for daily lookups)

---

### 3.5 `queue_history`

Stores historical daily snapshots for audit and reporting. Created during daily reset.

**Document ID:** `{clinicId}_{date}` (e.g., `CLN-84920_2026-10-30`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `clinicId` | string | Yes | Associated clinic |
| `date` | string | Yes | Session date (YYYY-MM-DD) |
| `totalIssued` | integer | Yes | Total tokens issued that day |
| `peakWaitMinutes` | integer | No | Maximum wait time recorded |
| `averageWaitMinutes` | number | No | Average wait time |
| `patientsServed` | integer | Yes | Patients marked as served |
| `patientsNoShow` | integer | Yes | Patients who didn't show |
| `doctorStatusChanges` | array | No | Log of status changes with timestamps |
| `resetPerformedAt` | timestamp | Yes | When daily reset occurred |
| `resetPerformedBy` | string | Yes | UID of staff who performed reset |

**Indexes:**
- `clinicId` ASC, `date` DESC (compound for historical lookups)

---

### 3.6 `subscriptions` (Future Phase)

Reserved for clinic subscription management. Not implemented in this phase.

---

## 4. Relationship Diagram

```
users (1) ----< clinic_members (>1) clinics (1)
  |                                        |
  |                                        | (1)
  |                                        v
  |                                    queue_sessions (1)
  |                                        |
  |                                        | (1)
  |                                        v
  |                                    queue_history
```

- **users → clinics:** Many-to-many via `clinic_members` (staff can belong to one clinic; patients belong to none)
- **clinics → queue_sessions:** One-to-many (one active session per clinic per day)
- **queue_sessions → queue_history:** One-to-one (daily snapshot created on reset)

---

## 5. Query Patterns by Screen

| Screen | Query | Collection | Filters |
|--------|-------|------------|---------|
| Patient Home | List active clinics | `clinics` | `isActive == true`, order by `updatedAt` desc |
| Patient Home | Search clinics | `clinics` | `city == selectedCity`, `isActive == true` |
| Clinic Details | Get clinic profile | `clinics` | `clinicId == selectedId` |
| Clinic Details | Get active session | `queue_sessions` | `clinicId == id` AND `date == today` |
| Admin Dashboard | Get clinic stats | `clinics` | `clinicId == adminClinicId` |
| Admin Dashboard | Get today's session | `queue_sessions` | `clinicId == id` AND `date == today` |
| Admin Reset Studio | Get history | `queue_history` | `clinicId == id`, order by `date` desc |

---

## 6. Undecided Fields

| Field | Collection | Reason |
|-------|------------|--------|
| `subscriptionTier` | `clinics` | Future phase — subscription management |
| `paymentStatus` | `clinics` | Future phase — payment integration |
| `smsNotifications` | `clinics` | Not in approved scope |
| `emailNotifications` | `clinics` | Not in approved scope |
| `pushTokens` | `users` | Not in approved scope — no push notification requirements |

---

## 7. Data Integrity Rules

| Rule | Enforcement |
|------|-------------|
| `currentParchiCount` cannot be negative | Firestore Security Rules + client validation |
| `totalIssuedToday` <= `currentParchiNumber` | Security rules validate on write |
| Daily reset preserves history | New `queue_history` document created, old `queue_session` archived |
| Cross-clinic access prevented | Security rules check `clinic_members` for user's clinic |
| Only assigned admin can reset count | Security rules verify `clinic_members.permissions` contains `reset_tally` |
