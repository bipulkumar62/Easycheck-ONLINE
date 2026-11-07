# Security Rules

**Phase:** Task 20 — Clinic Authorization  
**Project:** EasyCheck Online

## Firestore Security Rules (firestore.rules)

### Users Collection
- Read: Authenticated, own doc only
- Write: Authenticated, own doc only
- Create: Authenticated, own doc only, role must be patient or clinic_admin
- Update: Authenticated, own doc only, cannot change role or uid
- Delete: Never

### Clinics Collection
- Read: Authenticated, active clinics only
- Write: Clinic admin, own clinic only
- Create: Clinic admin, valid clinicId format
- Update: Clinic admin with manage_staff permission, own clinic only
- Delete: Never

### Clinic Members Collection
- Read: Authenticated, own memberships or clinic admin
- Write: Clinic admin with manage_staff permission
- Create: Clinic admin with manage_staff permission
- Delete: Clinic admin with manage_staff permission

### Queue Sessions Collection
- Read: Authenticated, patient or clinic member
- Write: Clinic member with update_tally permission, clinicId must match
- Create: Never (system-created)
- Delete: Never

### Queue History Collection
- Read: Authenticated, patient or clinic member
- Write: Clinic member with update_tally or reset_tally permission, clinicId must match, performedBy must match auth.uid
- Update: Never
- Delete: Never
