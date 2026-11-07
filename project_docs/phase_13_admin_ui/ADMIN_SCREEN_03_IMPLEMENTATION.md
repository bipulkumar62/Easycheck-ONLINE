# Admin Screen 03 Implementation: Reset Confirmation & Account State Studio

**Screen Name:** Reset Confirmation & Account State Studio  
**Phase:** Phase 13 — Admin UI Implementation  
**Project:** EasyCheck Online  
**Design System:** Clinical Precision  
**Stitch Source:** `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/reset_confirmation_account_state/`  
**HTML/CSS Source:** `reset_confirmation_account_state/code.html`  
**Visual Reference:** `reset_confirmation_account_state/screen.png` (487 x 1105 px)  
**Shell Type:** `mobile_tab` (Fixed top app bar + fixed bottom 4-tab nav)  
**Flutter Target:** `AdminResetStudioScreen` (`lib/features/admin/admin_reset_studio_screen.dart`)  
**Route:** `/admin/reset-studio`

---

## 1. Visual Hierarchy & Exact Components Implemented

### 1.1 Fixed Top App Bar (Header)
- Height 64px, fixed at top with safe-area padding
- Background `surface/90` with subtle shadow
- Left Cluster:
  - EasyCheck Admin Logo (32px height)
  - Subtitle Row: `"CLINIC ADMIN"` + dot separator + `"EASYCHECK ADMIN"`
  - Clinic Title: `"Apex Care Polyclinic"` in `headline-sm` (Plus Jakarta Sans)
- Right Cluster:
  - Profile Avatar Button: 32x32 rounded-full staff avatar photo (`Reception Apex`)

### 1.2 Scenario Selector Toolbar
- Pill container (`surfaceContainerHigh` background, rounded-full)
- 3 tabs:
  1. **Reset Dialog** — Active state (`surfaceContainerLowest` background, error-colored icon)
  2. **Feedback** — Notifications icon, primary color
  3. **Staff Audit** — Badge icon, secondary color

### 1.3 Dashboard Underlay Foundation
- **Quick Status Pill Banner:** Staff avatar (`RS` in `secondaryFixed`), Dr. Rajesh Sharma, General OPD • Room 04, Available pill
- **Parchi Live Counter Card:** Today's Token Tally, count "12", trend `+3 / hr`, "Issue Next (13)" button, "Reset Tally" button, last issued timestamp `10:38 AM (#012)`
- **Waiting Area Queue Preview:**
  - Patient 1: #10 Meera Patel ("Follow-up BP Check • Dr. Rajesh", badge "With Doctor")
  - Patient 2: #11 Harshavardhan Rao ("General Viral Consult • Waiting 8m", badge "Next Up")

### 1.4 Reset Confirmation Dialog (Active when Reset Dialog selected)
- Centered dialog container (`surfaceContainerLowest`, rounded-3xl)
- Icon Container: 56x56 rounded-2xl red container (`errorContainer` at 60% opacity) with `restart_alt` icon (32px)
- Heading: `"Reset today's count?"` in `headline-md` font-bold
- Body: `"This will reset the parchi tally for Apex Care Polyclinic back to 0."`
- Token Chip: Pill badge (`errorContainer`) with `confirmation_number` icon + count issued
- Primary Button: `"Confirm Reset to 0"` (52px height, `error` background, rounded-2xl)
- Secondary Button: `"Cancel"` (48px height, `surfaceContainerHigh` background, rounded-2xl)

### 1.5 Account & Audit Bottom Drawer (Active when Staff Audit selected)
- Slide-up bottom sheet (`surfaceContainerLowest`, rounded-t-3xl)
- Drawer drag handle (12x1.5 rounded-full)
- Staff Identity Header: Shield icon, "Front Desk Lead", Active pill, email, assigned clinic
- Audit Metadata Section: Session Auth Protocol, Daily Reset Permissions, Last Audit Checkpoint
- Quick Action Cards: Audit Activity, Reprint Slip
- Exit Actions: "Log out of Apex Terminal" button (56px), "Close Panel" text button

### 1.6 Fixed Bottom Navigation Bar
- 4 Tabs identical to Admin Dashboard, with **Clinic** (`manage_accounts`) active

---

## 2. Flutter Files Created or Modified

- `lib/features/admin/admin_reset_studio_screen.dart` — Full screen implementation with visual fidelity fixes:
  - Modal icon well border radius: 14px → 24px (matching Stitch `rounded-2xl`)
  - Modal dialog border radius: 24px → 32px (matching Stitch `rounded-3xl`)
  - Staff audit drawer top border radius: 24px → 32px (matching Stitch `rounded-t-3xl`)
  - Staff audit header icon container: 16px → 24px radius, icon changed to `shield_rounded`
  - Backdrop blur added to modal and drawer backdrops (`ImageFilter.blur`)
- `lib/app/theme/app_colors.dart` — Clinical Precision color tokens (existing)
- `lib/app/theme/app_typography.dart` — Plus Jakarta Sans and Inter tokens (existing)
- `lib/app/routes/app_routes.dart` — Centralized route `/admin/reset-studio`
- `lib/app/app.dart` — Route table registration with `_AdminThemed` wrapper
- `test/widget_test.dart` — Automated widget test coverage (includes AdminResetStudioScreen test)

---

## 3. Visual Deviations

| Component | Stitch Reference | Flutter Implementation | Status |
|-----------|-----------------|----------------------|--------|
| Top App Bar | 64px height, backdrop blur | Matches exactly | MATCH |
| Scenario Toolbar | 3-tab pill container | Matches exactly | MATCH |
| Reset Dialog Icon Well | rounded-2xl (24px) | Fixed: 24px radius | MATCH |
| Reset Dialog Container | rounded-3xl (32px) | Fixed: 32px radius | MATCH |
| Staff Audit Drawer | rounded-t-3xl (32px) | Fixed: 32px radius | MATCH |
| Staff Header Icon | rounded-2xl (24px) | Fixed: 24px radius | MATCH |
| Bottom Navigation | 4 tabs, Clinic active | Matches exactly | MATCH |

Remaining visual deviations: Zero. All component proportions, typography tokens, touch boundaries, and dialog layouts match the Stitch prototype.
