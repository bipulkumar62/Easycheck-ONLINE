# Admin Navigation Audit

**Phase:** Task 16 — Complete Admin UI Audit & Phase Completion  
**Project:** EasyCheck Online  
**Date:** October 31, 2026  
**Design System:** Clinical Precision (Admin)

---

## 1. Route Table

All routes are defined in `lib/app/routes/app_routes.dart` and registered in `lib/app/app.dart`.

| Route Constant | Value | Screen | Shell Type | Theme |
|----------------|-------|--------|------------|-------|
| `AppRoutes.initial` | `/` | Patient Login | `mobile_blank` | Patient |
| `AppRoutes.patientLogin` | `/patient/login` | Patient Login | `mobile_blank` | Patient |
| `AppRoutes.patientHome` | `/patient/home` | Patient Home | `mobile_tab` | Patient |
| `AppRoutes.patientClinicDetails` | `/patient/clinic-details` | Clinic Details | `mobile_stack` | Patient |
| `AppRoutes.adminLogin` | `/admin/login` | Admin Login | `mobile_blank` | Admin |
| `AppRoutes.adminDashboard` | `/admin/dashboard` | Admin Dashboard | `mobile_tab` | Admin |
| `AppRoutes.adminResetStudio` | `/admin/reset-studio` | Reset Studio | `mobile_tab` | Admin |
| `AppRoutes.adminUnauthorized` | `/admin/unauthorized` | Unauthorized | `mobile_stack` | Admin |

---

## 2. Admin Navigation Flow

### Entry Points

```
Patient Login (/patient/login)
  └── Google Sign-In → Patient Home (/patient/home)

Admin Login (/admin/login)
  └── Simulated OAuth → Admin Dashboard (/admin/dashboard)

Admin Dashboard (/admin/dashboard)
  └── Bottom Nav "Clinic" tab → Admin Reset Studio (/admin/reset-studio)

Admin Reset Studio (/admin/reset-studio)
  └── Bottom Nav "Live Queue" tab → Admin Dashboard (/admin/dashboard)
  └── "Log out of Apex Terminal" → Admin Login (/admin/login)

Admin Unauthorized (/admin/unauthorized)
  └── Back button → previous screen (Navigator.pop)
  └── "Switch Google Account" → redirect to login
  └── "Request Clinic Access" → toast confirmation only
```

### Patient-to-Admin Separation

Patient routes use the `PatientTheme` (Clinical Clarity — Inter font, navy/emerald palette):
- `/patient/login`
- `/patient/home`
- `/patient/clinic-details`

Admin routes use the `AdminTheme` (Clinical Precision — Plus Jakarta Sans + Inter, emerald/navy palette):
- `/admin/login`
- `/admin/dashboard`
- `/admin/reset-studio`
- `/admin/unauthorized`

**Verification:** No patient route exposes admin functionality, and no admin route exposes patient functionality. The `_AdminThemed` wrapper ensures admin screens always render with the Clinical Precision theme regardless of the default theme.

---

## 3. Bottom Navigation Bar Audits

### Admin Dashboard Bottom Nav (4 tabs)

| Position | Label | Icon | Active Color | Inactive Color | Route Action |
|----------|-------|------|-------------|----------------|--------------|
| 0 | Live Queue | `format_list_bulleted_rounded` | primary (#006A42) | outline (#6D7A70) | setState `_selectedTab = 0` |
| 1 | Intake | `how_to_reg_rounded` | primary | outline | setState `_selectedTab = 1` |
| 2 | Staff | `medical_services_rounded` | primary | outline | setState `_selectedTab = 2` |
| 3 | Clinic | `manage_accounts_rounded` | primary | outline | pushNamed `/admin/reset-studio` |

### Admin Reset Studio Bottom Nav (4 tabs)

| Position | Label | Icon | Active Color | Inactive Color | Route Action |
|----------|-------|------|-------------|----------------|--------------|
| 0 | Live Queue | `format_list_bulleted_rounded` | primary | onSurfaceVariant | pushReplacementNamed `/admin/dashboard` |
| 1 | Intake | `how_to_reg_rounded` | primary | onSurfaceVariant | setState `_selectedTab = 1` |
| 2 | Staff | `medical_services_rounded` | primary | onSurfaceVariant | setState `_selectedTab = 2` |
| 3 | Clinic | `manage_accounts_rounded` | primary | onSurfaceVariant | setState `_selectedTab = 3` (already active) |

---

## 4. Modal/Popover Navigation

### Admin Dashboard

| Trigger | Opens | Closes | Destination on Confirm |
|---------|-------|--------|----------------------|
| Staff avatar tap | Account popover | Outside tap / avatar tap | N/A |
| Popover "Log Out" | Logout confirmation modal | Cancel / confirm | `/admin/login` (confirm) |
| Reset trigger | Reset confirmation modal | Cancel / confirm | N/A (count resets to 0) |

### Admin Reset Studio

| Trigger | Opens | Closes | Destination |
|---------|-------|--------|-------------|
| Reset Dialog tab | Reset modal | Backdrop click / Cancel | N/A |
| Staff Audit tab | Staff audit drawer | Backdrop click / Close Panel | N/A |
| Drawer "Log out of Apex Terminal" | N/A | N/A | `/admin/login` |

---

## 5. Navigation Integrity Verification

| Check | Result |
|-------|--------|
| All 4 admin routes registered in `app.dart` | ✅ PASS |
| All 4 admin routes wrapped with `_AdminThemed` | ✅ PASS |
| No route collisions between patient and admin | ✅ PASS |
| Bottom nav "Clinic" tab from Dashboard → Reset Studio | ✅ PASS |
| Bottom nav "Live Queue" tab from Reset Studio → Dashboard | ✅ PASS |
| Logout from Dashboard → `/admin/login` | ✅ PASS |
| Logout from Reset Studio → `/admin/login` | ✅ PASS |
| Unauthorized screen back button → `Navigator.pop()` | ✅ PASS |
| Initial route is patient login (`/`) | ✅ PASS |

---

## 6. Navigation Deviations

**Total navigation deviations found:** 0

All navigation flows match the Stitch prototype specifications. Patient and admin domains are completely separated with independent route spaces and theme wrappers.
