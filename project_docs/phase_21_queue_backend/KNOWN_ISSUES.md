# Known Issues

**Phase:** Task 21 — Queue Backend  
**Project:** EasyCheck Online

## Issues

| Issue | Severity | Description | Mitigation |
|-------|----------|-------------|------------|
| No clinic data in Firestore | High | No clinics have been created yet | Create clinic documents via admin or console |
| No clinic memberships | High | No staff are assigned to clinics | Create membership documents via admin |
| Firestore rules not deployed | High | Permissive rules still active | Deploy updated rules via Firebase Console |
| No real-time testing | Medium | Queue updates not tested with real Firebase | Test with Firebase Emulator |
