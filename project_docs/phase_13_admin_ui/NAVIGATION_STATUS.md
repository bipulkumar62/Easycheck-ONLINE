# Navigation Status: Admin Screen 03 (Reset Confirmation & Account State Studio)

**Phase:** Phase 13 — Admin UI Implementation  
**Screen Target:** Screen A-03 (Reset Confirmation & Account State Studio)  
**Route:** `/admin/reset-studio`

---

## 1. Entry Navigation

| From Screen | Trigger | Route Transition |
|-------------|---------|-----------------|
| **Admin Screen 02** (Dashboard) | Tap bottom nav "Clinic" tab (`manage_accounts` icon) | `pushReplacementNamed('/admin/reset-studio')` |
| **Admin Screen 01** (Login) | Successful OAuth handshake → redirect | `pushReplacementNamed('/admin/dashboard')` then manual navigation to reset studio |

The Reset Studio is registered in `app.dart` routes as:
```dart
AppRoutes.adminResetStudio: (_) => _AdminThemed(child: const AdminResetStudioScreen()),
```

---

## 2. Exit Navigation

| Destination | Trigger | Route Transition |
|-------------|---------|-----------------|
| **Admin Screen 02** (Dashboard) | Bottom nav "Live Queue" tab | `pushReplacementNamed('/admin/dashboard')` |
| **Admin Screen 01** (Login) | "Log out of Apex Terminal" button | `pushReplacementNamed('/admin/login')` |

---

## 3. Bottom Navigation Bar (4 Tabs)

| Position | Label | Icon | Active State | Route Action |
|----------|-------|------|-------------|--------------|
| 1 | Live Queue | `format_list_bulleted` | Inactive | Navigates to `/admin/dashboard` |
| 2 | Intake | `how_to_reg` | Inactive | No-op (state change only) |
| 3 | Staff | `medical_services` | Inactive | No-op (state change only) |
| 4 | Clinic | `manage_accounts` | **Active** (emerald) | Already on this screen |

---

## 4. Route Integrity

- All 4 admin routes (`/admin/login`, `/admin/dashboard`, `/admin/reset-studio`, `/admin/unauthorized`) registered in `app.dart`
- All routes wrapped with `_AdminThemed` widget applying `AdminTheme` (Clinical Precision)
- Patient routes (`/patient/login`, `/patient/home`, `/patient/clinic-details`) remain on `PatientTheme` (Clinical Clarity)
- No route collisions or missing registrations
