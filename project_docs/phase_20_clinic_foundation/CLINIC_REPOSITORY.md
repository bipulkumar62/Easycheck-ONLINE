# Clinic Repository

**Phase:** Task 20 — Clinic Repository  
**Project:** EasyCheck Online

## Class: ClinicRepository

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getClinic(clinicId)` | `Future<ClinicModel?>` | Get clinic by ID |
| `createClinic(clinic)` | `Future<void>` | Create new clinic |
| `updateClinic(clinicId, updates)` | `Future<void>` | Update clinic fields |
| `clinicStream(clinicId)` | `Stream<ClinicModel?>` | Real-time listener |
| `activeClinicsStream()` | `Stream<List<ClinicModel>>` | All active clinics |
| `getAllClinics()` | `Future<List<ClinicModel>>` | Get all clinics |
| `isClinicActive(clinicId)` | `Future<bool>` | Check if active |
| `isClinicOnline(clinicId)` | `Future<bool>` | Check online status |

## Class: ClinicMembershipRepository

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getMembership(userId, clinicId)` | `Future<ClinicMembershipModel?>` | Get membership |
| `createMembership(membership)` | `Future<void>` | Create membership |
| `updateMembership(userId, clinicId, updates)` | `Future<void>` | Update membership |
| `getUserMemberships(userId)` | `Future<List<ClinicMembershipModel>>` | User's clinics |
| `getClinicMembers(clinicId)` | `Future<List<ClinicMembershipModel>>` | Clinic's staff |
| `hasPermission(userId, clinicId, permission)` | `Future<bool>` | Check permission |
| `deactivateMembership(userId, clinicId)` | `Future<void>` | Soft delete |
