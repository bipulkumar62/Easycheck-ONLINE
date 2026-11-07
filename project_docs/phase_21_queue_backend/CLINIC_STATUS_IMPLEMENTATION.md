# Clinic Status Implementation

**Phase:** Task 21 — Clinic Status  
**Project:** EasyCheck Online

## Clinic Online/Offline Status

Stored in `clinics` collection as `isOnline` boolean field.

### Staff Actions

- Mark clinic online: `isOnline = true`
- Mark clinic offline: `isOnline = false`
- Requires `update_status` permission
- Updated via `ClinicRepository.updateClinic(clinicId, {'isOnline': value})`

### Patient View

- Patients see clinic online/offline status in real-time
- Stream listener on `clinics/{clinicId}` document
- UI shows green dot (online) or gray dot (offline)

## Security

- Only clinic members with `update_status` permission can change status
- Security Rules validate: `hasClinicPermission(uid, clinicId, 'update_status')`
- Clinic ID in request must match document ID
