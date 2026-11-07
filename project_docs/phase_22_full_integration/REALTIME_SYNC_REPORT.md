# Realtime Sync Report

**Phase:** Task 22 — Realtime Sync  
**Project:** EasyCheck Online

## Stream Listeners

| Screen | Collection | Document | Trigger |
|--------|-----------|----------|---------|
| Patient Home | clinics | All where isActive=true | New/updated clinic |
| Patient Clinic Details | clinics | {clinicId} | Clinic info change |
| Patient Clinic Details | queue_sessions | {clinicId}_{today} | Parcha count change |
| Admin Dashboard | clinics | {clinicId} | Online/offline change |
| Admin Dashboard | queue_sessions | {clinicId}_{today} | Parcha count change |

## Listener Management

- All streams use `.snapshots()` from Firestore
- Streams are cancelled when widget is disposed
- No memory leaks from orphaned listeners
- Loading states shown during initial fetch
- Error states shown on Firestore errors

## Sync Latency

- Typical sync latency: < 1 second
- Updates propagate within the same Firestore transaction
- All connected clients receive updates simultaneously
