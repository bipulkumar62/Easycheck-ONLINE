# Admin Screen Map: EasyCheck Online

**Design System:** Clinical Precision  
**Source Directory:** `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/`  
**Total Screens:** 4 Screens  

---

## Screen 1: Google Authentication Screen

- **Folder Path:** `google_authentication/`
- **Source Code:** `google_authentication/code.html`
- **Visual Reference:** `google_authentication/screen.png` (487 x 1105 px)
- **Shell Type:** `mobile_blank` (Full viewport, no top app bar, no bottom tab bar)

### 1. Visual Hierarchy & Exact Visible Components

1. **Ambient Background:**
   - Soft off-white base (`#f8f9ff`).
   - Radial ambient orbs:
     - Top orb: `-top-12 w-64 h-64 bg-primary-container/10 rounded-full blur-3xl`.
     - Right orb: `top-20 right-4 w-48 h-48 bg-secondary/10 rounded-full blur-2xl`.

2. **Centered Brand Identity:**
   - Logo Container: `w-16 h-16 rounded-xl bg-surface-container-lowest p-2 shadow-md flex items-center justify-center relative`.
     - EasyCheck Admin square logo mark (48x48 / `w-12 h-12`).
     - Verified badge pip: Bottom-right corner green circle (`bg-primary text-on-primary rounded-full p-0.5 shadow-sm`) with `verified` icon (14px).
   - Brand Wordmark: Upper title `"EASYCHECK ONLINE"` in uppercase `label-sm` bold (`#375e9d`, tracking-widest).
   - Headline (H1): `"Clinic Admin"` in `headline-xl-mobile` (`28px`, font-weight 700, Plus Jakarta Sans, `#0d1c2e`).
   - Subtitle: `"Sign in to manage your clinic."` in `body-md` (`14px`, `#3d4a41`).

3. **Primary Authentication Card:**
   - Card Container (`#auth-main-card`): `w-full max-w-sm bg-surface-container-lowest rounded-2xl shadow-sm p-4 mt-4`.
   - Google Sign-in Button (`#btn-google-login`): Height 56px (`h-14`) rounded-xl container (`bg-surface-container-lowest shadow-md hover:bg-surface-container-low`):
     - Official Multi-colored Google "G" SVG (20x20).
     - Label: `"Continue with Google"` in `label-lg` (`14px`, font-weight 600, `#0d1c2e`).
     - Animated OAuth Loading Overlay (`#btn-loader`): Hidden by default. Includes spinning circular loader (`animate-spin h-5 w-5 text-primary`) + `"Authenticating OAuth..."` in `label-md`.
   - Access Disclaimer: Centered text `"Authorized clinic staff access only."` in `body-sm` (`12px`, `#3d4a41`).

4. **Dynamic State Transition Banner (`#status-card`):**
   - Hidden by default; rendered via JS:
     - **Verified State:** Green circle with `check_circle` + `"IDENTITY VERIFIED"` + `"Dr. Sarah Jenkins"` + `"Lead Triage • Station 4 Ready"` + spinner `"Redirecting to Live Queue..."`.
     - **Denied State:** Red circle with `gpp_bad` + `"ACCESS RESTRICTED"` + `"Unassigned Account"` + text explaining unmapped Google account + link `"Request role elevation →"` triggering the Helpdesk Modal.

5. **Access Provisioning Helpdesk Modal Dialog (`#helpdesk-modal`):**
   - Backdrop: `fixed inset-0 bg-inverse-surface/40 backdrop-blur-sm z-50 flex items-end sm:items-center justify-center p-4`.
   - Modal Container: `bg-surface-container-lowest rounded-2xl p-4 w-full max-w-sm shadow-xl`.
   - Header: Key icon (`vpn_key`, 24px `#375e9d`) + Close button (`close`, 20px).
   - Title & Copy: `"Access Provisioning"` in `headline-sm` bold + explanation of central LDAP/Azure AD directory services.
   - Internal Support Contacts: Call extension `Ext: 4092 (Triage Operations)` and email `admin-it@metrohealth.net`.
   - Action Button: `"Understood • Return to Login"` in `label-lg` (`h-12 bg-primary text-on-primary rounded-xl`).

### 2. Navigation & User Interactions

- **Google Sign-In Trigger (`handleGoogleSignIn()`):** Disables button, shows loader for 1200ms, and reveals dynamic verification banner before redirecting to the Dashboard.
- **Access Request Trigger (`showResetDialog()` / `closeHelpDialog()`):** Opens and closes the LDAP access provisioning modal dialog.

### 3. Asset & Resource References

- **Admin Logo Image:** `https://lh3.googleusercontent.com/aida/AEtjO1X3l5buskUI26MCSG0msv0l40HhrrsRLQ0QCA2vvolKgV21-s9B0xkw9LfXhSCj7E_Dqtxg4CI1JBqyA2cxsnaBXO4IpBx323kEUNrDyI8nIh8qhzxQc3QloQ0d7J2o1N7h79s1JFTU10rp_LrpS-sBniqLI8WYpDjsW8-WC4hHd2YxroRRHzXDX8Jgj7YXohG5YOPMGIhY4b3sw5g1t0A3P_7S9xL_hM4FaAgNqdwcTQ`
- **Icons:** `verified`, `vpn_key`, `close`, `call`, `mail`, `check_circle`, `gpp_bad`.
- **Fonts:** Plus Jakarta Sans (600, 700), Inter (400, 500, 600, 700).

---

## Screen 2: Clinic Admin Dashboard

- **Folder Path:** `clinic_admin_dashboard/`
- **Source Code:** `clinic_admin_dashboard/code.html`
- **Visual Reference:** `clinic_admin_dashboard/screen.png` (487 x 1105 px)
- **Shell Type:** `mobile_tab` (Fixed top app bar + fixed bottom tab navigation)

### 1. Visual Hierarchy & Exact Visible Components

1. **Fixed Top App Bar (Header):**
   - Height 64px (`h-16`), fixed at top with safe-area padding (`pt-safe`), background `surface/90` with `backdrop-blur-xl`, shadow `0 1px 8px rgba(7,59,120,0.04)`.
   - Left Cluster:
     - EasyCheck Admin Logo (height 32px / `h-8`).
     - Subtitle Row: `"CLINIC ADMIN"` in `label-sm` (`#006a42`) + dot separator + `"EASYCHECK ADMIN"` in `label-sm` (`#375e9d`).
     - Clinic Title: `"Apex Care Polyclinic"` in `headline-sm` (`16px`, Plus Jakarta Sans, `#0d1c2e`).
   - Right Cluster:
     - Profile Avatar Button: 32x32 rounded-full staff avatar photo (`Reception Apex`) with shadow `0 1px 4px rgba(7,59,120,0.12)`.

2. **Operational Context & Staff Shift Card:**
   - Card Container: `bg-surface-container-lowest rounded-xl p-4 shadow-sm flex items-center justify-between`.
   - Left: Clinic Title `"Apex Care Polyclinic"` in `headline-md` bold + `"Desk Registration & Doctor Status"` in `body-sm` (`#535f59`).
   - Right (Staff Menu Trigger `#account-menu-trigger`): 36x36 rounded-full avatar with green online badge pip on bottom-right.
   - Interactive Popover (`#account-popover`): Hidden floating card (`w-64 p-4 bg-surface-container-lowest rounded-xl shadow-xl`):
     - Staff photo + `"Reception Apex"` + `reception.apex@easycheck.med`.
     - Clinic ID Box: `"CLINIC ID"` + `CLN-84920` in monospace font.
     - Logout Action Button (`#btn-open-logout`): Red tinted button (`bg-error-container text-on-error-container`) with `logout` icon.

3. **Doctor Availability Selector Card (Section 1):**
   - Card Container: `bg-surface-container-lowest rounded-xl p-4 shadow-sm space-y-2`.
   - Header: Stethoscope icon (`stethoscope`, 18px `#006a42`) + `"DOCTOR AVAILABILITY"` in `label-md` uppercase + Doctor Name `"Dr. Rajesh Sharma, MD"` in `headline-sm` + Room `"Internal Medicine • Room 104 Consultation"`.
   - Status Pill (`#sync-pill`): Green dot + `"Online"` in `label-sm` (`bg-primary-fixed text-on-primary-fixed`).
   - 3 Status Buttons Grid (`#doctor-status-group`):
     1. **Available (`#btn-status-available`):** Ring-2 green border (`ring-primary bg-primary-fixed text-on-primary-fixed`), icon `check_circle` (24px) + label `"Available"`.
     2. **Delayed (`#btn-status-delayed`):** Neutral container (`bg-surface-container-low text-on-surface-variant`), icon `schedule` (24px) + label `"Delayed"`.
     3. **Off-Duty (`#btn-status-unavailable`):** Neutral container, icon `block` (24px) + label `"Off-Duty"`.
   - Real-time feedback container (`#status-feedback-container`): Shows spinning sync indicator and "Saving to backend..." / "Saved to Firebase".

4. **Main Parchi Counter Card (Section 2 - Central Focus):**
   - Card Container: `bg-surface-container-lowest rounded-xl p-4 shadow-md space-y-4 relative overflow-hidden`.
   - Ambient Glow: `-right-12 -top-12 w-36 h-36 bg-primary-fixed/20 rounded-full blur-2xl`.
   - Header: `"Today’s Parchi Count"` in `headline-lg-mobile` (`22px`, Plus Jakarta Sans bold) + Date `"Wednesday, October 24"`.
   - Token Sequence Tag (`#token-badge`): `"Seq: P-012"`.
   - Giant Counter Touch Box:
     - Well Container: `bg-surface-container-low rounded-2xl py-6 px-4 flex items-center justify-between gap-2 shadow-inner`.
     - Decrement Button (`#counter-decrement`): 64x64 (`w-16 h-16`) circular white button (`bg-surface-container-lowest text-on-surface shadow-sm active:scale-90`) with `remove` icon (32px).
     - Giant Number Display (`#counter-display`): 68px font-size (`text-[68px]`), Plus Jakarta Sans, tabular numbers (`tabular-nums font-bold leading-none`). Initial value: `"12"`.
     - Pulse Label (`#counter-pulse-label`): `"PARCHI ISSUED"` in `label-sm` uppercase emerald.
     - Increment Button (`#counter-increment`): 64x64 (`w-16 h-16`) circular emerald button (`bg-primary text-on-primary shadow-lg ring-4 ring-primary-fixed/40 active:scale-90`) with `add` icon (34px).
   - Reset Trigger Button (`#btn-trigger-reset`): Text button with restart icon (`restart_alt`, 18px text-error) + `"Reset count to 0"`.

5. **Modal Dialogs:**
   - **Reset Confirmation Modal (`#modal-reset`):** Centered dialog with 48x48 red circle warning icon, headline `"Reset today’s parchi count to 0?"`, warning copy about clinic audit ledger, `"Cancel"` button, and `"Confirm Reset"` red button (`bg-error text-on-error`).
   - **Logout Confirmation Modal (`#modal-logout`):** Centered dialog with 48x48 red circle logout icon, headline `"End Shift Session?"`, copy `"You are logged into Apex Care Polyclinic. Unsaved local changes are synced."`, `"Log out of Reception"` button, and `"Stay signed in"` button.

6. **Transient Toast Notification (`#transient-toast`):**
   - Fixed top-20 floating pill (`bg-inverse-surface text-inverse-on-surface px-4 py-2 rounded-full shadow-lg flex items-center gap-2`).
   - Icon: `check_circle` in `#62dd9e`.
   - Message: `"Saved to Firebase • Updated just now"`.

7. **Fixed Bottom Tab Navigation Bar:**
   - Height 64px (`h-16`), fixed at bottom with `pb-safe`, background `surface/90` with `backdrop-blur-xl`, shadow `0 -1px 8px rgba(7,59,120,0.04)`.
   - 4 Tabs:
     1. **Live Queue (`data-path="live-queue"`):** Icon `format_list_bulleted` (22px) + label `"Live Queue"`. Active state in `#006a42`.
     2. **Intake (`data-path="triage-intake"`):** Icon `how_to_reg` (22px) + label `"Intake"`.
     3. **Staff (`data-path="practitioners"`):** Icon `medical_services` (22px) + label `"Staff"`.
     4. **Clinic (`data-path="admin-profile"`):** Icon `manage_accounts` (22px) + label `"Clinic"`.

### 2. Navigation & User Interactions

- **Counter Increment (`btnIncrement`):** Increments count by 1, updates sequence tag (`Seq: P-013`), scales number display, pulses label, and displays toast notification.
- **Counter Decrement (`btnDecrement`):** Decrements count by 1 (disabled when count is 0) and displays toast notification.
- **Doctor Status Switch:** Tapping status button immediately updates active styling, sets saving state, and confirms with toast.
- **Reset Flow:** Opens `#modal-reset`, confirmed reset sets count to 0.
- **Profile Popover & Logout:** Tapping avatar opens `#account-popover`; tapping logout opens `#modal-logout`.

### 3. Asset & Resource References

- **Logo Image:** EasyCheck Admin logo (same as Screen 1).
- **Staff Photo:** `https://lh3.googleusercontent.com/aida-public/AB6AXuA7WvlN35T1eSzt05t8hl1O6gx25tL5OSNzibqwt3j_FE70apiBkx6z-m-YweSaq9O7fR6_bbBbuyB-YByT7HE676ZsTFFbDiF5cejmFvCcAXaufIEg9ycz2ssMcrPqmxJeHRam6-8Qj4E2ym1p58I6pCikazzpGWT_W5mFq4Fgh3tvd4NDAZeFyoYkE6UAjQ-2-1SwG3G3bprjDTAvPrnUrjFIeOIvZpmGplEoLsCn`
- **Icons:** `stethoscope`, `check_circle`, `schedule`, `block`, `remove`, `add`, `restart_alt`, `logout`, `warning`, `format_list_bulleted`, `how_to_reg`, `medical_services`, `manage_accounts`, `sync`, `verified`.

---

## Screen 3: Reset Confirmation & Account State Studio

- **Folder Path:** `reset_confirmation_account_state/`
- **Source Code:** `reset_confirmation_account_state/code.html`
- **Visual Reference:** `reset_confirmation_account_state/screen.png` (487 x 1105 px)
- **Shell Type:** `mobile_tab` (State testing studio showing modal over live queue background)

### 1. Visual Hierarchy & Exact Visible Components

1. **Top Scenario Selector Toolbar:**
   - Pill container (`bg-surface-container-high rounded-full p-1 flex justify-between shadow-sm`):
     - Button 1: `"Reset Dialog"` (`restart_alt`, 16px text-error) — Active state.
     - Button 2: `"Feedback"` (`notifications_active`, 16px text-primary).
     - Button 3: `"Staff Audit"` (`badge`, 16px text-secondary).

2. **Dashboard Underlay Foundation (Dimmed / Under Modal):**
   - Doctor Card: Dr. Rajesh Sharma (`RS` avatar in `secondary-fixed`), room 04, status pill `"Available"`.
   - Today's Token Tally Card: Parchi live count `"12"` + trend indicator `"+3 / hr"` + `"Issue Next (13)"` primary button + `"Reset Tally"` secondary button + last parchi timestamp (`10:38 AM #012`).
   - In Waiting Area Queue Preview (3 patients):
     - Patient 1: `#10` Meera Patel ("Follow-up BP Check • Dr. Rajesh", badge "With Doctor").
     - Patient 2: `#11` Harshavardhan Rao ("General Viral Consult • Waiting 8m", badge "Next Up").

3. **Active Reset Confirmation Dialog (`#reset-modal-backdrop`):**
   - Centered dialog container (`w-full max-w-sm bg-surface-container-lowest rounded-3xl p-6 shadow-2xl animate-in zoom-in-95`):
     - Icon Container: 56x56 (`w-14 h-14`) rounded-2xl red container (`bg-error-container/60 text-error`) with `restart_alt` icon (32px).
     - Heading (H2): `"Reset today’s count?"` in `headline-md` font-bold (`#0d1c2e`).
     - Body: `"This will reset the parchi tally for Apex Care Polyclinic back to 0."`
     - Token Chip: Pill badge in `error-container` with `confirmation_number` icon + `"12 issued today"`.
     - Action Buttons:
       - Primary: `"Confirm Reset to 0"` in 52px height button (`bg-error text-on-error rounded-2xl shadow-md`) with `check_circle` icon.
       - Secondary: `"Cancel"` in 48px height button (`bg-surface-container-high text-on-surface rounded-2xl`).

4. **Account & Audit Bottom Drawer (`#account-drawer-backdrop`):**
   - Slide-up bottom sheet container (`rounded-t-3xl bg-surface-container-lowest p-6 shadow-2xl`):
     - Drawer drag handle (`w-12 h-1.5 rounded-full bg-surface-variant mx-auto`).
     - Staff Identity Header: Shield person icon (`shield_person`, 32px), title `"Front Desk Lead"`, status pill `"Active"`, email `reception.apex@easycheck.med`, assigned clinic `"Apex Care Polyclinic"`.
     - Audit Metadata Section:
       - Session Auth Protocol: `"Google OAuth 2.0"` with verified badge.
       - Daily Reset Permissions: `"Granted (Lead Tier)"` in emerald bold.
       - Last Audit Checkpoint: `"Today, 08:30 AM IST"`.
     - Quick Action Cards:
       - Card 1: `"Audit Activity"` (`receipt_long`, "View 18 shift actions").
       - Card 2: `"Reprint Slip"` (`print`, "Bluetooth Desk Printer").
     - Exit Actions: Red button `"Log out of Apex Terminal"` (56px) + text button `"Close Panel"`.

5. **Fixed Bottom Navigation Bar:**
   - 4 Tabs identical to Admin Dashboard, with **Clinic** (`manage_accounts`) active.

### 2. Navigation & User Interactions

- **Toolbar Buttons:** Switch visibility between Reset Dialog (`openModal()`), Feedback Toasts (`triggerToasts()`), and Staff Audit Drawer (`openDrawer()`).
- **Confirm Reset:** Clears token count to 0, closes modal, and injects audit confirmation banner.

### 3. Asset & Resource References

- **Staff Photo / Logos:** Same as Admin Dashboard.
- **Icons:** `restart_alt`, `notifications_active`, `badge`, `trending_up`, `add_circle`, `history`, `shield_person`, `verified_user`, `receipt_long`, `print`, `logout`.

---

## Screen 4: Unauthorized Security State Screen

- **Folder Path:** `unauthorized_security_states/`
- **Source Code:** `unauthorized_security_states/code.html`
- **Visual Reference:** `unauthorized_security_states/screen.png` (487 x 1105 px)
- **Shell Type:** `mobile_stack` (Fixed top app bar with back navigation button, no bottom tab bar)

### 1. Visual Hierarchy & Exact Visible Components

1. **Fixed Top App Bar (Header):**
   - Height 64px (`h-16`), fixed at top with safe-area padding (`pt-safe`), background `surface/90` with `backdrop-blur-xl`.
   - Left Cluster:
     - Back Button: Circular button with `arrow_back` icon (24px `#0d1c2e`), invoking `history.back()`.
     - EasyCheck Admin Logo (28px height).
     - Title: `"Patient Triage Detail"` in `headline-sm` (`16px`, Plus Jakarta Sans, `#0d1c2e`). *(Note: Prototype title anomaly; represents triage security context).*
   - Right Cluster:
     - Profile Avatar Button: 32x32 rounded-full avatar (`Reception Apex`).

2. **Top Portal Badge Strip:**
   - Left: Portal pill with red pulsing dot (`bg-error animate-pulse`) + `"CLINIC ADMIN PORTAL"` in `label-sm` uppercase.
   - Right: EasyCheck logo + `"EasyCheck"` brand title in `headline-sm` bold (`#375e9d`).

3. **Access Denied Security Card:**
   - Card Container: `bg-surface-container-lowest rounded-2xl p-6 shadow-md relative overflow-hidden text-center`.
   - Ambient Glow: `-right-10 -top-10 w-36 h-36 bg-surface-container-low rounded-full opacity-60`.
   - Shield Lock Icon: 64x64 rounded-2xl container (`bg-surface-container-low`) housing a 48x48 inner container with filled `shield_lock` icon (30px `#375e9d`).
   - Permissions Required Pill: `bg-error-container text-on-error-container` with `lock` icon (14px) + `"PERMISSIONS REQUIRED"`.
   - Main Headline (H2): `"Access Not Authorized"` in `headline-lg-mobile` (`22px`, Plus Jakarta Sans bold, `#375e9d`).
   - Body Explanation: `"Your Google account dr.guest@gmail.com was successfully authenticated, but has not been assigned as an authorized administrator for any clinic."` in `body-md` (`#535f59`).

4. **Action Buttons Section:**
   - Primary Action Button: Height 56px (`h-14`) rounded-2xl filled button (`bg-primary text-on-primary shadow-md active:scale-[0.98]`):
     - Icon: `switch_account` (20px).
     - Label: `"Switch Google Account"` in `headline-sm`.
     - JS Action: `handleSwitchAccount()`.
   - Secondary Action Button: Height 48px (`h-12`) rounded-2xl button (`bg-surface-container-highest text-secondary active:scale-[0.98]`):
     - Icon: `contact_support` (18px).
     - Label: `"Request Clinic Access"` in `headline-sm`.
     - JS Action: `handleRequestAccess()`.

5. **Transient Floating Re-authentication Toast (`#toastNotification`):**
   - Fixed bottom-6 pill (`bg-inverse-surface text-inverse-on-surface p-2 rounded-xl shadow-lg flex justify-between`):
     - Left: Sync icon (`sync`, 20px) + message `"Re-authenticating permissions..."`.
     - Right: Status code badge `"200 OK"` in monospace font.

### 2. Navigation & User Interactions

- **Back Button:** Executes `history.back()`.
- **Switch Google Account:** Displays redirecting toast and reloads authentication view.
- **Request Clinic Access:** Dispatches administrative ticket `#REQ-883` and reveals toast confirmation.

### 3. Asset & Resource References

- **Logo Image:** EasyCheck Admin logo mark.
- **Staff Avatar:** Reception Apex avatar photo.
- **Icons:** `arrow_back`, `shield_lock`, `lock`, `switch_account`, `contact_support`, `sync`.
