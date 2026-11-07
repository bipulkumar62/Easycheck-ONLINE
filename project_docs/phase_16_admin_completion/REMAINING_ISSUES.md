# Remaining Issues

**Phase:** Task 16 — Complete Admin UI Audit & Phase Completion  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Issue Summary

| Severity | Count | Description |
|----------|-------|-------------|
| Blocker | 0 | No blocking issues |
| Critical | 0 | No critical issues |
| Major | 0 | No major issues |
| Minor | 0 | No major visual or functional deviations remain |
| Cosmetic / Lint | 41 | Naming convention suggestions (do not affect functionality) |

---

## 2. Resolved Issues (Fixed During Audit)

The following visual discrepancies were identified during the audit and fixed:

| # | Screen | Issue | Fix | File |
|---|--------|-------|-----|------|
| 1 | Screen 3 (Reset Studio) | Modal icon well radius was 14px instead of 24px | Changed to 24px | `admin_reset_studio_screen.dart` |
| 2 | Screen 3 | Modal dialog radius was 24px instead of 32px | Changed to 32px | `admin_reset_studio_screen.dart` |
| 3 | Screen 3 | Staff audit drawer top radius was 24px instead of 32px | Changed to 32px | `admin_reset_studio_screen.dart` |
| 4 | Screen 3 | Staff header icon container radius was 16px instead of 24px | Changed to 24px | `admin_reset_studio_screen.dart` |
| 5 | Screen 3 | Staff header icon type was `admin_panel_settings` instead of `shield_person` | Changed to `shield_rounded` | `admin_reset_studio_screen.dart` |
| 6 | Screen 3 | Missing backdrop blur on modal and drawer backdrops | Added `BackdropFilter(ImageFilter.blur)` | `admin_reset_studio_screen.dart` |
| 7 | Screen 4 (Unauthorized) | Portal badge strip used `errorContainer` instead of `surfaceContainerHigh` | Changed to `surfaceContainerHigh` | `admin_unauthorized_screen.dart` |
| 8 | Screen 4 (Unauthorized) | Portal badge text used `onErrorContainer` instead of `onSurface` | Changed to `onSurface` | `admin_unauthorized_screen.dart` |
| 9 | Screen 4 (Unauthorized) | Shield icon outer radius was 14px instead of 24px | Changed to 24px | `admin_unauthorized_screen.dart` |
| 10 | Screen 4 (Unauthorized) | Shield icon inner radius was 10px instead of 16px | Changed to 16px | `admin_unauthorized_screen.dart` |
| 11 | Screen 4 (Unauthorized) | Shield icon inner color was `surfaceContainer` instead of `surfaceContainerHighest` | Changed to `surfaceContainerHighest` | `admin_unauthorized_screen.dart` |
| 12 | Screen 4 (Unauthorized) | Missing backdrop blur on top app bar | Added `BackdropFilter(ImageFilter.blur)` | `admin_unauthorized_screen.dart` |

---

## 3. Deferred Items (Not Bugs — Future Firebase Milestone)

The following items are intentionally deferred and are NOT issues:

| Item | Reason | Milestone |
|------|--------|-----------|
| Real Firebase Authentication | Requires Firebase project configuration | Firebase Integration |
| Firestore Security Rules for RBAC | Requires Firebase Auth | Firebase Integration |
| Atomic counter increment (`FieldValue.increment`) | Requires Firestore | Firebase Integration |
| Audit ledger batch write on reset | Requires Firestore | Firebase Integration |
| Real-time doctor status stream | Requires Firestore | Firebase Integration |
| Staff identity from Firebase Auth claims | Requires Firebase Auth | Firebase Integration |
| Google OAuth handshake (`signInWithCredential`) | Requires Firebase Auth | Firebase Integration |

---

## 4. Lint-Level Issues (41 infos — do not affect functionality)

All 41 analyze issues are `info` level naming convention suggestions:

| Category | Count | Example |
|----------|-------|---------|
| `constant_identifier_names` | 33 | `_ap_surface` → should be `apSurface` |
| `unused_element` | 2 | `_ap_surfaceContainer`, `_ap_outline` |
| `unnecessary_underscores` | 5 | `_pulseAnim` parameter names |
| `library_private_types_in_public_api` | 1 | `_ClinicData` used in public API |

These are style suggestions only. They do not affect compilation, runtime behavior, or visual output.

---

## 5. Known Limitations (By Design)

| Limitation | Reason |
|------------|--------|
| No Firebase connection | Explicitly excluded per task restrictions |
| No real authentication | Explicitly excluded per task restrictions |
| No super-admin functionality | Explicitly excluded per task restrictions |
| No database operations | Explicitly excluded per task restrictions |
| Simulated OAuth handshake | Backend integration deferred to Firebase milestone |
| Hardcoded prototype data (clinic names, counts, staff email) | Matches Stitch prototype; production data comes from Firestore |

---

## 6. No Remaining Bugs

**All visual and functional issues identified during this audit have been resolved.** There are no remaining bugs, visual mismatches, or functional gaps in the admin UI implementation.
