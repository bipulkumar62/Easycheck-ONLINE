# Access Control Notes: Clinic Admin Dashboard

**Phase:** Phase 12 — Admin UI Implementation  
**Screen Target:** Screen A-02 (Clinic Admin Dashboard)

---

## 1. Operational Security Constraints

1. **Scoped Clinic Authority:**
   - Operational controls (parchi token issuance, decrements, daily resets, doctor availability toggles) are strictly bound to the authenticated clinic identifier: `CLN-84920` (Apex Care Polyclinic).
   - An administrator cannot view or manipulate token counts or practitioner schedules belonging to external healthcare facilities.

2. **Daily Reset Audit Trail:**
   - The reset action is classified as destructive and audit-grade.
   - The UI enforces a two-step explicit confirmation dialog warning the operator that the reset is permanently logged.
   - In production Firebase implementation, reset requests will require an audit payload containing `timestamp`, `operatorUid`, `operatorEmail`, and `preResetCount` written to an immutable subcollection.

3. **Front Desk Shift Isolation:**
   - Logging out of the reception session immediately clears local terminal state and redirects to `/admin/login`.
   - Client-side token caches must not persist across operator handovers.

4. **Zero Frontend Trust:**
   - Frontend validation prevents negative parchi numbers (`_parchiCount <= 0`).
   - Firestore security rules will independently enforce non-negative constraints: `request.resource.data.todayParchiCount >= 0`.
