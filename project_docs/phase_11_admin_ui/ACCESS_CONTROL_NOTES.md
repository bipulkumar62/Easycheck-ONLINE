# Access Control Notes: Admin Authentication

**Phase:** Phase 11 — Admin UI Implementation  
**Screen Target:** Screen A-01 (Admin Google Authentication)

---

## 1. Architectural Boundaries

1. **Separation of Patient and Admin Domains:**
   - Patient entrypoint: `/patient/login` using the **Clinical Clarity** theme.
   - Admin entrypoint: `/admin/login` using the **Clinical Precision** theme (`_AdminThemed`).
   - The two portals maintain separate route spaces and independent UI hierarchies.

2. **Zero-Trust Role-Based Access Control (RBAC):**
   - Authentication alone does **not** grant administrative privileges.
   - Per the Stitch prototype specifications, a Google account authenticated at `/admin/login` must be verified against central hospital Directory Services (LDAP/Azure AD) or Firestore admin rosters.
   - If unassigned, the user transitions to the **Access Restricted** state or the **Unauthorized Security State Screen** (`/admin/unauthorized`).

3. **Super-Admin Protection:**
   - Clinic desk administrators have scoped privileges strictly confined to their assigned clinic ID (`CLN-84920`).
   - Front Desk Lead permissions allow issuing/revoking tokens and daily tallies, but do **not** grant super-admin access across external clinics or system configurations.

4. **Future Firebase Security Rules Enforcement:**
   - Client-side role claims are strictly untrusted for authorization.
   - All parchi increments, counter resets, and doctor availability toggles will be enforced via Firestore Security Rules using `request.auth.token.role == 'clinic_admin' && resource.data.clinicId == request.auth.token.clinicId`.
