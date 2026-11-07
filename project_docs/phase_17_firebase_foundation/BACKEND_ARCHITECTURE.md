# Backend Architecture

**Phase:** Task 17 — Firebase Project Setup & Backend Architecture  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Architecture Overview

EasyCheck Online uses a **serverless, client-centric architecture** with Firebase as the backend platform. No custom backend server (Node.js, Render, etc.) is required — all data operations go through Firestore with Security Rules providing authorization.

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER (Flutter)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐  │
│  │  Patient UI │  │   Admin UI  │  │   Shared Components   │  │
│  │  (Clinical  │  │ (Clinical   │  │   Auth, Theme, Models │  │
│  │   Clarity)  │  │   Precision)│  │                         │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬───────────┘  │
│         │                │                     │                │
│         └────────────────┴─────────────────────┘                │
│                           │                                       │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AUTHENTICATION LAYER                          │
│  ┌─────────────────┐  ┌─────────────────────────────────────┐  │
│  │ Firebase Auth   │  │   Google Sign-In (OAuth 2.0)        │  │
│  │   (Client SDK)  │  │   Anonymous sign-in (fallback)      │  │
│  └─────────────────┘  └─────────────────────────────────────┘  │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DATA LAYER (Firestore)                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  users   │  │  clinics │  │  clinic_ │  │ queue_     │   │
│  │          │  │          │  │  members │  │ sessions   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│                           │                                       │
│                           ▼                                       │
│                    ┌──────────────┐                              │
│                    │ queue_     │                              │
│                    │ history    │                              │
│                    └────────────┘                              │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                 SECURITY RULES LAYER                            │
│  Read/write access enforced by Firestore Security Rules         │
│  Role-based access control (RBAC) via clinic_members            │
│  No client-side trust — all authorization server-side           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Layer Descriptions

### 2.1 Flutter Application Layer

| Component | Responsibility |
|-----------|---------------|
| `lib/app/` | App bootstrap, routing, theme, localization |
| `lib/features/authentication/` | Patient and admin login screens (UI only — auth logic delegated to Firebase) |
| `lib/features/patient/` | Patient home, clinic details screens |
| `lib/features/admin/` | Admin dashboard, reset studio, unauthorized screens |
| `lib/shared/` | Reusable widgets, models |
| `lib/core/` | Config, constants, errors, utils |

**Responsibilities:**
- UI rendering and user interaction
- Local state management (counter, search, navigation)
- Calling Firebase SDK methods (read/write Firestore, sign in)
- **NOT** responsible for authorization decisions

### 2.2 Authentication Layer

| Component | Responsibility |
|-----------|---------------|
| Firebase Auth SDK | User registration, sign-in, sign-out, token management |
| Google Sign-In | OAuth 2.0 flow for clinic staff and patients |
| Anonymous Auth | Fallback for patients without Google accounts |
| ID Tokens | JWT tokens passed with every Firestore request |

**Flow:**
1. User taps "Continue with Google"
2. Flutter calls `google_sign_in` plugin
3. Google returns ID token
4. Flutter calls `FirebaseAuth.signInWithCredential()` with Google credential
5. Firebase Auth returns user UID and ID token
6. ID token is automatically attached to all Firestore requests

### 2.3 Firestore Data Layer

| Collection | Responsibility |
|------------|---------------|
| `users` | User profiles and roles |
| `clinics` | Clinic profiles and operational data |
| `clinic_members` | Staff-to-clinic assignments (RBAC) |
| `queue_sessions` | Active daily queue sessions |
| `queue_history` | Historical daily snapshots |

**Data Access Pattern:**
- All reads/writes go through Firestore client SDK
- Security Rules evaluate every request
- Real-time listeners used for live counter updates
- Atomic increments (`FieldValue.increment`) used for parchi counter

### 2.4 Security Rules Layer

| Responsibility | Implementation |
|---------------|----------------|
| Authentication check | `request.auth != null` |
| Clinic membership | Check `clinic_members` for user's clinicId |
| Role-based permissions | Check `clinic_members.permissions` array |
| Data validation | Field type and value validation |
| Cross-clinic isolation | `resource.data.clinicId == user's clinicId` |

---

## 3. Role-Based Access Control (RBAC)

| Role | Can View | Can Edit | Can Delete | Clinics Accessible |
|------|----------|----------|------------|-------------------|
| `patient` | Clinic profiles, queue status | None | None | All active clinics (read-only) |
| `front_desk_lead` | Own clinic data | Parchi count, doctor status | None | Assigned clinic only |
| `triage_coordinator` | Own clinic data | Patient queue status | None | Assigned clinic only |
| `clinic_admin` | Own clinic data | All clinic settings | None | Assigned clinic only |

**Super Admin** — Future phase only. Not implemented in this phase.

---

## 4. Data Flow Examples

### 4.1 Patient Views Clinic Availability

```
Patient opens Clinic Details screen
    │
    ▼
Flutter reads `clinics/{clinicId}`
    │
    ▼
Security Rules: allow read if clinic.isActive == true
    │
    ▼
Flutter reads `queue_sessions/{clinicId}_{today}`
    │
    ▼
Security Rules: allow read if clinic.isActive == true
    │
    ▼
UI displays doctor status and parchi count
```

### 4.2 Admin Increments Parchi Count

```
Staff taps "+" button on Admin Dashboard
    │
    ▼
Flutter calls FieldValue.increment(1) on queue_sessions doc
    │
    ▼
Security Rules: 
  - request.auth.uid exists
  - user is member of clinicId
  - user has "update_tally" permission
  - new value >= 0
    │
    ▼
Firestore updates atomically
    │
    ▼
Real-time listener updates UI
```

### 4.3 Admin Resets Daily Count

```
Staff taps "Reset count to 0" → confirmation modal
    │
    ▼
Flutter writes to queue_history (archive today's data)
    │
    ▼
Flutter sets currentParchiCount = 0 in queue_sessions
    │
    ▼
Security Rules: user must have "reset_tally" permission
    │
    ▼
UI shows audit confirmation toast
```

---

## 5. Trusted Backend Operations

**None required for MVP.** All operations can be handled by:
- Firestore Security Rules for authorization
- `FieldValue.increment()` for atomic counter updates
- Client-side state for UI state

**Future considerations (if needed):**
- Cloud Functions for complex audit logging
- Cloud Functions for scheduled daily resets
- Cloud Functions for subscription validation

---

## 6. Monitoring and Error Reporting

| Tool | Purpose | Status |
|------|---------|--------|
| Firebase Crashlytics | Crash reporting | Planned (production) |
| Firebase Performance | Performance monitoring | Not required for MVP |
| Firestore usage monitoring | Quota tracking | Firebase Console |
| Authentication logs | Sign-in audit | Firebase Console |

---

## 7. Cost Considerations

| Service | Free Tier | MVP Usage Estimate | Cost Concern |
|---------|-----------|-------------------|--------------|
| Firebase Auth | 50,000 monthly users | Low (clinic staff only) | None |
| Firestore | 50,000 reads/day, 20,000 writes/day | Low (single clinic) | None |
| Firestore Storage | 1 GB | None (no file uploads) | None |
| Cloud Functions | 125,000 invocations/month | None (not used) | None |
| Crashlytics | Free | Low | None |

**Estimated monthly cost:** $0 (within Spark plan free tier)

---

## 8. What Is NOT Implemented

| Feature | Reason |
|---------|--------|
| Cloud Functions | Not required for MVP |
| Custom backend server | Firestore Security Rules sufficient |
| Firebase Storage | No file upload requirements |
| Subscription payments | Future phase |
| Super-admin functionality | Future phase |
| Push notifications | Not in approved scope |
