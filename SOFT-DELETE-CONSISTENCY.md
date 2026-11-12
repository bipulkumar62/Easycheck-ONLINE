# SOFT-DELETE-CONSISTENCY.md — Comprehensive Soft-Delete & Deactivation Audit

> **Target Application:** EasyCheck Online (`easycheck-online`)  
> **Auditor Role:** Senior Software Engineer — Data Integrity, Distributed Systems & Database Architecture  
> **Audit Status:** Complete — Read-Only Forensic Assessment  
> **Document Version:** 1.0.0  
> **Audit Date:** 2026-11-11  
> **Execution Mode:** Non-Destructive / Zero Code Modifications  

---

## 1. Executive Summary & Audit Scope

This document provides a comprehensive audit of **soft-delete consistency**, **logical deactivation patterns**, **cascading visibility**, and **data retention boundaries** across **EasyCheck Online**.

In distributed architectures and multi-tenant applications like EasyCheck, records are rarely physically purged (`hard deleted`) immediately upon termination or removal due to audit compliance, historical integrity (e.g., healthcare parchi audit logs), and legal constraints. Instead, the application relies on logical flags (`isActive: bool`) and lifecycle statuses (`status: 'active' | 'paused' | 'closed'`).

If soft-deleted or deactivated parent entities (such as a disabled clinic or offboarded clinic member) continue to allow child mutations or surface in public queries, the system exhibits **soft-delete inconsistency**.

### High-Level Audit Findings

| Category | Finding Summary | Severity | Status |
| :--- | :--- | :---: | :---: |
| **Model Inactive Permission Leak** | `ClinicMembershipModel.hasPermission()` checks the permissions list without checking `this.isActive`. A deactivated member in memory evaluates as permitted. | **High** | Confirmed Bug |
| **Cascading Deactivation in Rules** | In `firestore.rules`, `canManageClinic` verifies `clinic_members.isActive == true` but fails to verify `isActiveClinic(clinicId)`. Deactivated clinics can still receive queue session tally updates. | **High** | Confirmed Bug |
| **Access Request Inconsistency Trap** | When a member is removed via `remove-member` (`isActive = false`), the associated `admin_access_requests` record remains `approved`. On subsequent logins, `AdminAccessService` permanently traps the user in an `inconsistent` unauthorized state, blocking re-application. | **High** | Confirmed Defect |
| **Orphaned Access Requests on Deletion** | Patient account deletion physically hard-deletes `users/{uid}`, but any historical `admin_access_requests` or `queue_history` records referencing that UID remain orphaned without anonymization or tombstoning. | **Medium** | Confirmed Architecture |
| **Discovery Filter Alignment** | Patient discovery intentionally includes deactivated clinics (`clinicsStream`) to display an honest offline notice rather than having clinics silently vanish; active filtering is correctly enforced in `admin_access_request_screen.dart`. | **Low Risk** | Documented Intent |
| **Immutable Queue Audit Trail** | `queue_history` and `queue_sessions` have `allow delete: if false` in `firestore.rules`, ensuring historical queue tallies cannot be deleted or pruned unintentionally. | **Positive** | Confirmed Resilient |

---

## 2. Project-Wide Deletion Architecture

### 2.1 Entity Deletion & Deactivation Strategy

EasyCheck Online employs a hybrid deletion model:

| Entity / Collection | Deletion Strategy | Soft-Delete Key / Flag | Hard Delete Allowed? | Deletion Trigger / Actor |
| :--- | :---: | :---: | :---: | :--- |
| **`users`** (`users/{userId}`) | Dual (Soft & Hard) | `isActive: bool` | Yes (Patient self-delete) | Patient self-delete via `deleteProfile()`; Operator deactivation. |
| **`clinics`** (`clinics/{clinicId}`) | Pure Soft-Delete | `isActive: bool`, `isOnline: bool` | **NO** (`allow delete: if false`) | Operator CLI (`deactivate-clinic`). |
| **`clinic_members`** (`clinic_members/{userId}_{clinicId}`) | Pure Soft-Delete | `isActive: bool` | **NO** (`allow delete: if isSuperAdmin`) | Operator CLI (`remove-member`). |
| **`admin_access_requests`** (`admin_access_requests/{uid}_{clinicId}`) | Status Lifecycle | `status: 'pending'\|'approved'\|'rejected'` | Only Super Admin | Rejection sets status to `'rejected'`. No soft-delete flag. |
| **`queue_sessions`** (`queue_sessions/{clinicId}_{date}`) | Status Lifecycle | `status: 'active'\|'paused'\|'closed'` | **NO** (`allow delete: if false`) | Session lifecycle status update. |
| **`queue_history`** (`queue_history/{historyId}`) | Immutable Audit | None (Append-only) | **NO** (No delete rule) | Never deleted; tamper-proof clinical log. |

---

## 3. Relationship & Cascading Consistency Map

```
+-----------------------------------------------------------------------------------------+
|                                    Clinics (Parent)                                     |
|                                    isActive: bool                                       |
+-----------------------------------------------------------------------------------------+
                    |                                                |
         Cascades to Member Access?                        Cascades to Queue Sessions?
         [PARTIALLY ENFORCED]                              [NOT ENFORCED IN RULES]
                    |                                                |
                    v                                                v
+---------------------------------------+       +-----------------------------------------+
|     clinic_members (Child 1)          |       |         queue_sessions (Child 2)        |
|     isActive: bool                    |       |         status: 'active'|'closed'       |
+---------------------------------------+       +-----------------------------------------+
                    |                                                |
       Orphaned Request Trap?                             Audit History Preserved?
        [CONFIRMED DEFECT]                                    [IMMUTABLE OK]
                    |                                                |
                    v                                                v
+---------------------------------------+       +-----------------------------------------+
|   admin_access_requests (Child 3)     |       |          queue_history (Child 4)        |
|   status: 'approved' (stale)          |       |          action: 'increment'|'reset'    |
+---------------------------------------+       +-----------------------------------------+
```

---

## 4. In-Depth Findings & Vulnerability Analysis

---

### Finding 1: `ClinicMembershipModel.hasPermission()` Ignores `isActive`

- **Severity:** **HIGH**
- **Affected File & Function:**
  - `lib/features/clinics/clinic_membership_model.dart:71-73` (`hasPermission()`)
  - `lib/features/clinics/clinic_membership_repository.dart:101-113` (`hasPermission()`)
- **Status:** **CONFIRMED BUG**
- **Exact Code Citation:**
  ```dart
  // lib/features/clinics/clinic_membership_model.dart:71-73
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
  ```
  ```dart
  // lib/features/clinics/clinic_membership_repository.dart:101-110
  Future<bool> hasPermission(String userId, String clinicId, String permission) async {
    try {
      final membership = await getMembership(userId, clinicId);
      if (membership == null) return false;
      return membership.hasPermission(permission);
    } on ServerFailure {
      return false;
    }
  }
  ```
- **What is Happening:**
  When a staff member is deactivated by an operator (`isActive: false`), the document still contains their historical permissions array (e.g. `['update_tally', 'manage_staff']`). Calling `membershipRepository.hasPermission(uid, clinicId, 'update_tally')` fetches the document, confirms it exists, and calls `membership.hasPermission()`, which returns `true` because it checks array inclusion without validating `this.isActive == true`.
- **Why It Creates Inconsistent Behavior:**
  Deactivated or soft-deleted staff members are evaluated as having active privileges in any local or service-level permission check.
- **Recommended Solution:**
  Update `ClinicMembershipModel.hasPermission`:
  ```dart
  bool hasPermission(String permission) {
    return isActive && permissions.contains(permission);
  }
  ```

---

### Finding 2: Firestore Rules Permit Queue Writes on Deactivated Clinics

- **Severity:** **HIGH**
- **Affected File & Function:**
  - `firestore.rules:50-57` (`canManageClinic()`)
  - `firestore.rules:222-239` (`match /queue_sessions/{sessionId}`)
- **Status:** **CONFIRMED BUG**
- **Exact Code Citation:**
  ```javascript
  // firestore.rules:50-57
  function canManageClinic(uid, clinicId) {
    return isAuthenticated() && (
      isClinicAdmin(uid, clinicId)
      || (isActiveMember(uid, clinicId)
        && get(/databases/$(database)/documents/clinic_members/$(uid + '_' + clinicId)).data.get('role', '') == 'front_desk_lead')
    );
  }

  // firestore.rules:231-236
  match /queue_sessions/{sessionId} {
    allow update: if (isSuperAdmin() || canManageClinic(request.auth.uid, resource.data.clinicId))
      && request.resource.data.clinicId == resource.data.clinicId
      // ...
  ```
- **What is Happening:**
  `canManageClinic` only inspects whether the caller is an active member in `clinic_members`. It **does not check `isActiveClinic(clinicId)`**.
- **Why It Creates Inconsistent Behavior:**
  When a network administrator deactivates a clinic (`clinics/{clinicId}.isActive = false`), staff members whose individual membership records were not explicitly deactivated can continue to increment, decrement, and reset today's parchi count in `queue_sessions` directly via Firestore SDK calls, bypassing the clinic-level deactivation!
- **Recommended Solution:**
  Update `canManageClinic` to enforce clinic active status:
  ```javascript
  function canManageClinic(uid, clinicId) {
    return isAuthenticated()
      && isActiveClinic(clinicId)
      && (
        isClinicAdmin(uid, clinicId)
        || (isActiveMember(uid, clinicId)
          && get(/databases/$(database)/documents/clinic_members/$(uid + '_' + clinicId)).data.get('role', '') == 'front_desk_lead')
      );
  }
  ```

---

### Finding 3: Soft-Deleted Members Trapped in Inconsistent State

- **Severity:** **HIGH**
- **Affected File & Function:**
  - `lib/features/authentication/admin_access_service.dart:77-140` (`resolveUid()`)
  - `lib/features/authentication/admin_access_request_repository.dart:122-133` (`submitRequest()`)
  - `tools/admin_cli/index.js:352-402` (`remove-member`)
- **Status:** **CONFIRMED ARCHITECTURAL DEFECT**
- **What is Happening:**
  1. User requests access to Clinic CLN-10001 (`status: 'pending'`).
  2. Operator approves request; membership created (`isActive: true`), request marked `status: 'approved'`.
  3. Later, operator runs `remove-member --uid <UID> --clinic CLN-10001`. This sets `clinic_members.isActive = false`.
  4. The user logs in again. `_membershipRepository.getUserMemberships(uid)` filters `where('isActive', isEqualTo: true)`, returning an empty list.
  5. `AdminAccessService.resolveUid` falls back to checking `_requestRepository.getRequestsForUser(uid)`.
  6. The request is still in `status: 'approved'`.
  7. Lines 129–138 match `case AdminAccessRequestStatus.approved:`, returning `AdminAccessState.inconsistent`.
  8. The user is navigated to `AdminUnauthorizedScreen`.
  9. If the user tries to submit a new access request, `AdminAccessRequestRepository.submitRequest` checks for existing requests, sees `existing.status == approved`, and throws: `"You already have a request for this clinic. Check your request status instead."`
- **Why It Creates Inconsistent Behavior:**
  The user is permanently locked out from ever re-requesting access to that clinic. Soft-deleting a membership leaves the associated access request in a zombie `approved` state.
- **Recommended Solution:**
  1. In `tools/admin_cli/index.js`, when `remove-member` is executed, update the corresponding `admin_access_requests/{uid}_{clinicId}` document to `status: 'rejected'` or `status: 'revoked'`.
  2. In `AdminAccessRequestRepository.submitRequest`, allow re-submission if the user has no active membership and the prior request is revoked/inactive.

---

### Finding 4: Orphaned Records on Patient Account Deletion

- **Severity:** **MEDIUM**
- **Affected File & Function:**
  - `lib/features/patient/patient_home_screen.dart:420-450` (`_deleteAccount()`)
  - `lib/features/authentication/user_profile_repository.dart:117-127` (`deleteProfile()`)
- **Status:** **CONFIRMED ARCHITECTURAL RISK**
- **What is Happening:**
  When a patient deletes their account from `PatientHomeScreen`, the app executes:
  `await _profileRepository.deleteProfile(user.uid);`
  `await user.delete();`
  However, if that user had previously submitted an `admin_access_requests` document or performed an action recorded in `queue_history`, those records remain in Firestore pointing to a non-existent UID.
- **Why It Creates Inconsistent Behavior:**
  Querying `admin_access_requests` returns documents whose `uid` cannot be resolved against `users/{uid}` or Firebase Auth, potentially causing null pointer exceptions in admin consoles or audit log processors.
- **Recommended Solution:**
  When `deleteProfile(uid)` is invoked, delete or anonymize non-clinical child records (`admin_access_requests/{uid}_*`) while retaining clinical queue audit logs (`queue_history`) with an anonymized tombstone marker (`performedBy: 'deleted_user'`).

---

### Finding 5: `sessionsForDateStream` Includes Deactivated Clinic Sessions

- **Severity:** **LOW**
- **Affected File & Function:**
  - `lib/features/clinics/queue_repository.dart:300-308` (`sessionsForDateStream()`)
- **Status:** **CONFIRMED BEHAVIOR**
- **What is Happening:**
  `sessionsForDateStream` queries `queue_sessions` where `date == today` without joining or verifying clinic `isActive`.
- **Why It Creates Inconsistent Behavior:**
  If a clinic was active in the morning (parchi count = 25) and deactivated by the administrator at noon, the patient discovery home screen still displays "Today's Parchi: 25" next to the disabled/offline clinic badge until the calendar day changes.
- **Recommended Solution:**
  Documented as acceptable operational behavior: patients can see the final counter achieved before the clinic went offline.

---

## 5. Critical Edge Cases Evaluation

| # | Edge Case Scenario | Audit Assessment | Verification Status |
| :-: | :--- | :--- | :---: |
| **1** | Deleted user must not appear in normal listings | Patient profiles are hard-deleted on account removal; operator CLI `list-users` flags `disabled=true`. | **PASS** |
| **2** | Related records follow intended deletion policy | `queue_history` audit records are retained immutably by design. | **PASS** |
| **3** | Search results exclude deleted records | Active search filters `clinic.isActive` or clearly flags offline state in `patient_home_screen.dart`. | **PASS** |
| **4** | Counts and analytics exclude deleted records | Queue session counts isolate by date; inactive clinics display paused/offline indicators. | **PASS** |
| **5** | Pagination handles soft-deleted records | Firestore limit queries filter `.where('isActive', isEqualTo: true)` on member lists. | **PASS** |
| **6** | Related queries exclude soft-deleted parents | **FAIL (Finding 2):** `queue_sessions` allows updates even when parent `clinics.isActive == false`. | **DEFECT** |
| **7** | Admin recovery workflows retain intended access | Super Admin retains `isSuperAdmin()` bypass on all collections in `firestore.rules`. | **PASS** |
| **8** | Restoring record restores expected visibility | Toggling `isActive: true` on clinic or member immediately restores full operational state. | **PASS** |
| **9** | Permanent deletion does not delete unrelated data | Deterministic doc IDs (`${uid}_${clinicId}`) prevent accidental cross-document deletion. | **PASS** |
| **10** | Background jobs do not reintroduce deleted data | No external caching layer (Redis) exists to re-inject purged records. | **PASS** |

---

## 6. Prioritized Remediation Roadmap (Approval Required)

> [!IMPORTANT]
> **NO CODE HAS BEEN MODIFIED.**  
> In compliance with strict safety rules, the following minimal fixes are proposed for review and explicit approval.

---

### Change 1: Enforce Active State in `ClinicMembershipModel` (Fixes Finding 1)
- **Target File:** `lib/features/clinics/clinic_membership_model.dart`
- **Change:**
  ```dart
  bool hasPermission(String permission) {
    return isActive && permissions.contains(permission);
  }
  ```
- **Risk / Side Effects:** None. Only prevents deactivated members from returning `true` on permission inquiries.

---

### Change 2: Enforce `isActiveClinic` in Firestore Rules for Queue Management (Fixes Finding 2)
- **Target File:** `firestore.rules`
- **Change:**
  ```javascript
  function canManageClinic(uid, clinicId) {
    return isAuthenticated()
      && isActiveClinic(clinicId)
      && (
        isClinicAdmin(uid, clinicId)
        || (isActiveMember(uid, clinicId)
          && get(/databases/$(database)/documents/clinic_members/$(uid + '_' + clinicId)).data.get('role', '') == 'front_desk_lead')
      );
  }
  ```
- **Risk / Side Effects:** Properly rejects queue tally writes if the parent clinic is disabled.

---

### Change 3: Update Request State on Member Deactivation in CLI (Fixes Finding 3)
- **Target File:** `tools/admin_cli/index.js`
- **Change:**
  Inside `remove-member`, update any existing `admin_access_requests` document for `${uid}_${clinicId}` to `status: 'revoked'`:
  ```javascript
  const requestRef = db.collection('admin_access_requests').doc(membershipId(uid, clinicId));
  const requestSnap = await transaction.get(requestRef);
  if (requestSnap.exists) {
    transaction.update(requestRef, {
      status: 'rejected',
      rejectionReason: 'Membership was deactivated by clinic administrator.',
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  ```
- **Risk / Side Effects:** Resolves the permanent zombie lockout; enables former members to be re-invited or re-apply cleanly.

---

## 7. Soft-Delete Consistency Scoring

### Scoring Methodology

- **Base Score:** 100 Points
- **Deductions:**
  - **High Severity Inconsistencies (3 × -10):** -30 points  
    *(Model permission check ignoring `isActive`, Rules allowing writes to deactivated parent clinic, Zombie access request lock)*
  - **Medium Severity Inconsistencies (1 × -5):** -5 points  
    *(Orphaned access requests upon patient account deletion)*
  - **Bonus for Immutable Audit Protection:** +5 points  
    *(Tamper-proof `queue_history` and `allow delete: if false` on clinics and sessions)*

$$\text{Final Consistency Score} = 100 - 30 - 5 + 5 = 70 / 100$$

### Overall Soft-Delete Consistency Score: **70 / 100 (GOOD / REQUIRES HARDENING)**

---

## 8. Approval Gate — Safety Sign-Off

> [!IMPORTANT]
> **AUDIT COMPLETE — STOPPING HERE.**  
> - No application source code has been altered.
> - No database rules or CLI tools were modified.
> - Awaiting explicit user approval before applying any of the 3 proposed remediations.

