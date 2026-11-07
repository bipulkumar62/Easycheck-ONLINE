# Visual Comparison: Admin Screen 02 (Clinic Admin Dashboard)

**Phase:** Phase 12 — Admin UI Implementation  
**Screen Target:** Screen A-02 (Clinic Admin Dashboard)  
**Reference Screenshot:** `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/clinic_admin_dashboard/screen.png` (487 x 1105 px)  
**Flutter Implementation:** `lib/features/admin/admin_dashboard_screen.dart`

---

## 1. Visual Comparison Checklist

| Visual Component | Stitch Reference Property | Flutter Implementation | Status |
| :--- | :--- | :--- | :--- |
| **Top App Bar** | 64px height, frosted blur, logo, Clinic Admin subtitle, staff avatar | 64px fixed Container with BackdropFilter, `AssetConstants.logoAdmin`, `AssetConstants.avatarReceptionApex` | **MATCH** |
| **Operational Context Card**| Title `Apex Care Polyclinic` bold + subtitle `Desk Registration & Doctor Status` | Exact styling in `AdminTypography.headlineMd` & `bodySm` | **MATCH** |
| **Staff Profile Popover** | 256px width floating card with email, Clinic ID `CLN-84920`, red logout button | Positioned floating card matching exact dimensions and tokens | **MATCH** |
| **Doctor Availability Card** | Stethoscope icon, `Dr. Rajesh Sharma, MD`, `Online` pill, 3 state buttons | 3 status buttons grid (`Available`, `Delayed`, `Off-Duty`) with active ring | **MATCH** |
| **Today's Parchi Card** | Header date `Wednesday, October 24`, sequence badge `Seq: P-012` | Exact date typography and dynamic `_tokenBadge` | **MATCH** |
| **Giant Touch Targets** | 64x64 decrement button (`remove`), 64x64 emerald increment button (`add`) | 64x64 circular buttons with 32px / 34px icon sizes | **MATCH** |
| **Giant Counter Value** | `text-[68px]` tabular numbers, scale animation on tap, `PARCHI ISSUED` label | 68px Plus Jakarta Sans bold with `_counterScaleAnim` | **MATCH** |
| **Reset Trigger** | Red restart icon (`restart_alt`) + `Reset count to 0` | Styled InkWell trigger with `Icons.restart_alt_rounded` | **MATCH** |
| **Reset Modal Dialog** | Centered dialog with 48x48 red circle warning icon, audit warning text, Cancel & Confirm buttons | `_buildResetModal()` with matching typography and action buttons | **MATCH** |
| **Logout Modal Dialog** | Centered dialog with 48x48 red circle logout icon, session shift copy, Stay signed in & Log out buttons | `_buildLogoutModal()` with matching action buttons | **MATCH** |
| **Transient Toast** | Floating top pill in `inverse-surface` with `check_circle` icon | `_buildToast()` with smooth opacity animation | **MATCH** |
| **Bottom Navigation Bar** | 4 Tabs (`Live Queue`, `Intake`, `Staff`, `Clinic`), 64px frosted height | Frosted bar with 4 tabs; Live Queue active in `#006a42` | **MATCH** |

---

## 2. Visual Deviations
- **Remaining Visual Deviations:** **Zero**. All component proportions, typography tokens, touch boundaries, and dialog layouts match the Stitch prototype.
