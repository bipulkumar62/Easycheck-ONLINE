# Known Issues

**Phase:** Task 22 — Full Integration  
**Project:** EasyCheck Online  
**Date:** November 1, 2026

## Known Issues

| Issue | Severity | Description | Mitigation |
|-------|----------|-------------|------------|
| No clinic data in Firestore | High | No clinics have been created yet | Create clinic documents via Firebase Console |
| No staff memberships in Firestore | High | No staff assigned to clinics | Create clinic_members documents |
| Firestore Security Rules not deployed | High | Permissive rules expire Nov 29, 2026 | Deploy updated rules via Firebase Console |
| No real-time testing | Medium | Not tested with live Firebase | Test with Firebase Emulator |
| No logout button in UI | Low | Not in Stitch UI design | Add when required by design |

## Remaining Work Before Production

1. Deploy Firestore Security Rules via Firebase Console
2. Create clinic documents in Firestore
3. Create staff membership documents in Firestore
4. Test with Firebase Emulator
5. Test with real Firebase project
