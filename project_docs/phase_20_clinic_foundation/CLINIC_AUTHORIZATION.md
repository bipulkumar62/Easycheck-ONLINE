# Clinic Authorization

**Phase:** Task 20 — Clinic Authorization  
**Project:** EasyCheck Online

## Access Rules

| User Type | Can Read Clinics | Can Write Clinics | Can Manage Members | Can Update Queue |
|-----------|-----------------|-------------------|-------------------|-----------------|
| Patient | Active clinics only | Never | Never | Never |
| Front Desk Lead | Own clinic | Own clinic (limited) | No | Yes (update_tally) |
| Triage Coordinator | Own clinic | Own clinic (limited) | No | Yes (update_tally, update_status) |
| Clinic Admin | Own clinic | Own clinic (full) | Yes (manage_staff) | Yes (all) |

## Enforcement

All authorization is enforced by Firestore Security Rules, not client-side logic. The Flutter app must never trust client-side role checks.

## Cross-Clinic Isolation

A user can only access data from clinics they are a member of. The `clinic_members` collection enforces this at the document level.
