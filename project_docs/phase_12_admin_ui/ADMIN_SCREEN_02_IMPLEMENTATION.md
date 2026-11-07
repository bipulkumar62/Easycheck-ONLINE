# Admin Screen 02 Implementation: Clinic Admin Dashboard

**Screen Name:** Clinic Admin Dashboard  
**Phase:** Phase 12 — Admin UI Implementation  
**Project:** EasyCheck Online  
**Design System:** Clinical Precision  
**Stitch Source:** `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/clinic_admin_dashboard/`  
**HTML/CSS Source:** `clinic_admin_dashboard/code.html`  
**Visual Reference:** `clinic_admin_dashboard/screen.png` (487 x 1105 px)  
**Shell Type:** `mobile_tab` (Fixed top app bar + fixed bottom 4-tab nav)  
**Flutter Target:** `AdminDashboardScreen` (`lib/features/admin/admin_dashboard_screen.dart`)  
**Route:** `/admin/dashboard` ([AppRoutes.adminDashboard](file:///d:/Easycheck%20ONLINE/lib/app/routes/app_routes.dart#L14))

---

## 1. Visual Hierarchy & Exact Components Implemented

1. **Fixed Top App Bar (Header):**
   - Height 64px (`h-16`), fixed at top with safe-area padding (`pt-safe`), background `surface/90` with `backdrop-blur-xl`, subtle shadow `0 1px 8px rgba(7,59,120,0.04)`.
   - Left Cluster:
     - EasyCheck Admin Logo (height 32px / `h-8`).
     - Subtitle Row: `"CLINIC ADMIN"` in `label-sm` (`#006a42`) + dot separator + `"EASYCHECK ADMIN"` in `label-sm` (`#375e9d`).
     - Clinic Title: `"Apex Care Polyclinic"` in `headline-sm` (`16px`, Plus Jakarta Sans, `#0d1c2e`).
   - Right Cluster:
     - Profile Avatar Button: 32x32 rounded-full staff avatar photo (`Reception Apex`) with shadow `0 1px 4px rgba(7,59,120,0.12)`.

2. **Operational Context & Staff Shift Card:**
   - Card Container: `bg-surface-container-lowest rounded-xl p-4 shadow-sm flex items-center justify-between`.
   - Left: Clinic Title `"Apex Care Polyclinic"` in `headline-md` bold + `"Desk Registration & Doctor Status"` in `body-sm` (`#535f59`).
   - Right (Staff Menu Trigger): 36x36 rounded-full avatar with green online badge pip on bottom-right.
   - Interactive Popover (`#account-popover`): Floating card (`w-64 p-4 bg-surface-container-lowest rounded-xl shadow-xl`):
     - Staff photo + `"Reception Apex"` + `reception.apex@easycheck.med`.
     - Clinic ID Box: `"CLINIC ID"` + `CLN-84920` in monospace font.
     - Logout Action Button: Red tinted button (`bg-error-container text-on-error-container`) with `logout` icon.

3. **Doctor Availability Selector Card (Section 1):**
   - Card Container: `bg-surface-container-lowest rounded-xl p-4 shadow-sm space-y-2`.
   - Header: Stethoscope icon (`stethoscope`, 18px `#006a42`) + `"DOCTOR AVAILABILITY"` in `label-md` uppercase + Doctor Name `"Dr. Rajesh Sharma, MD"` in `headline-sm` + Room `"Internal Medicine • Room 104 Consultation"`.
   - Status Pill: Green dot + `"Online"` in `label-sm` (`bg-primary-fixed text-on-primary-fixed`).
   - 3 Status Buttons Grid:
     1. **Available:** Ring-2 green border (`ring-primary bg-primary-fixed text-on-primary-fixed`), icon `check_circle` (24px) + label `"Available"`.
     2. **Delayed:** Neutral container (`bg-surface-container-low text-on-surface-variant`), icon `schedule` (24px) + label `"Delayed"`.
     3. **Off-Duty:** Neutral container, icon `block` (24px) + label `"Off-Duty"`.
   - Real-time feedback: Shows spinning indicator during saving, followed by confirmation toast.

4. **Main Parchi Counter Card (Section 2 - Central Focus):**
   - Card Container: `bg-surface-container-lowest rounded-xl p-4 shadow-md space-y-4 relative overflow-hidden`.
   - Ambient Glow: `-right-12 -top-12 w-36 h-36 bg-primary-fixed/20 rounded-full blur-2xl`.
   - Header: `"Today’s Parchi Count"` in `headline-lg-mobile` (`22px`, Plus Jakarta Sans bold) + Date `"Wednesday, October 24"`.
   - Token Sequence Tag: `"Seq: P-012"`.
   - Giant Counter Touch Box:
     - Well Container: `bg-surface-container-low rounded-2xl py-6 px-4 flex items-center justify-between gap-2 shadow-inner`.
     - Decrement Button: 64x64 (`w-16 h-16`) circular white button (`bg-surface-container-lowest text-on-surface shadow-sm`) with `remove` icon (32px).
     - Giant Number Display: 68px font-size (`text-[68px]`), Plus Jakarta Sans, tabular numbers (`tabular-nums font-bold leading-none`). Initial value: `"12"`.
     - Pulse Label: `"PARCHI ISSUED"` in `label-sm` uppercase emerald with scale animation.
     - Increment Button: 64x64 (`w-16 h-16`) circular emerald button (`bg-primary text-on-primary shadow-lg ring-4 ring-primary-fixed/40`) with `add` icon (34px).
   - Reset Trigger Button: Text button with restart icon (`restart_alt`, 18px text-error) + `"Reset count to 0"`.

5. **Modal Dialogs:**
   - **Reset Confirmation Modal:** Centered dialog with 48x48 red circle warning icon, headline `"Reset today’s parchi count to 0?"`, warning copy about clinic audit ledger, `"Cancel"` button, and `"Confirm Reset"` red button (`bg-error text-on-error`).
   - **Logout Confirmation Modal:** Centered dialog with 48x48 red circle logout icon, headline `"End Shift Session?"`, copy `"You are logged into Apex Care Polyclinic. Unsaved local changes are synced."`, `"Log out of Reception"` button, and `"Stay signed in"` button.

6. **Transient Toast Notification:**
   - Fixed top floating pill (`bg-inverse-surface text-inverse-on-surface px-4 py-2 rounded-full shadow-lg flex items-center gap-2`).
   - Icon: `check_circle` in `#62dd9e`.
   - Message: `"Saved to Firebase • Updated just now"` or token sequence confirmation.

7. **Fixed Bottom Tab Navigation Bar:**
   - Height 64px (`h-16`), fixed at bottom with `pb-safe`, background `surface/90` with `backdrop-blur-xl`, shadow `0 -1px 8px rgba(7,59,120,0.04)`.
   - 4 Tabs:
     1. **Live Queue:** Icon `format_list_bulleted` (22px) + label `"Live Queue"`. Active state in `#006a42`.
     2. **Intake:** Icon `how_to_reg` (22px) + label `"Intake"`.
     3. **Staff:** Icon `medical_services` (22px) + label `"Staff"`.
     4. **Clinic:** Icon `manage_accounts` (22px) + label `"Clinic"` (links to Reset Studio).

---

## 2. Flutter Files Created or Verified

- `lib/features/admin/admin_dashboard_screen.dart` — Core screen implementation.
- `lib/app/theme/app_colors.dart` — Clinical Precision color tokens.
- `lib/app/theme/app_typography.dart` — Plus Jakarta Sans and Inter tokens.
- `lib/app/routes/app_routes.dart` — Centralized route `/admin/dashboard`.
- `lib/app/app.dart` — Route table registration with `_AdminThemed`.
- `test/widget_test.dart` — Automated widget test coverage.
