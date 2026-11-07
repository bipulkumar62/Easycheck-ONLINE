# Remaining Issues & Observations: Patient Application

**Phase:** Phase 10 — Patient UI Completion & Verification  
**Date:** October 31, 2026

---

## 1. Resolved Items

1. **Resolution of Screen Count Assumptions:**
   - Previous tasks (Task 08 and Task 09) inquired about non-existent "Patient Screen 05" and "Patient Screen 06".
   - The forensic Stitch analysis confirmed that the patient application contains exactly **3 screens**.
   - No synthetic screens were fabricated, preserving the integrity of the original Stitch design system.

2. **Test Automation Stability:**
   - Addressed infinite looping animation timeouts in `widget_test.dart` by replacing indefinite `pumpAndSettle()` with finite `pump(Duration)` calls.
   - Comprehensive test suite now validates all screens in the project.

---

## 2. Deferred Technical Items (Documented for Backend Phase)

1. **Native AdMob Integration:**
   - The AdMob container currently renders the pixel-accurate 320x50 layout matching the Stitch prototype. Integration of `google_mobile_ads` Native AdWidget with live ad unit IDs is deferred to the ads integration milestone.

2. **Google OAuth & Firebase Auth:**
   - Real authentication handshake via `FirebaseAuth` and Google Sign-In SDK is deferred to the Firebase backend integration phase.

3. **Firestore Snapshot Streams:**
   - Dynamic real-time listening on clinic queue documents is deferred to the backend integration phase.

---

## 3. Blocking Issues

- **None.** There are zero blocking issues in the patient application.
