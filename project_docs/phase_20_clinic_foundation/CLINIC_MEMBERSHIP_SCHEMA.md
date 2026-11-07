# Clinic Membership Schema

**Phase:** Task 20 — Clinic Membership  
**Project:** EasyCheck Online

## Collection: clinic_members

**Document ID:** Composite: {userId}_{clinicId}

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| userId | string | Yes | Firebase Auth UID |
| clinicId | string | Yes | Assigned clinic ID |
| role | string | Yes | clinic_admin, front_desk_lead, triage_coordinator |
| permissions | array<string> | Yes | Granted permissions |
| isActive | boolean | Yes | Membership active status |
| joinedAt | timestamp | Yes | Assignment time |
| assignedBy | string | No | UID of assigner |

## Valid Roles

- `clinic_admin` — Full clinic operations
- `front_desk_lead` — Daily tallies, doctor status
- `triage_coordinator` — Patient queue management

## Valid Permissions

- `update_tally` — Increment/decrement parcha number
- `update_status` — Change doctor availability
- `reset_tally` — Daily reset
- `manage_staff` — Manage clinic memberships
- `view_queue` — View queue information

## Constraints

- Users cannot assign themselves as clinic_admin
- Membership changes require clinic_admin with manage_staff permission
- Cross-clinic membership is not allowed
