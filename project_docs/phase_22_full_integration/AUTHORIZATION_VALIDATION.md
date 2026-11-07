# Authorization Validation

**Phase:** Task 22 — Full Integration  
**Project:** EasyCheck Online  
**Date:** November 1, 2026

## Access Control Test Results

| Test Scenario | Expected Result | Status |
|--------------|----------------|--------|
| Patient reads clinic data | Allowed | ✅ |
| Patient updates queue | Denied | ✅ (Security Rules) |
| Staff accesses own clinic | Allowed | ✅ |
| Staff accesses another clinic | Denied | ✅ (Security Rules) |
| Staff updates another clinic's queue | Denied | ✅ (Security Rules) |
| Unauthenticated user reads data | Denied | ✅ |
| User changes own role | Denied | ✅ (Security Rules) |
| Queue history modification by staff | Denied | ✅ (immutable) |

## Enforcement Mechanism

All authorization is enforced by Firestore Security Rules (`firestore.rules`). Client-side checks are UI-only and not trusted.

## Security Rules Summary

- **Users Collection**: Users can read/write their own profile only
- **Clinics Collection**: Authenticated users can read active clinics; clinic admins can write their own clinic
- **Clinic Members Collection**: Users can read their own memberships; clinic admins can manage staff
- **Queue Sessions Collection**: Authenticated users can read; clinic members with `update_tally` permission can update
- **Queue History Collection**: Authenticated users can read; clinic members with `update_tally` or `reset_tally` can create; updates/deletes not allowed

## Role-Based Access Control

| Role | Can Read Clinics | Can Write Clinics | Can Update Queue | Can Manage Members |
|------|-----------------|-------------------|------------------|-------------------|
| Patient | Active clinics only | Never | Never | Never |
| Front Desk Lead | Own clinic | Own clinic (limited) | Yes | No |
| Triage Coordinator | Own clinic | Own clinic (limited) | Yes | No |
| Clinic Admin | Own clinic | Own clinic (full) | Yes | Yes |
