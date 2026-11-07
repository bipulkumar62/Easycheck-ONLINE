# Known Issues & Observations: Admin Screen 01

**Phase:** Phase 11 — Admin UI Implementation  
**Date:** October 31, 2026

---

## 1. Resolved Observations During Implementation

1. **Brand Identity Pip Placement:**
   - The verified badge pip in the Stitch design sits directly on the bottom-right edge of the 64x64 admin logo container.
   - Accurately positioned using a stacked 22x22 circle with 2px white border and filled `verified_rounded` icon.

2. **Google Button Proportions:**
   - The Admin login button is 56px height (`h-14`) with rounded-xl border radius (12px), unlike the 48px pill button in the Patient Login view.
   - Implemented with exact 56px height and authentic 4-color Google vector.

---

## 2. Deferred Technical Items

1. **Google OAuth & Firebase Authentication:**
   - Real OAuth credential exchange with `FirebaseAuth.instance.signInWithCredential()` is deferred to the Firebase backend milestone.
2. **Dynamic RBAC Query:**
   - Server-side role resolution from Firestore or Azure AD is deferred to the backend integration phase.

---

## 3. Blocking Issues

- **None.** Admin Screen 01 is fully functional locally and builds cleanly.
