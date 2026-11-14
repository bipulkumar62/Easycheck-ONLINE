# IMPLICIT STATE MACHINE — Production Audit Report

> **Project:** EasyCheck Online — Real-time Outpatient Clinic Queue Tracking  
> **Stack:** Flutter 3.x · Firebase Auth · Cloud Firestore · Supabase Edge Functions  
> **Audit Date:** 2026-11-13  
> **Auditor Role:** Senior Software Architect & State Management Engineer  
> **Scope:** Read-only. Zero code modifications.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Methodology](#2-methodology)
3. [State Machine Inventory](#3-state-machine-inventory)
   - 3.1 [SM-01: Authentication Flow](#sm-01-authentication-flow)
   - 3.2 [SM-02: Admin Access Resolution](#sm-02-admin-access-resolution)
   - 3.3 [SM-03: Queue Session Lifecycle](#sm-03-queue-session-lifecycle)
   - 3.4 [SM-04: Optimistic Counter](#sm-04-optimistic-counter)
   - 3.5 [SM-05: Clinic Lifecycle](#sm-05-clinic-lifecycle)
   - 3.6 [SM-06: Doctor Status](#sm-06-doctor-status)
   - 3.7 [SM-07: Membership Lifecycle](#sm-07-membership-lifecycle)
   - 3.8 [SM-08: Photo Upload](#sm-08-photo-upload)
   - 3.9 [SM-09: Patient Notification Baseline](#sm-09-patient-notification-baseline)
   - 3.10 [SM-10: Account Deletion Sequence](#sm-10-account-deletion-sequence)
   - 3.11 [SM-11: Locale/Language](#sm-11-localelanguage)
4. [Findings](#4-findings)
5. [State Transition Matrix](#5-state-transition-matrix)
6. [Cross-Machine Interactions](#6-cross-machine-interactions)
7. [Production Readiness Score](#7-production-readiness-score)
8. [Recommendations Summary](#8-recommendations-summary)

---

## 1. Executive Summary

This audit identifies **11 implicit state machines** embedded across the EasyCheck Online codebase. Of these, only **1** uses an explicit enum (`AdminAccessState`). The remaining **10** are implemented as loose boolean flags, string comparisons, or multi-variable combinations that form hidden state spaces.

The audit uncovered **14 findings**: **4 CRITICAL**, **5 HIGH**, **3 MEDIUM**, and **2 LOW**. The most dangerous patterns are:

- A **zombie lockout trap** in the admin access state machine where a removed member can never re-apply.
- A **non-transactional check-then-act race** in queue session creation that can produce duplicate sessions.
- **Overlapping concurrency guards** (`_busy` + `_counterSyncing`) in the optimistic counter that can deadlock the UI.
- A **non-atomic multi-step deletion sequence** for patient accounts with partial-failure risks.

**Production Readiness Score: 52 / 100**

---

## 2. Methodology

### Severity Classification

| Level | Definition |
|-------|-----------|
| **CRITICAL** | Can cause data corruption, permanent user lockout, financial impact, or silent data loss in production. |
| **HIGH** | Causes incorrect behavior, stale state, or security bypass under realistic conditions. |
| **MEDIUM** | Edge case that produces confusing UX or minor inconsistency under specific circumstances. |
| **LOW** | Code smell, missing validation, or theoretical issue unlikely to manifest without deliberate effort. |

### Approach

1. **Inventory** — Identify every entity that transitions through distinct states (explicit enums, string statuses, boolean flags, multi-variable combinations).
2. **Map** — Document all states, valid transitions, guards, and side effects.
3. **Audit** — Check for impossible states, missing transitions, unguarded mutations, race conditions, and cross-machine contradictions.
4. **Score** — Deduct from a base of 100 per finding severity.

---

## 3. State Machine Inventory

### SM-01: Authentication Flow

**Location:** [patient_login_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/patient_login_screen.dart), [admin_login_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_login_screen.dart), [auth_gate_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/auth_gate_screen.dart)

**Type:** Implicit — multiple `bool` flags + nullable error string

**State Variables:**
| Variable | Type | Location |
|----------|------|----------|
| `_isSigningIn` | `bool` | Login screens |
| `_error` | `String?` | Login screens |
| `_hasSignedInAccount` | `bool` | Login screens |

**Derived State Space (2³ = 8 combinations):**

| `_isSigningIn` | `_error` | `_hasSignedInAccount` | Semantic State | Valid? |
|:-:|:-:|:-:|---|:-:|
| `false` | `null` | `false` | **Idle** — awaiting user tap | ✅ |
| `true` | `null` | `false` | **Signing In** — spinner visible | ✅ |
| `false` | `non-null` | `false` | **Error** — message shown | ✅ |
| `false` | `null` | `true` | **Signed In** — navigating away | ✅ |
| `true` | `non-null` | `false` | ⚠️ Signing in AND error shown | ❌ |
| `true` | `null` | `true` | ⚠️ Still signing in but already signed in | ❌ |
| `false` | `non-null` | `true` | ⚠️ Error shown but signed in | ❌ |
| `true` | `non-null` | `true` | ⚠️ All flags active — impossible | ❌ |

**Transitions:**
```
Idle ──[tap sign-in]──▶ SigningIn ──[success]──▶ SignedIn
                                  ──[failure]──▶ Error ──[tap retry]──▶ SigningIn
```

**Issues:** No guard prevents the 4 invalid combinations. Each variable is set independently via `setState()`, so a cancelled future or rapid double-tap could momentarily reach an invalid state. See [Finding F-01](#f-01).

---

### SM-02: Admin Access Resolution

**Location:** [admin_access_service.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_access_service.dart)

**Type:** Explicit enum — `AdminAccessState`

**States:**
```
┌─────────────────────────────────────────────────────────────────────┐
│                        AdminAccessState                            │
│                                                                    │
│  ┌──────┐   ┌─────────┐   ┌──────────┐   ┌──────┐   ┌──────────┐ │
│  │ none │   │ pending │   │ approved │   │ rejected│  │ inactive │ │
│  └──┬───┘   └────┬────┘   └────┬─────┘   └───┬────┘  └────┬─────┘ │
│     │            │             │              │            │       │
│     │            │             │              │            │       │
│     │       ┌────┴─────────────┴──────────────┘            │       │
│     │       │        ┌──────────────┐                      │       │
│     │       │        │ inconsistent │ ◀── TRAP             │       │
│     │       │        └──────────────┘                      │       │
│     │       │                                              │       │
└─────┴───────┴──────────────────────────────────────────────┴───────┘
```

**Resolution Logic** (from [admin_access_service.dart L77-143](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_access_service.dart#L77-L143)):

1. Fetch all memberships for UID.
2. For each membership, fetch the linked clinic.
3. If any clinic has `isActive == true` → **approved**.
4. If clinic exists but `isActive == false` → **inactive** (first match saved).
5. If no active membership found, check access requests.
6. If newest request is `pending` → **pending**.
7. If newest request is `rejected` → **rejected**.
8. If newest request is `approved` but no active membership → **inconsistent** ← TRAP.
9. If no memberships and no requests → **none**.

**Issues:** The `inconsistent` state has no programmatic exit. See [Finding F-02](#f-02).

---

### SM-03: Queue Session Lifecycle

**Location:** [queue_session_model.dart](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_session_model.dart), [queue_repository.dart](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart)

**Type:** String-based — `status` field with `validStatuses` list

**States:** `active` | `paused` | `closed`

**Transition Diagram:**
```
                    ┌──────────────────────┐
                    │                      │
     ┌──────────────▼──┐    ┌──────────┐   │
     │     active      │◀──▶│  paused   │   │
     │ (counter runs)  │    │ (frozen)  │   │
     └───────┬─────────┘    └──────────┘   │
             │                             │
             ▼                             │
     ┌──────────────────┐                  │
     │     closed       │──[reset]─────────┘
     │ (day ended)      │
     └──────────────────┘
```

**Mutations & Guards:**

| Operation | Guard | Transaction? | Source |
|-----------|-------|:---:|--------|
| `incrementParcha()` | `session.status != 'active'` → throw | ✅ | [queue_repository.dart L72-128](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L72-L128) |
| `decrementParcha()` | `currentParchaNumber <= 0` → return 0 | ✅ | [queue_repository.dart L131-171](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L131-L171) |
| `resetParcha()` | None — always succeeds, forces `active` | ✅ | [queue_repository.dart L174-221](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L174-L221) |
| `updateSessionStatus()` | `validStatuses.contains(status)` | ❌ | [queue_repository.dart L344-362](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L344-L362) |
| `getOrCreateTodaySession()` | None — check-then-set | ❌ | [queue_repository.dart L46-70](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L46-L70) |

**Issues:**
- `decrementParcha()` does NOT check `session.status != 'active'` — counter can be decremented on a paused/closed session. See [Finding F-03](#f-03).
- `getOrCreateTodaySession()` is non-transactional — race condition on first load. See [Finding F-04](#f-04).
- `resetParcha()` unconditionally sets status to `active` — a `closed` session can be reopened. See [Finding F-05](#f-05).
- `updateSessionStatus()` accepts any valid string without transition validation — `closed → active` is allowed. See [Finding F-06](#f-06).

---

### SM-04: Optimistic Counter

**Location:** [admin_dashboard_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart)

**Type:** Implicit — 4+ interacting variables

**State Variables:**
| Variable | Type | Purpose |
|----------|------|---------|
| `_count` | `int` | Displayed value (optimistic) |
| `_lastServerCount` | `int` | Last confirmed Firestore value |
| `_pendingCounterDelta` | `int` | Uncommitted local delta |
| `_counterSyncing` | `bool` | True during Firestore write |
| `_busy` | `bool` | General UI busy flag |

**Interaction Model:**
```
User Tap (+1)
    │
    ▼
_count++ (optimistic)
_pendingCounterDelta++
    │
    ├── if !_counterSyncing && !_busy:
    │       _counterSyncing = true
    │       _busy = true
    │       ▼
    │   Firestore transaction (incrementParcha)
    │       │
    │       ├── success: _lastServerCount = result
    │       │            _counterSyncing = false
    │       │            _busy = false
    │       │            _pendingCounterDelta = 0
    │       │
    │       └── failure: _count = _lastServerCount
    │                    _counterSyncing = false
    │                    _busy = false
    │                    _pendingCounterDelta = 0
    │
    └── if _counterSyncing || _busy:
            delta buffered, next tap queued
```

**Issues:** `_busy` and `_counterSyncing` are overlapping guards with different semantics but identical lifecycles in the counter path. See [Finding F-07](#f-07).

---

### SM-05: Clinic Lifecycle

**Location:** [clinic_model.dart](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_model.dart), [clinic_repository.dart](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_repository.dart)

**Type:** Implicit — 2 boolean flags

**State Variables:** `isActive` (bool) × `isOnline` (bool)

**State Space (2² = 4 combinations):**

| `isActive` | `isOnline` | Semantic State | Reachable? |
|:--:|:--:|---|:--:|
| `true` | `true` | **Fully Operational** — visible to patients, queue running | ✅ |
| `true` | `false` | **Offline** — admin paused, patients see "offline" | ✅ |
| `false` | `true` | ⚠️ **Deactivated but online** — contradictory | ❓ |
| `false` | `false` | **Deactivated** — hidden from discovery | ✅ |

**Transitions:**
- Admin dashboard toggles `isOnline` independently.
- Admin CLI `deactivate-clinic` sets both to `false` atomically.
- No CLI or UI sets `isActive = false` while preserving `isOnline = true`, but no guard prevents it via direct Firestore mutation.

**Issues:** The `isActive=false, isOnline=true` state is unguarded. See [Finding F-08](#f-08).

---

### SM-06: Doctor Status

**Location:** [admin_dashboard_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart)

**Type:** String-based — passed to `updateClinic()`

**States:** `available` | `delayed` | `offDuty`

**Transition Diagram:**
```
    available ◀──────▶ delayed
        │                │
        ▼                ▼
           offDuty
        ▲                ▲
        │                │
    available ◀──────▶ delayed
```

All transitions are valid — any state can transition to any other state. The status is set via `_setDoctorStatus(String)` which calls `updateClinic()`.

**Issues:** No validation at the repository layer — any string is accepted. See [Finding F-09](#f-09).

---

### SM-07: Membership Lifecycle

**Location:** [clinic_membership_model.dart](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_membership_model.dart), [clinic_membership_repository.dart](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_membership_repository.dart)

**Type:** Implicit — single boolean flag

**States:** `isActive: true` (active member) | `isActive: false` (deactivated)

**Interaction with Access Requests:**
```
     ┌───────────┐        ┌──────────────┐
     │ No Record │──req──▶│   pending    │
     └───────────┘        └──────┬───────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
            ┌─────────────┐          ┌──────────────┐
            │  approved   │          │   rejected   │
            │  + member   │          │  (dead end)  │
            │  created    │          └──────────────┘
            └──────┬──────┘
                   │
          ┌────────┴────────┐
          ▼                 ▼
   ┌────────────┐   ┌──────────────┐
   │   active   │   │ deactivated  │
   │ isActive=T │   │ isActive=F   │
   └────────────┘   └──────┬───────┘
                           │
                    request still "approved"
                           │
                           ▼
                   ┌───────────────┐
                   │ INCONSISTENT  │ ← ZOMBIE TRAP
                   │ (no exit)     │
                   └───────────────┘
```

**Issues:** Deactivating a member does not revoke or reset their access request. See [Finding F-02](#f-02).

---

### SM-08: Photo Upload

**Location:** [admin_dashboard_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart)

**Type:** Implicit — 2 independent boolean flags

**State Variables:**
| Variable | Type | Purpose |
|----------|------|---------|
| `_isUploadingPhoto` | `bool` | Doctor profile photo upload in progress |
| `_isUploadingClinicPhoto` | `bool` | Clinic banner photo upload in progress |

**State Space (2² = 4 combinations):**

| `_isUploadingPhoto` | `_isUploadingClinicPhoto` | Semantic State | Valid? |
|:--:|:--:|---|:--:|
| `false` | `false` | Idle | ✅ |
| `true` | `false` | Doctor photo uploading | ✅ |
| `false` | `true` | Clinic photo uploading | ✅ |
| `true` | `true` | Both uploading concurrently | ✅ |

All 4 states are intentionally valid — the two uploads are independent operations to different Supabase endpoints. No cross-contamination risk.

**Issues:** Minor — no timeout or cancellation mechanism for stalled uploads. See [Finding F-10](#f-10).

---

### SM-09: Patient Notification Baseline

**Location:** [patient_home_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart)

**Type:** Implicit — 4 boolean flags forming a priming sequence

**State Variables:**
| Variable | Type | Purpose |
|----------|------|---------|
| `_notificationBaselineReady` | `bool` | Master gate — baseline collection complete |
| `_clinicBaselineEstablished` | `bool` | Clinic list snapshot captured |
| `_countBaselineReady` | `bool` | Queue count snapshot captured |
| `_countBaselineEstablished` | `bool` | Count baseline committed |

**Priming Sequence:**
```
App Start
    │
    ▼
_clinicBaselineEstablished = false
_countBaselineReady = false
_countBaselineEstablished = false
_notificationBaselineReady = false
    │
    ├── Clinic stream first emission ──▶ _clinicBaselineEstablished = true
    │
    ├── Count stream first emission ──▶ _countBaselineReady = true
    │                                          │
    │                            if _clinicBaselineEstablished:
    │                                          │
    │                                          ▼
    │                              _countBaselineEstablished = true
    │                              _notificationBaselineReady = true
    │
    └── Subsequent emissions: if _notificationBaselineReady → show notification
```

**Issues:** The ordering dependency (`_clinicBaselineEstablished` must be `true` before `_countBaselineEstablished` can be set) creates a timing-dependent initialization. If the count stream emits before the clinic stream, `_countBaselineReady` is set but `_countBaselineEstablished` remains `false`. The next count emission will not re-check. See [Finding F-11](#f-11).

---

### SM-10: Account Deletion Sequence

**Location:** [patient_home_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart), [user_profile_repository.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/user_profile_repository.dart)

**Type:** Implicit — sequential multi-step operation guarded by single `_isDeletingAccount` flag

**Steps:**
```
Step 1: _isDeletingAccount = true
    │
    ▼
Step 2: Re-authenticate Google credential
    │
    ├── failure ──▶ show error, _isDeletingAccount = false
    │
    ▼
Step 3: Delete user profile from Firestore (hard delete)
    │
    ├── failure ──▶ show error, _isDeletingAccount = false
    │               ⚠️ Re-auth succeeded but profile NOT deleted
    │
    ▼
Step 4: Delete Firebase Auth account
    │
    ├── failure ──▶ show error, _isDeletingAccount = false
    │               ⚠️ Profile DELETED but auth account STILL EXISTS
    │               ⚠️ ORPHANED AUTH ACCOUNT — cannot recover
    │
    ▼
Step 5: Navigate to login screen
```

**Issues:** Steps 3 and 4 are not atomic — partial failure leaves the system in an irrecoverable state. See [Finding F-12](#f-12).

---

### SM-11: Locale/Language

**Location:** [locale_controller.dart](file:///d:/Easycheck%20ONLINE/lib/app/localization/locale_controller.dart)

**Type:** Explicit — `Locale` object persisted in `SharedPreferences`

**States:** `hi` (Hindi) | `en` (English)

**Transitions:** `setLocale(Locale)` → persist to SharedPreferences → notify listeners → rebuild UI.

**Issues:** None. This is a well-implemented, simple two-state machine with consistent persistence.

---

## 4. Findings

### F-01

**ID:** F-01  
**Severity:** 🟡 MEDIUM  
**Title:** Authentication login uses independent boolean flags without invalid-state guards  
**State Machine:** SM-01 (Authentication Flow)  
**Location:** [patient_login_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/patient_login_screen.dart), [admin_login_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_login_screen.dart)

**Description:**  
Three independent boolean variables (`_isSigningIn`, `_error`, `_hasSignedInAccount`) form an 8-combination state space where only 4 combinations are semantically valid. No assertions, guards, or state class prevents reaching the 4 invalid combinations.

**Risk:**  
A rapid double-tap on the sign-in button during a slow network response could set `_isSigningIn = true` twice, and if the first attempt completes with an error while the second is in-flight, `_error` and `_isSigningIn` could both be non-null simultaneously, showing an error message behind a spinner.

**Evidence:**  
Each variable is set independently via `setState()` without checking the others.

**Impact:** Confusing UI state — spinner + error shown simultaneously. No data corruption.

---

### F-02

**ID:** F-02  
**Severity:** 🔴 CRITICAL  
**Title:** Zombie lockout trap — `inconsistent` state has no programmatic exit  
**State Machine:** SM-02 (Admin Access Resolution) + SM-07 (Membership Lifecycle)  
**Location:** [admin_access_service.dart L129-138](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_access_service.dart#L129-L138)

**Description:**  
When an admin removes a clinic member via `remove-member` CLI or deactivates their membership (`isActive = false`), the access request document retains `status: approved`. On the next login, `resolveUid()` finds no active membership but finds an `approved` request → returns `AdminAccessState.inconsistent`.

The `inconsistent` state displays "Ask your clinic administrator to activate your membership" but:
1. There is no `revoked` status in `AdminAccessRequestStatus` enum.
2. The user cannot submit a new access request while an `approved` one exists.
3. No CLI command or UI action resets the request status.

**Risk:**  
The user is permanently locked out of the admin experience. The only recovery is direct Firestore document manipulation by a developer. In a production clinic, a removed staff member who is later re-hired cannot regain access through normal workflows.

**Evidence:**
```dart
// admin_access_service.dart L129-138
case AdminAccessRequestStatus.approved:
  return AdminAccessResolution(
    state: AdminAccessState.inconsistent,
    // ...
    message: 'Your access request was approved, but no active clinic '
        'membership was found. Ask your clinic administrator to '
        'activate your membership, then try again.',
  );
```

The `AdminAccessRequestStatus` enum contains only: `pending`, `approved`, `rejected`. No `revoked` or `cancelled` state exists.

**Impact:** Permanent user lockout. Staff cannot be cycled (remove → re-add) without database intervention.

---

### F-03

**ID:** F-03  
**Severity:** 🟠 HIGH  
**Title:** `decrementParcha()` ignores session status — counter can be decremented on paused/closed sessions  
**State Machine:** SM-03 (Queue Session Lifecycle)  
**Location:** [queue_repository.dart L131-171](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L131-L171)

**Description:**  
`incrementParcha()` correctly guards with `if (session.status != 'active') throw ...` at [line 103](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L103-L104). However, `decrementParcha()` has no equivalent guard. An admin can decrement the counter on a paused or closed session.

**Risk:**  
A paused queue (intended to freeze the count while the doctor is on break) can still have its counter decremented, creating an inconsistent patient experience — the displayed count changes even though the queue is "frozen."

**Evidence:**
```dart
// incrementParcha() — HAS guard:
if (session.status != 'active') {
  throw const ServerFailure('Queue session is not active');
}

// decrementParcha() — NO guard:
if (session.currentParchaNumber <= 0) return 0;  // only checks lower bound
```

**Impact:** Queue integrity violation during paused/closed sessions.

---

### F-04

**ID:** F-04  
**Severity:** 🔴 CRITICAL  
**Title:** `getOrCreateTodaySession()` has a non-transactional check-then-act race condition  
**State Machine:** SM-03 (Queue Session Lifecycle)  
**Location:** [queue_repository.dart L46-70](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L46-L70)

**Description:**  
The method first calls `getSession()` (a separate read), then if `null`, creates a new session with `col.doc(...).set()`. These are two independent Firestore operations, not wrapped in a transaction.

```dart
final existing = await getSession(clinicId, date);   // Read
if (existing != null) return existing;
// ... gap where another call can also read null ...
await col.doc(_sessionId(clinicId, date)).set(newSession.toMap());  // Write
```

If two admin devices open the dashboard simultaneously at the start of a day, both can read `null` and both can create a session. The second `.set()` overwrites the first, potentially resetting the counter to 0 if the first had already incremented.

**Risk:**  
Counter reset on first day use when multiple admin devices are active. Patient queue numbers are lost.

**Evidence:**  
Compare with `incrementParcha()` which correctly uses `fs.runTransaction()` at [line 80](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L80).

**Impact:** Silent counter reset. Patients who already received parchi numbers see the count drop to 0.

---

### F-05

**ID:** F-05  
**Severity:** 🟠 HIGH  
**Title:** `resetParcha()` unconditionally reopens closed sessions  
**State Machine:** SM-03 (Queue Session Lifecycle)  
**Location:** [queue_repository.dart L174-221](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L174-L221)

**Description:**  
`resetParcha()` always sets `'status': 'active'` regardless of the current session status. A `closed` session (day ended) can be silently reopened by a reset.

```dart
transaction.set(sessionRef, {
  // ...
  'status': 'active',  // always active, ignoring current status
  // ...
}, SetOptions(merge: true));
```

**Risk:**  
An admin accidentally resetting a closed session re-opens it, making yesterday's (or earlier) session appear as today's queue. Patients see conflicting information.

**Impact:** Session lifecycle integrity violation. Closed sessions should not be reopenable without explicit confirmation.

---

### F-06

**ID:** F-06  
**Severity:** 🟡 MEDIUM  
**Title:** `updateSessionStatus()` allows any valid status string without transition validation  
**State Machine:** SM-03 (Queue Session Lifecycle)  
**Location:** [queue_repository.dart L344-362](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L344-L362)

**Description:**  
The method validates that the status is one of `['active', 'paused', 'closed']` but does not enforce transition rules. Any state can transition to any other state:
- `closed → active` (reopening a closed session)
- `closed → paused` (pausing an already-ended session)
- `paused → closed` (closing without resuming)

```dart
if (!QueueSessionModel.validStatuses.contains(status)) {
  throw const ServerFailure('Invalid session status');
}
// No current-state check. No transition validation.
await col.doc(_sessionId(clinicId, date)).update({
  'status': status,
  // ...
});
```

**Risk:**  
Invalid lifecycle transitions are silently accepted. The session state can be arbitrarily jumped to any valid value without following the intended `active ↔ paused → closed` progression.

**Impact:** Weak lifecycle enforcement. Combined with F-05, a closed session can be fully reopened through multiple paths.

---

### F-07

**ID:** F-07  
**Severity:** 🟠 HIGH  
**Title:** Overlapping concurrency guards `_busy` and `_counterSyncing` with divergent semantics  
**State Machine:** SM-04 (Optimistic Counter)  
**Location:** [admin_dashboard_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart)

**Description:**  
Two boolean flags guard the counter sync operation:
- `_busy` — general UI busy flag used across multiple operations (photo upload, status changes, etc.)
- `_counterSyncing` — specific to Firestore counter writes

Both are checked before initiating a counter sync (`if (_counterSyncing || _busy) return`), and both are set/cleared together in the counter path. However, `_busy` is also set by non-counter operations. If a photo upload sets `_busy = true`, counter taps are silently dropped even though the counter path is free.

**Risk:**  
- During a slow photo upload, rapid parchi taps are silently ignored — the admin thinks the count is incrementing but it is not.
- If `_busy` is set but `_counterSyncing` is not (e.g., during a doctor status update), the counter appears frozen with no user feedback.

**Evidence:**  
`_busy` is a shared flag across multiple unrelated async operations in the ~2500-line dashboard screen.

**Impact:** Silent data loss — admin taps are dropped without feedback. Patient counts are lower than expected.

---

### F-08

**ID:** F-08  
**Severity:** 🟡 MEDIUM  
**Title:** Contradictory clinic state `isActive=false, isOnline=true` is unguarded  
**State Machine:** SM-05 (Clinic Lifecycle)  
**Location:** [clinic_model.dart](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_model.dart), [clinic_repository.dart](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_repository.dart)

**Description:**  
The `deactivate-clinic` CLI correctly sets both `isActive = false` and `isOnline = false`. However, no guard prevents a direct Firestore write (or a future UI feature) from setting `isActive = false` while leaving `isOnline = true`.

In this contradictory state:
- The admin access service would return `inactive` (checking `isActive`).
- Patient discovery queries filtering on `isOnline` would still show the clinic.
- Patients would see an "online" clinic that no admin can manage.

**Risk:**  
Low probability through normal workflows. Higher risk with direct Firestore mutations or future feature additions that modify flags independently.

**Impact:** Patients see a ghost clinic — online but unmanned.

---

### F-09

**ID:** F-09  
**Severity:** 🟢 LOW  
**Title:** Doctor status accepts arbitrary strings at the repository layer  
**State Machine:** SM-06 (Doctor Status)  
**Location:** [admin_dashboard_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart)

**Description:**  
`_setDoctorStatus()` passes a string to `updateClinic()` which writes it directly to Firestore. The UI constrains the options to `available`, `delayed`, `offDuty` via a dropdown, but no server-side or repository-level validation prevents an arbitrary string.

**Risk:**  
Minimal through normal UI. A compromised client or direct API call could set `doctorStatus` to an invalid value like `on-vacation`, which the patient home screen would display raw or fail to match in its status-to-label mapping.

**Impact:** Cosmetic — patient sees an unknown doctor status string. No data corruption.

---

### F-10

**ID:** F-10  
**Severity:** 🟢 LOW  
**Title:** Photo upload has no timeout or cancellation mechanism  
**State Machine:** SM-08 (Photo Upload)  
**Location:** [admin_dashboard_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart)

**Description:**  
`_isUploadingPhoto` and `_isUploadingClinicPhoto` are set to `true` before the upload and `false` in a `finally` block. However, if the Supabase Edge Function hangs (no response, no timeout), the flag remains `true` indefinitely, and the UI shows a permanent spinner with no way to cancel.

**Risk:**  
On unstable mobile networks, a stalled upload locks the UI into a permanent uploading state until the screen is popped and re-entered.

**Impact:** UX degradation — permanent spinner. No data corruption.

---

### F-11

**ID:** F-11  
**Severity:** 🟠 HIGH  
**Title:** Notification baseline priming has timing-dependent initialization order  
**State Machine:** SM-09 (Patient Notification Baseline)  
**Location:** [patient_home_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart)

**Description:**  
The baseline priming sequence requires `_clinicBaselineEstablished = true` before count baseline can be committed. If the queue count Firestore stream emits its first snapshot before the clinic list stream, the count baseline is marked as "ready" (`_countBaselineReady = true`) but not "established" because the clinic gate is still closed.

The next count emission does not re-check `_clinicBaselineEstablished`, so if clinics load after the second count emission, the notification baseline is never fully established. The patient never receives queue update notifications for that session.

**Risk:**  
On slow networks where Firestore streams initialize in non-deterministic order, patients may silently never receive notifications. This is especially problematic on mobile networks where stream initialization timing varies significantly.

**Impact:** Silent notification failure — patient misses queue updates. No error is shown.

---

### F-12

**ID:** F-12  
**Severity:** 🔴 CRITICAL  
**Title:** Account deletion is a non-atomic multi-step sequence with irrecoverable partial failure  
**State Machine:** SM-10 (Account Deletion Sequence)  
**Location:** [patient_home_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart), [user_profile_repository.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/user_profile_repository.dart)

**Description:**  
The deletion sequence executes 3 steps sequentially: re-authenticate → delete Firestore profile → delete Firebase Auth account. If step 3 fails (e.g., network error after step 2 succeeds):

- The Firestore profile document is **permanently deleted** (hard delete).
- The Firebase Auth account **still exists** — the user can still sign in.
- On next sign-in, the app has no profile document → undefined behavior.
- The user cannot re-delete because the profile is already gone.
- No rollback mechanism exists.

**Risk:**  
Any network interruption between Firestore delete and Auth delete creates an orphaned authentication account with no recoverable profile. The user exists in Firebase Auth but has no application data.

**Evidence:**  
The profile deletion in `user_profile_repository.dart` is a hard delete (`doc.delete()`), not a soft delete. There is no compensating transaction or saga pattern.

**Impact:** Irrecoverable data loss. Orphaned auth account. User trapped in broken state.

---

### F-13

**ID:** F-13  
**Severity:** 🔴 CRITICAL  
**Title:** No `authStateChanges()` listener — auth state transitions are invisible across tabs/sessions  
**State Machine:** SM-01 (Authentication Flow) — cross-cutting  
**Location:** [auth_gate_screen.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/auth_gate_screen.dart)

**Description:**  
The app does not subscribe to `FirebaseAuth.instance.authStateChanges()`. When a user signs out on one tab/device, other active tabs/sessions continue operating with the stale auth state. The `AuthGateScreen` only checks auth state on initial load, not reactively.

**Risk:**  
- An admin signs out on their phone but their desktop session continues to increment queue counters — Firestore security rules may reject the writes (if the token expires), but the optimistic UI shows success while data is silently lost.
- A patient deletes their account on one tab while another tab continues to show their profile and clinics.

**Evidence:**  
No `authStateChanges()` subscription found anywhere in the codebase. The `auth_gate_screen.dart` uses a one-shot `FirebaseAuth.instance.currentUser` check.

**Impact:** Ghost sessions operating with revoked credentials. Silent write failures with optimistic UI.

---

### F-14

**ID:** F-14  
**Severity:** 🟠 HIGH  
**Title:** 9 of 10 sign-out call sites bypass `GoogleSignIn.signOut()`  
**State Machine:** SM-01 (Authentication Flow) — cross-cutting  
**Location:** [google_auth_service.dart](file:///d:/Easycheck%20ONLINE/lib/features/authentication/google_auth_service.dart)

**Description:**  
The `GoogleAuthService.signOut()` method correctly calls both `GoogleSignIn().signOut()` and `FirebaseAuth.instance.signOut()`. However, 9 of the 10 places in the codebase that sign the user out call `FirebaseAuth.instance.signOut()` directly, bypassing the Google sign-in cleanup.

**Risk:**  
The Google sign-in credential remains cached. On next sign-in, the user is not shown the Google account picker — they are automatically signed in with the cached credential. This prevents switching accounts and creates confusion when multiple staff members share a device.

**Impact:** Account picker bypass. Shared devices cannot switch users without force-clearing app data.

---

## 5. State Transition Matrix

### Queue Session — Expected vs. Actual

| From \ To | `active` | `paused` | `closed` |
|-----------|:--------:|:--------:|:--------:|
| `active` | — | ✅ Expected | ✅ Expected |
| `paused` | ✅ Expected | — | ⚠️ Allowed but skips resume |
| `closed` | ❌ Should be blocked (allowed via F-05, F-06) | ❌ Should be blocked (allowed via F-06) | — |

### Admin Access — Expected vs. Actual

| From \ To | `none` | `pending` | `approved` | `rejected` | `inactive` | `inconsistent` |
|-----------|:------:|:---------:|:----------:|:----------:|:----------:|:--------------:|
| `none` | — | ✅ Submit request | — | — | — | — |
| `pending` | — | — | ✅ Admin approves | ✅ Admin rejects | — | — |
| `approved` | — | — | — | — | ✅ Clinic deactivated | ⚠️ Member removed (F-02) |
| `rejected` | ✅ New request | ✅ Re-submit | — | — | — | — |
| `inactive` | — | — | ✅ Clinic reactivated | — | — | — |
| `inconsistent` | ❌ No exit | ❌ No exit | ❌ No exit | ❌ No exit | ❌ No exit | — |

---

## 6. Cross-Machine Interactions

These findings arise from the interaction between two or more state machines:

| Interaction | State Machines | Finding | Risk |
|-------------|---------------|---------|------|
| Removed member re-applies | SM-02 × SM-07 | F-02 | Permanent lockout |
| Counter tap during photo upload | SM-04 × SM-08 | F-07 | Silent tap drop |
| Counter increment on paused session | SM-03 × SM-04 | F-03 | Integrity violation |
| Logout on one tab, counter on another | SM-01 × SM-04 | F-13 | Ghost writes |
| Account delete partial failure | SM-10 × SM-01 | F-12 | Orphaned account |
| Notification baseline race | SM-09 × SM-05 | F-11 | Silent notification failure |

---

## 7. Production Readiness Score

### Scoring Methodology

| Severity | Deduction per Finding | Count | Total Deduction |
|----------|:--------------------:|:-----:|:---------------:|
| CRITICAL | −10 | 4 | −40 |
| HIGH | −3 | 5 | −15 |
| MEDIUM | −2 | 3 | −6 |
| LOW | −1 | 2 | −2 |

**Calculated:** 100 − 40 − 15 − 6 − 2 = **37**

### Adjustments

| Factor | Adjustment | Rationale |
|--------|:----------:|-----------|
| Transactional counter operations | +5 | `incrementParcha`, `decrementParcha`, `resetParcha` correctly use Firestore transactions |
| Explicit `AdminAccessState` enum | +3 | One state machine is properly formalized |
| `validStatuses` list on `QueueSessionModel` | +2 | Status values are constrained, even if transitions are not |
| Firestore security rules exist | +3 | 280-line ruleset provides server-side guardrails |
| Audit history on queue operations | +2 | Every counter change is logged immutably |

**Adjusted:** 37 + 15 = **52**

---

### Final Score

```
╔═══════════════════════════════════════════╗
║   PRODUCTION READINESS SCORE:  52 / 100   ║
║                                           ║
║   CRITICAL:  4  │  HIGH:    5             ║
║   MEDIUM:    3  │  LOW:     2             ║
║   TOTAL FINDINGS: 14                      ║
║                                           ║
║   Rating: ⚠️  NOT PRODUCTION-READY        ║
║   The 4 CRITICAL findings must be         ║
║   resolved before production deployment.  ║
╚═══════════════════════════════════════════╝
```

---

## 8. Recommendations Summary

### Priority 1 — CRITICAL (Must Fix Before Production)

| Finding | Recommendation |
|---------|---------------|
| F-02 | Add a `revoked` status to `AdminAccessRequestStatus`. When a member is removed, update their access request to `revoked`. Add a transition from `inconsistent → none` that deletes the stale request. |
| F-04 | Wrap `getOrCreateTodaySession()` in a Firestore transaction, matching the pattern used by `incrementParcha()`. Use `transaction.get()` + conditional `transaction.set()`. |
| F-12 | Reverse the deletion order: delete Auth first (recoverable via re-sign-in), then delete profile. Alternatively, implement a two-phase soft-delete: mark profile as `pendingDeletion`, then delete Auth, then hard-delete profile. |
| F-13 | Subscribe to `FirebaseAuth.instance.authStateChanges()` in the app's root widget. On `null` user event, navigate to login and clear all local state. |

### Priority 2 — HIGH (Fix Before Scale)

| Finding | Recommendation |
|---------|---------------|
| F-03 | Add `if (session.status != 'active') throw` guard to `decrementParcha()`. |
| F-05 | Add a status check in `resetParcha()` — if status is `closed`, either throw or require an explicit `reopen` parameter. |
| F-07 | Replace `_busy` + `_counterSyncing` with a single `enum DashboardOperation { idle, syncing, uploading, updatingStatus }` or use separate, non-overlapping guards for each operation category. |
| F-11 | Re-check `_clinicBaselineEstablished` on every count emission, not just the first. Or use a `Completer` to await clinic baseline before processing count baseline. |
| F-14 | Route all sign-out calls through `GoogleAuthService.signOut()`. Remove direct `FirebaseAuth.instance.signOut()` calls. |

### Priority 3 — MEDIUM/LOW (Harden)

| Finding | Recommendation |
|---------|---------------|
| F-01 | Replace 3 booleans with `enum LoginState { idle, signingIn, error, signedIn }`. |
| F-06 | Add transition validation to `updateSessionStatus()` — e.g., `closed → active` requires going through `resetParcha()`. |
| F-08 | Add an invariant check: when setting `isActive = false`, also set `isOnline = false`. |
| F-09 | Add `validDoctorStatuses` list and validate in `updateClinic()`. |
| F-10 | Add a timeout (e.g., 30 seconds) to the upload HTTP call. Set `_isUploading* = false` on timeout. |

---

> **AUDIT COMPLETE — AWAITING EXPLICIT USER APPROVAL BEFORE ANY MODIFICATIONS.**
