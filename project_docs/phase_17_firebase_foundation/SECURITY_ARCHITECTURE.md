# Security Architecture

**Phase:** Task 17 — Firebase Project Setup & Backend Architecture  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Security Philosophy

**Core Principle:** Flutter UI checks are NOT security controls. All authorization is enforced by Firestore Security Rules and Firebase Authentication. The client is treated as untrusted.

> "Never allow a client to grant itself admin or super-admin privileges."

---

## 2. Security Layers

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: Client Application (Flutter)                           │
│  - UI validation only (prevents negative counts, etc.)          │
│  - NO authorization decisions                                   │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 2: Firebase Authentication                                │
│  - Identity verification                                        │
│  - ID token issuance                                            │
│  - Anonymous auth for patients                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 3: Firestore Security Rules                               │
│  - Read/write authorization                                     │
│  - Field-level validation                                       │
│  - Cross-clinic isolation                                       │
│  - Role-based access control (RBAC)                             │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 4: Firebase App Check                                     │
│  - Runtime integrity verification                               │
│  - Play Integrity (Android)                                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Authentication Strategy

| Method | Use Case | Security Properties |
|--------|----------|---------------------|
| Google Sign-In | Clinic staff, registered patients | OAuth 2.0, ID token verification |
| Anonymous | Unregistered patients | Limited to read-only clinic browsing |
| Email/Password | Not enabled | Reduces attack surface |
| Phone Auth | Not enabled | Not in scope |

**Key Security Properties:**
- ID tokens are cryptographically signed by Google
- Firebase Auth verifies tokens on every Firestore request
- Anonymous users have limited privileges (read-only)
- No password-based authentication eliminates credential stuffing risk

---

## 4. Authorization Model

### 4.1 Role-Based Access Control (RBAC)

Roles are stored in `users.role` and clinic membership in `clinic_members`. Security Rules enforce access:

```
Role Hierarchy:
  patient        → Read clinics, read queue sessions (own clinic not applicable)
  front_desk_lead → Read own clinic, update parchi count, update doctor status
  triage_coordinator → Read own clinic, update patient queue status
  clinic_admin → Read own clinic, all operations including daily reset
  super_admin → FUTURE PHASE — NOT IMPLEMENTED
```

### 4.2 Clinic Membership Verification

Every clinic operation requires verification that the user is a member of the target clinic:

```
Security Rule Pattern:
  allow read, write: if request.auth != null
    && exists(/databases/$(database)/documents/clinic_members/$(request.auth.uid)_$(resource.data.clinicId))
    && get(/databases/$(database)/documents/clinic_members/$(request.auth.uid)_$(resource.data.clinicId)).data.isActive == true
```

### 4.3 Cross-Clinic Isolation

**Critical Security Rule:** A user can never access data from a clinic they are not a member of.

```
allow read: if request.auth != null
  && resource.data.clinicId in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.authorizedClinicIds
```

---

## 5. Firestore Security Rules Strategy

### 5.1 Rule Structure

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions (defined at top)
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isClinicMember(clinicId) {
      return exists(/databases/$(database)/documents/clinic_members/$(request.auth.uid)_$(clinicId))
        && get(/databases/$(database)/documents/clinic_members/$(request.auth.uid)_$(clinicId)).data.isActive == true;
    }
    
    function hasPermission(clinicId, permission) {
      return isClinicMember(clinicId)
        && permission in get(/databases/$(database)/documents/clinic_members/$(request.auth.uid)_$(clinicId)).data.permissions;
    }
    
    function isPatient() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'patient';
    }
    
    // Collection rules...
  }
}
```

### 5.2 Collection-Specific Rules

| Collection | Read | Write | Create | Delete |
|------------|------|-------|--------|--------|
| `users` | Authenticated (own doc only) | Authenticated (own doc only) | Authenticated | Never |
| `clinics` | Authenticated + isActive | Admin only (own clinic) | Never | Never |
| `clinic_members` | Authenticated (own memberships) | Admin only | Never | Never |
| `queue_sessions` | Authenticated (clinic members) | Clinic members with permissions | Never | Never |
| `queue_history` | Authenticated (clinic members) | System only (daily reset) | Never | Never |

### 5.3 Field Validation

| Field | Validation Rule |
|-------|----------------|
| `currentParchiCount` | `>= 0` (integer) |
| `totalIssuedToday` | `>= 0` and `<= currentParchiNumber` |
| `doctorStatus` | `in ["available", "delayed", "offDuty"]` |
| `clinicId` | Must match user's clinic_membership |
| `date` | Must match YYYY-MM-DD format |

---

## 6. Firebase App Check Strategy

| Component | Implementation |
|-----------|---------------|
| Provider | Play Integrity (Android) |
| Enforcement | Not enforced in MVP (enable in production) |
| Purpose | Prevent abuse from tampered clients |
| Configuration | Enable in Firebase Console > App Check |

---

## 7. Input Validation

| Input | Validation Location | Rule |
|-------|-------------------|------|
| Parchi count increment | Security Rules | `request.resource.data.currentParchiNumber == resource.data.currentParchiNumber + 1` |
| Parchi count decrement | Security Rules | `request.resource.data.currentParchiNumber == resource.data.currentParchiNumber - 1` AND `>= 0` |
| Doctor status | Security Rules | `in ["available", "delayed", "offDuty"]` |
| Daily reset | Security Rules | User has `reset_tally` permission; creates `queue_history` doc |

---

## 8. Rate Limiting and Abuse Prevention

| Measure | Implementation |
|---------|---------------|
| App Check | Play Integrity token required (production) |
| Firestore quotas | 50,000 reads/day, 20,000 writes/day (Spark plan) |
| Anonymous auth limits | Firebase Auth default rate limits |
| Write frequency | Client-side debouncing (no rapid-fire increments) |

---

## 9. Audit Logging for Sensitive Operations

| Operation | Audit Trail | Storage Location |
|-----------|-------------|-----------------|
| Daily parchi reset | `queue_history` document with `resetPerformedAt`, `resetPerformedBy` | Firestore |
| Doctor status change | `doctorStatusChanges` array in `queue_sessions` | Firestore |
| Parchi counter increment | Implicit in `queue_sessions.lastUpdatedAt` and `updatedBy` | Firestore |
| Admin role assignment | Future phase | `clinic_members` document |

---

## 10. What Is NOT a Security Control

| Item | Why Not a Security Control |
|------|---------------------------|
| Flutter UI button enable/disable | Can be bypassed by modifying client code |
| Route guards in Flutter | Can be bypassed by direct URL navigation |
| Client-side role checks | Can be spoofed |
| Local data caching | Can be modified |
| Obscured API keys | Can be extracted from APK |

---

## 11. Security Rules Deployment Plan

| Phase | Action |
|-------|--------|
| Phase 17 (Current) | Document rules strategy |
| Phase 18 | Implement `firestore.rules` with RBAC |
| Phase 19 | Enable App Check enforcement |
| Production | Replace permissive rules (current rules expire Nov 29, 2026) |

---

## 12. Current Rules Gap

The existing `firestore.rules` uses a permissive rule:

```
allow read, write: if request.time < timestamp.date(2026, 11, 29);
```

**This expires on November 29, 2026.** After that date, all Firestore requests will be denied until proper rules are deployed. This must be addressed before production use.
