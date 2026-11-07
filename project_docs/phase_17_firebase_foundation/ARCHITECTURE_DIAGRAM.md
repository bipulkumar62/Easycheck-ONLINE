# Architecture Diagram

**Phase:** Task 17 — Firebase Project Setup & Backend Architecture  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. High-Level System Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            DEVICE LAYER (Flutter)                            │
│                                                                              │
│  ┌──────────────────────┐      ┌──────────────────────┐                     │
│  │   Patient UI         │      │     Admin UI         │                     │
│  │  (Clinical Clarity)  │      │  (Clinical Precision)│                     │
│  │                      │      │                      │                     │
│  │ • Login screen       │      │ • Login screen       │                     │
│  │ • Clinic discovery   │      │ • Dashboard          │                     │
│  │ • Clinic details     │      │ • Reset studio       │                     │
│  │ • Queue status       │      │ • Unauthorized       │                     │
│  └──────────┬───────────┘      └──────────┬───────────┘                     │
│             │                           │                                   │
│             └───────────────────────────┴───────────────────────────────────┘
│                                      │
│                                      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                      FIREBASE AUTHENTICATION LAYER                           │
│                                                                              │
│  ┌─────────────────┐  ┌──────────────────────────────────────────────────┐  │
│  │ Google Sign-In  │  │   Anonymous Auth (patient fallback)              │  │
│  │   (OAuth 2.0)   │  │                                                  │  │
│  └──────────┬──────┘  └──────────────────────────────────────────────────┘  │
│             │                                                                   │
│             ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │  Firebase Auth: ID tokens, user accounts, session management             │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                      FIRESTORE SECURITY RULES LAYER                          │
│                                                                              │
│  • Read/write authorization based on request.auth                            │
│  - Clinic membership verification via clinic_members                         │
│  - Role-based permissions (patient, front_desk_lead, triage_coordinator)    │
│  - Field-level validation (counter >= 0, valid status values)                │
│  - Cross-clinic isolation enforced                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                      CLOUD FIRESTORE DATA LAYER                              │
│                                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌────────────────────┐      │
│  │  users   │  │  clinics │  │ clinic_    │  │ queue_sessions       │      │
│  │          │  │          │  │ members    │  │                      │      │
│  └──────────┘  └──────────┘  └────────────┘  └────────────────────┘      │
│         │                │                │                │              │
│         │                │                │                ▼              │
│         │                │                │      ┌──────────────┐       │
│         │                │                │      │ queue_     │       │
│         │                │                │      │ history    │       │
│         │                │                │      └────────────┘       │
│         │                │                │                           │
└──────────┴───────────────┴───────────────┴─────────────────────────────┘
```

---

## 2. Component Responsibilities

| Layer | Components | Responsibility |
|-------|-----------|----------------|
| **Device Layer** | Patient UI, Admin UI | Render UI, handle user input, manage local state |
| **Auth Layer** | Firebase Auth, Google Sign-In | Verify identity, issue ID tokens, manage sessions |
| **Security Rules** | Firestore Security Rules | Authorize all data access, validate fields, enforce RBAC |
| **Data Layer** | Cloud Firestore | Store and serve all application data |

---

## 3. Data Flow Diagrams

### 3.1 Patient Views Clinic Queue

```
Patient UI
    │
    ▼
[Read clinics/{clinicId}]
    │
    ├─ Security Rules: isAuthenticated() && resource.data.isActive == true
    │
    ▼
[Read queue_sessions/{clinicId}_{today}]
    │
    ├─ Security Rules: isAuthenticated() && isPatient()
    │
    ▼
Patient UI displays: doctor status, parchi count, wait time
```

### 3.2 Admin Issues Parchi Token

```
Admin UI (taps "+" button)
    │
    ▼
[Write queue_sessions/{clinicId}_{today}]
    │
    ├─ Security Rules:
    │   - isAuthenticated()
    │   - isClinicMember(request.auth.uid, clinicId)
    │   - hasPermission(update_tally)
    │   - currentParchiNumber == resource.data.currentParchiNumber + 1
    │
    ▼
[Firestore: atomic increment]
    │
    ▼
[Real-time listener updates Admin UI]
```

### 3.3 Admin Resets Daily Count

```
Admin UI (taps "Reset count to 0" → confirm)
    │
    ▼
[Write queue_history/{clinicId}_{date}]
    │
    ├─ Security Rules: hasPermission(reset_tally)
    │
    ▼
[Write queue_sessions/{clinicId}_{today}: currentParchiNumber = 0]
    │
    ├─ Security Rules: hasPermission(reset_tally)
    │
    ▼
[Admin UI shows audit confirmation]
```

---

## 4. Authentication Flow

```
User opens app
    │
    ▼
Firebase Auth checks persisted session
    │
    ├─ Session exists → Auto sign-in → Route to appropriate home
    │
    └─ No session → Show login screen
         │
         ├─ Patient taps "Continue with Google"
         │    │
         │    ▼
         │    Google OAuth → ID token
         │    │
         │    ▼
         │    FirebaseAuth.signInWithCredential()
         │    │
         │    ▼
         │    Create users/{uid} (role: patient)
         │    │
         │    ▼
         │    Navigate to /patient/home
         │
         └─ Staff taps "Continue with Google"
              │
              ▼
              Google OAuth → ID token
              │
              ▼
              FirebaseAuth.signInWithCredential()
              │
              ▼
              Check users/{uid}.role == "clinic_admin"
              │
              ├─ Yes + clinic_members exists → /admin/dashboard
              ├─ Yes + no clinic_members → /admin/unauthorized
              └─ No → /admin/unauthorized
```

---

## 5. Security Boundaries

| Boundary | Enforcement Mechanism |
|----------|----------------------|
| Client → Flutter UI | Local validation only (not security) |
| Flutter → Firebase Auth | ID token verification (automatic) |
| Firebase Auth → Firestore | Security Rules (server-side) |
| Firestore → Client | Security Rules (read filtering) |
| Clinic → Clinic | Cross-clinic isolation (Security Rules) |

---

## 6. Deployment Architecture

```
Firebase Project: easycheck-online
├── Location: asia-south1 (Mumbai)
├── Database: (default) Firestore
├── Auth: Google Sign-In + Anonymous
├── Storage: Not used
├── Functions: Not used
└── App Check: Not enforced (MVP)
```

---

## 7. Future Architecture Considerations

| Consideration | Status | Notes |
|--------------|--------|-------|
| Cloud Functions | Evaluated | Not required for MVP |
| Custom backend server | Not required | Firestore Security Rules sufficient |
| Multi-region Firestore | Not required | Single region (asia-south1) |
| Firebase Storage | Not required | No file uploads |
| Super Admin | Future phase | Not implemented |

---

## 8. What Is NOT in the Architecture

| Component | Reason |
|-----------|--------|
| Node.js/Express server | Firestore Security Rules replace backend logic |
| Render/Heroku/Vercel | Not needed — Firebase is the backend |
| Custom API endpoints | Firestore SDK handles data access |
| WebSocket server | Firestore real-time listeners suffice |
| Message queue | Not needed for single-clinic operations |
