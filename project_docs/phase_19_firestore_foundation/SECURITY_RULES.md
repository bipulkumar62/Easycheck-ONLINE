# Security Rules

**Phase:** Task 19 — Firestore Foundation  
**Project:** EasyCheck Online

## File: firestore.rules

### Helper Functions

| Function | Description |
|----------|-------------|
| `isAuthenticated()` | Check if request.auth != null |
| `getUserRole(uid)` | Get user's role from users collection |
| `isPatient(uid)` | Check if user role is 'patient' |
| `isClinicAdmin(uid)` | Check if user role is 'clinic_admin' |
| `isClinicMember(uid, clinicId)` | Check if user is active member of clinic |
| `hasClinicPermission(uid, clinicId, permission)` | Check specific permission |

### Collection Rules

| Collection | Read | Write | Create | Delete |
|------------|------|-------|--------|--------|
| users | Authenticated (own doc only) | Authenticated (own doc only) | Authenticated (own doc only) | Never |
| clinics | Authenticated (active clinics) | Clinic admin (own clinic) | Clinic admin | Never |
| clinic_members | Authenticated (own memberships or admin) | Clinic admin (manage_staff) | Clinic admin (manage_staff) | Clinic admin (manage_staff) |
| queue_sessions | Authenticated (patient or clinic member) | Clinic member (update_tally) | Never | Never |
| queue_history | Authenticated (patient or clinic member) | Clinic member (update_tally/reset_tally) | Never | Never |

### Key Security Properties

1. Users can only read/write their own profile
2. Users cannot change their role or UID
3. Clinic members can only access their own clinic's data
4. Patients can read active clinic data but cannot write
5. Queue history is immutable
6. Cross-clinic access is prevented
