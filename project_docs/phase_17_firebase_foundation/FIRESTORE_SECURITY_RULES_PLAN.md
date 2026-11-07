# Firestore Security Rules Plan

**Phase:** Task 17 — Firebase Project Setup & Backend Architecture  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Current Rules Status

| File | Status | Content |
|------|--------|---------|
| `firestore.rules` | ✅ Present | Permissive rules — expires Nov 29, 2026 |
| `firestore.indexes.json` | ✅ Present | 2 clinic indexes configured |

**Current `firestore.rules`:**
```
rules_version='2'
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2026, 11, 29);
    }
  }
}
```

**Gap:** These rules allow unauthenticated read/write access to all documents until November 29, 2026. They must be replaced with proper RBAC rules before production.

---

## 2. Security Rules Design

### 2.1 Helper Functions

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ============ HELPER FUNCTIONS ============
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserRole(uid) {
      return get(/databases/$(database)/documents/users/$(uid)).data.role;
    }
    
    function isClinicMember(uid, clinicId) {
      return exists(/databases/$(database)/documents/clinic_members/$(uid)_$(clinicId))
        && get(/databases/$(database)/documents/clinic_members/$(uid)_$(clinicId)).data.isActive == true;
    }
    
    function hasPermission(uid, clinicId, permission) {
      return isClinicMember(uid, clinicId)
        && permission in get(/databases/$(database)/documents/clinic_members/$(uid)_$(clinicId)).data.permissions;
    }
    
    function isSameClinic(resourceClinicId, userClinicId) {
      return resourceClinicId == userClinicId;
    }
    
    function validParchiCount(value) {
      return value is int && value >= 0;
    }
    
    function validDoctorStatus(status) {
      return status in ['available', 'delayed', 'offDuty'];
    }
    
    // ============ USERS COLLECTION ============
    
    match /users/{userId} {
      allow read: if isAuthenticated()
        && (userId == request.auth.uid || isClinicMember(request.auth.uid, get().data.clinicId));
      
      allow create: if isAuthenticated()
        && userId == request.auth.uid;
      
      allow update: if isAuthenticated()
        && userId == request.auth.uid;
      
      allow delete: if false;
    }
    
    // ============ CLINICS COLLECTION ============
    
    match /clinics/{clinicId} {
      allow read: if isAuthenticated()
        && (isPatient() || isClinicMember(request.auth.uid, clinicId));
      
      allow create: if false; // Clinics created by super-admin (future phase)
      
      allow update: if isAuthenticated()
        && isClinicMember(request.auth.uid, clinicId)
        && hasPermission(request.auth.uid, clinicId, 'manage_clinic');
      
      allow delete: if false;
    }
    
    // ============ CLINIC_MEMBERS COLLECTION ============
    
    match /clinic_members/{memberId} {
      allow read: if isAuthenticated()
        && (memberId.split('_')[0] == request.auth.uid || isClinicMember(request.auth.uid, memberId.split('_')[1]));
      
      allow create: if isAuthenticated()
        && hasPermission(request.auth.uid, memberId.split('_')[1], 'manage_staff');
      
      allow update: if isAuthenticated()
        && hasPermission(request.auth.uid, memberId.split('_')[1], 'manage_staff');
      
      allow delete: if false;
    }
    
    // ============ QUEUE_SESSIONS COLLECTION ============
    
    match /queue_sessions/{sessionId} {
      allow read: if isAuthenticated()
        && (isPatient() || isClinicMember(request.auth.uid, resource.data.clinicId));
      
      allow create: if false; // Sessions created by system
      
      allow update: if isAuthenticated()
        && isClinicMember(request.auth.uid, resource.data.clinicId)
        && (
          (hasPermission(request.auth.uid, resource.data.clinicId, 'update_tally') 
            && request.resource.data.currentParchiNumber == resource.data.currentParchiNumber + 1)
          || (hasPermission(request.auth.uid, resource.data.clinicId, 'update_tally') 
            && request.resource.data.currentParchiNumber == resource.data.currentParchiNumber - 1
            && request.resource.data.currentParchiNumber >= 0)
          || (hasPermission(request.auth.uid, resource.data.clinicId, 'update_status')
            && validDoctorStatus(request.resource.data.doctorStatus))
        );
      
      allow delete: if false;
    }
    
    // ============ QUEUE_HISTORY COLLECTION ============
    
    match /queue_history/{historyId} {
      allow read: if isAuthenticated()
        && (isPatient() || isClinicMember(request.auth.uid, resource.data.clinicId));
      
      allow create: if isAuthenticated()
        && hasPermission(request.auth.uid, resource.data.clinicId, 'reset_tally');
      
      allow update: if false; // History is immutable
      
      allow delete: if false;
    }
  }
}
```

---

## 3. Rule Validation Logic by Operation

### 3.1 Parchi Counter Increment

```
Preconditions:
  - request.auth.uid exists
  - User is member of session's clinicId
  - User has 'update_tally' permission
  - request.resource.data.currentParchiNumber == resource.data.currentParchiNumber + 1
  
Postconditions:
  - currentParchiNumber incremented by 1 atomically
  - lastUpdatedAt updated to request.time
  - updatedBy set to request.auth.uid
```

### 3.2 Parchi Counter Decrement

```
Preconditions:
  - request.auth.uid exists
  - User is member of session's clinicId
  - User has 'update_tally' permission
  - request.resource.data.currentParchiNumber == resource.data.currentParchiNumber - 1
  - request.resource.data.currentParchiNumber >= 0
  
Postconditions:
  - currentParchiNumber decremented by 1
  - lastUpdatedAt updated
  - updatedBy set to request.auth.uid
```

### 3.3 Doctor Status Change

```
Preconditions:
  - request.auth.uid exists
  - User is member of session's clinicId
  - User has 'update_status' permission
  - request.resource.data.doctorStatus in ['available', 'delayed', 'offDuty']
  
Postconditions:
  - doctorStatus updated
  - lastUpdatedAt updated
  - Status change logged in doctorStatusChanges array
```

### 3.4 Daily Reset

```
Preconditions:
  - request.auth.uid exists
  - User is member of session's clinicId
  - User has 'reset_tally' permission
  - New queue_history document created with audit fields
  - queue_sessions.currentParchiNumber set to 0
  
Postconditions:
  - Historical data preserved in queue_history
  - Current count reset to 0
  - lastResetDate updated in clinics document
```

---

## 4. Field-Level Validation

| Field | Collection | Validation Rule |
|-------|-----------|-----------------|
| `currentParchiNumber` | `queue_sessions` | `value is int && value >= 0` |
| `totalIssuedToday` | `queue_sessions` | `value is int && value >= 0` |
| `doctorStatus` | `queue_sessions` | `value in ['available', 'delayed', 'offDuty']` |
| `clinicId` | All collections | Must match user's `clinic_members` entry |
| `date` | `queue_sessions`, `queue_history` | Must match `^\d{4}-\d{2}-\d{2}$` |
| `resetPerformedAt` | `queue_history` | `value is timestamp` |
| `resetPerformedBy` | `queue_history` | `value == request.auth.uid` |

---

## 5. Cross-Clinic Isolation Rules

**Critical:** A user can NEVER access data from a clinic they are not a member of.

```javascript
// Pattern applied to all clinic-scoped collections:
allow read, write: if isAuthenticated()
  && isClinicMember(request.auth.uid, resource.data.clinicId);
```

**Additional protection for `users` collection:**
```javascript
match /users/{userId} {
  allow read: if isAuthenticated()
    && (userId == request.auth.uid); // Users can only read their own profile
}
```

---

## 6. Anonymous User Restrictions

Anonymous users (patients without Google Sign-In) have restricted access:

```javascript
// Anonymous users can only read clinic data
match /clinics/{clinicId} {
  allow read: if isAuthenticated()
    && request.auth.token.firebase.identities['anonymous.com'] != null
    && resource.data.isActive == true;
  
  // Anonymous users cannot write to any clinic-scoped collection
  allow write: if false;
}
```

---

## 7. Indexes Required for Security Rules

The following indexes from `firestore.indexes.json` support security rule queries:

| Index | Purpose |
|-------|---------|
| `clinics`: city ASC, isActive ASC, updatedAt DESC | Patient clinic discovery |
| `clinics`: adminUid ASC, updatedAt DESC | Admin clinic lookup |

**Additional indexes needed for Security Rules:**
| Index | Purpose |
|-------|---------|
| `clinic_members`: userId ASC, isActive ASC | Membership verification |
| `clinic_members`: clinicId ASC, isActive ASC | Staff lookup by clinic |

---

## 8. Rules Deployment Checklist

| Step | Action | Status |
|------|--------|--------|
| 1 | Replace permissive `firestore.rules` with RBAC rules | ⏳ Pending (Phase 18) |
| 2 | Deploy rules via Firebase Console or CLI | ⏳ Pending |
| 3 | Test rules with Firebase Emulator | ⏳ Pending |
| 4 | Enable Firebase App Check enforcement | ⏳ Pending (Production) |
| 5 | Monitor Firestore access logs | ⏳ Pending (Production) |

---

## 9. Emergency Rule Expiration

The current permissive rules expire on **November 29, 2026**. After that date:
- All Firestore read/write requests will be denied
- The app will be unable to read or write any data
- Proper RBAC rules MUST be deployed before this date

---

## 10. Testing Strategy

| Test | Method | Tool |
|------|--------|------|
| Authenticated user can read own clinic data | Unit test | Firebase Emulator |
| Unauthenticated user cannot read any data | Unit test | Firebase Emulator |
| User cannot access another clinic's data | Unit test | Firebase Emulator |
| Anonymous user can read active clinics | Unit test | Firebase Emulator |
| Counter increment requires update_tally permission | Unit test | Firebase Emulator |
| Daily reset requires reset_tally permission | Unit test | Firebase Emulator |
