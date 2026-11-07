# User Profile Schema

**Phase:** Task 19 — Firestore Foundation  
**Project:** EasyCheck Online

## Collection: users

**Document ID:** Firebase Auth UID

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| uid | string | Yes | Firebase Auth UID |
| email | string | Yes | User's email |
| displayName | string | No | Display name |
| photoUrl | string | No | Profile photo URL |
| role | string | Yes | 'patient' or 'clinic_admin' |
| createdAt | timestamp | Yes | Account creation |
| updatedAt | timestamp | Yes | Last update |
| isActive | boolean | Yes | Account status |

## Role Values

- `patient` — Can browse clinics, view queue status (read-only)
- `clinic_admin` — Can manage clinic operations (requires clinic_members entry)

## Constraints

- Users cannot change their own role via client write (enforced by Security Rules)
- Users cannot change their UID
- Role assignment is controlled by administrative process, not client input
