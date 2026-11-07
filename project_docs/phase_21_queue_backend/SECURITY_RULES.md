# Security Rules

**Phase:** Task 21 — Queue Security Rules  
**Project:** EasyCheck Online

## queue_sessions Collection

```
allow read: if isAuthenticated()
  && (isPatient() || isClinicMember(request.auth.uid, resource.data.clinicId));

allow update: if isAuthenticated()
  && isClinicMember(request.auth.uid, resource.data.clinicId)
  && hasClinicPermission(request.auth.uid, resource.data.clinicId, 'update_tally')
  && request.resource.data.clinicId == resource.data.clinicId
  && request.resource.data.currentParchaNumber == resource.data.currentParchaNumber + 1;

allow create: if false;
allow delete: if false;
```

## queue_history Collection

```
allow read: if isAuthenticated()
  && (isPatient() || isClinicMember(request.auth.uid, resource.data.clinicId));

allow create: if isAuthenticated()
  && isClinicMember(request.auth.uid, resource.data.clinicId)
  && (hasClinicPermission(..., 'update_tally') || hasClinicPermission(..., 'reset_tally'))
  && request.resource.data.clinicId == resource.data.clinicId
  && request.resource.data.performedBy == request.auth.uid;

allow update: if false;
allow delete: if false;
```

## Cross-Clinic Protection

A staff member from Clinic A cannot:
- Read or write queue_sessions for Clinic B
- Read or write queue_history for Clinic B
- Change Clinic B's online/offline status

Enforced by: `isClinicMember(request.auth.uid, resource.data.clinicId)` check in every rule.
