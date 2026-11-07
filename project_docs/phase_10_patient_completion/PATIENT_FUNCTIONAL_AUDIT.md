# Patient Functional Audit: EasyCheck Online

**Phase:** Phase 10 — Patient UI Completion & Verification  
**Date:** October 31, 2026

---

## 1. Local Interactions (Fully Working Locally)

| Screen | Interaction | Behavior | Verification Method |
| :--- | :--- | :--- | :--- |
| **Patient Login** | Google Sign-In Button Tap | Triggers 180ms opacity reduction feedback (`0.85` opacity), then navigates to `/patient/home` | Automated widget test & UI execution |
| **Patient Login** | Legal Links Tap | Displays alert dialogs with full text for "Privacy Policy" and "Terms of Service" | Manual / UI modal trigger |
| **Patient Home** | Search Bar Typing | Instant client-side case-insensitive substring search filtering `.clinic-item` elements by clinic name, physician name, or specialty | Automated widget test |
| **Patient Home** | Clinic Card Selection | Navigates to `/patient/clinic-details` passing selected `ClinicModel` context | Navigator transition verified |
| **Patient Home** | Bottom Tab Navigation | Updates active tab state and visual selection indicators for `Home`, `My Clinics`, and `Settings` | State verification |
| **Clinic Details**| Back Button Tap | Calls `Navigator.of(context).pop()` returning seamlessly to Home feed while preserving scroll state | Pop navigation verified |
| **Clinic Details**| Sync Simulation Toggle | Toggles today's counter between `42` (live count) and `—` (syncing/disconnected state) with rotating sync icon animation | Toggle interaction verified |

---

## 2. Backend Dependencies (Deferred to Firebase Milestone)

| Screen | Feature | Local Mock / Prototype Behavior | Required Firebase Backend Service |
| :--- | :--- | :--- | :--- |
| **Patient Login** | Google Authentication | Local navigation to `/patient/home` | `FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider)` |
| **Patient Home** | Live Clinic Queue Feed | Static list of 3 prototype clinics (`_allClinics`) | `FirebaseFirestore.instance.collection('clinics').snapshots()` |
| **Clinic Details**| Real-Time Parchi Count | Initial value `42` with interactive local toggle | `FirebaseFirestore.instance.collection('clinics').doc(clinicId).snapshots()` |
| **Clinic Details**| Doctor Availability State | Static enum (`DoctorStatus.available`) | Live stream from Admin shift console |

---

## 3. Strict Compliance Note

In strict adherence to the project guidelines, **no fake API calls, fake backend success messages, or simulated Firebase connections** have been injected into production flows. All Firebase hooks are documented and cleanly prepared for the subsequent backend integration phase.
