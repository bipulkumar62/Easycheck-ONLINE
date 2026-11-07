# Screenshot Checklist: EasyCheck Online

**Phase:** Phase 01 — Stitch Design Analysis  
**Project:** EasyCheck Online  
**Coverage:** 7 Discovered Screens (3 Patient + 4 Admin)  

This checklist acts as the acceptance criteria for pixel-perfect Flutter UI implementation. Every entry corresponds to an original Stitch screen reference.

---

## 1. Patient Screens

### Screen P-01: Patient Google Login
- **Reference Screenshot:** `stitch_easycheck_clinic_mobile_ui/stitch_easycheck_clinic_mobile_ui/google_login_easycheck_online/screen.png`
- **Resolution:** 780 x 1768 px
- **Flutter Target:** `PatientLoginView`

#### Mandatory Visual Components Checklist:
- [ ] **Background:** Full-bleed medical clinic photograph with vertical gradient overlay (`surface/90` to `surface-container-low/95`) and soft 2px backdrop blur.
- [ ] **Ambient Glows:** Soft emerald radial micro-glow top-right (`w-80 h-80 blur-3xl`) and slate/blue micro-glow bottom-left (`w-72 h-72 blur-2xl`).
- [ ] **Live Sync Chip:** Pill badge with animated green ping dot (`animate-ping`) and uppercase text `"LIVE CLINIC DESKS ACTIVE"`.
- [ ] **Brand Mark:** 56x56 rounded-2xl white card housing EasyCheck Online logo.
- [ ] **Brand Wordmark:** Navy `"EasyCheck"` (`#002553`) and Emerald `"Online"` (`#006d44`) with subtitle `"OFFICIAL PATIENT PORTAL"`.
- [ ] **Value Card (Level 1 Elevation):** Rounded-2xl translucent white container (`bg-surface-container-lowest/80 backdrop-blur-md`) with subtle shadow.
- [ ] **Card Copy:** Verified badge with `"Real-time OPD & Parchi Tracker"`, H1 `"Your doctor, closer than ever."`, and descriptive body copy.
- [ ] **Social Proof Strip:** 3 overlapping colored avatar circles (`DR`, `RN`, `OP`), text `"Trusted by 140+ clinics"`, and timer badge `"Instant Access"`.
- [ ] **Google Sign-In Button:** 48px height rounded-2xl white button, multi-color Google SVG icon, text `"Continue with Google"` in 14px semi-bold.
- [ ] **Security Badge:** Lock icon with `"HIPAA-aligned • Encrypted health records"`.
- [ ] **Legal Links:** Centered `"Privacy Policy"` and `"Terms of Service"` separated by dot divider.

---

### Screen P-02: Patient Home / Clinic Discovery
- **Reference Screenshot:** `stitch_easycheck_clinic_mobile_ui/stitch_easycheck_clinic_mobile_ui/home_easycheck_online/screen.png`
- **Resolution:** 780 x 1956 px
- **Flutter Target:** `PatientHomeView`

#### Mandatory Visual Components Checklist:
- [ ] **Fixed Top App Bar:** 64px height with `pt-safe`, frosted blur effect (`backdrop-blur-xl`), EasyCheck logo, title column `"EasyCheck / Home"`, notification bell icon button, and generic user avatar circle (`person`).
- [ ] **Location Picker Chip:** Rounded-full pill with filled pin icon (`location_on`), bold text `"Lahore, Punjab"`, and dropdown arrow (`keyboard_arrow_down`).
- [ ] **Live Status Pill:** Green pulsing dot with bold text `"Live Queue"`.
- [ ] **Search Bar:** 48px height rounded-xl search field, search icon (`search`), placeholder `"Search hospital or doctor"`, instant client-side filtering.
- [ ] **Section Header:** Title `"Registered Clinics"` with `"3 Active"` pill badge and right-aligned `"Live Sync"` indicator.
- [ ] **Clinic Card 1 (Al-Shifa Family Health Clinic):**
  - [ ] Clinic name in `headline-sm` bold navy (`#002553`).
  - [ ] Doctor name `"Dr. Rajesh Kumar, MD"`, specialty in emerald `"Consultant Cardiologist & General Physician"`, address with `near_me` pin.
  - [ ] 72x72 rounded-xl photo of Dr. Rajesh Kumar with green online status pip on bottom-right.
  - [ ] Status pill: Green dot + `"Available"`.
  - [ ] Today's Parchi badge: Emerald container pill with `confirmation_number` + `"Today’s Parchi: 42"`.
- [ ] **Clinic Card 2 (Crescent Memorial Hospital):**
  - [ ] Clinic name, Dr. Fatima Zahra, specialty `"Pediatric Specialist"`, address.
  - [ ] 72x72 rounded-xl photo of Dr. Fatima Zahra with green online status pip.
  - [ ] Status pill: Green dot + `"Available"`.
  - [ ] Today's Parchi badge: Emerald container pill with `"Today’s Parchi: 28"`.
- [ ] **Clinic Card 3 (St. Jude Community Medicare - Offline):**
  - [ ] Clinic name, Dr. Tariq Mahmood, specialty `"Orthopedic Consultant"`, address.
  - [ ] 72x72 rounded-xl photo of Dr. Tariq Mahmood in 30% grayscale with gray offline status pip.
  - [ ] Status pill: Gray dot + `"Unavailable"`.
  - [ ] Today's Parchi badge: Gray container pill with `event_busy` + `"Today’s Parchi: Closed for session"`.
- [ ] **AdMob Banner Slot:** Reserved 320x50 container with `ad_units` icon and `"Google AdMob (320x50 SDK Container)"` text.
- [ ] **Bottom Navigation Bar:** 64px height frosted bar with 3 tabs: `"Home"` (active with pill background), `"My Clinics"` (`local_hospital`), and `"Settings"` (`settings`).

---

### Screen P-03: Patient Clinic Details
- **Reference Screenshot:** `stitch_easycheck_clinic_mobile_ui/stitch_easycheck_clinic_mobile_ui/clinic_details_easycheck_online/screen.png`
- **Resolution:** 780 x 2394 px
- **Flutter Target:** `PatientClinicDetailsView`

#### Mandatory Visual Components Checklist:
- [ ] **Fixed Top App Bar:** 64px height with back arrow (`arrow_back`), EasyCheck logo, title `"Clinic Details"`, and user avatar.
- [ ] **Doctor & Clinic Profile Card:**
  - [ ] 96x96 rounded-2xl photo of Dr. Rajesh Kumar with verified badge circle (`verified`).
  - [ ] Tag `"VERIFIED CLINIC PROFILE"` in emerald uppercase.
  - [ ] Live pulsing pill: Animated ping dot + `"Currently Available"`.
  - [ ] Doctor Name: `"Dr. Rajesh Kumar, MD"` in `headline-sm` navy.
  - [ ] Clinic Block: Hospital icon (`local_hospital`) + `"Al-Shifa Family Health Clinic"` + full address in Lahore.
- [ ] **Live Parchi Counter Card:**
  - [ ] Header: `receipt_long` icon + title `"Today’s Parchi Count"`.
  - [ ] Simulation Chip: `sync` icon + `"Simulate Syncing"` interactive button.
  - [ ] Big Metric Box: 32px bold number `"42"`, verified reception chip (`verified_user`), and sync subtitle with animated green ping dot.
  - [ ] Comparison Grid (2 columns): Yesterday box (`"38 slips"`) vs Today box (`"42 slips"` in emerald).
  - [ ] Backend Sync Footer: `cloud_done` icon + `"Count synced directly with reception desk backend"`.
- [ ] **Planning Your Visit Card:** Lightbulb icon (`lightbulb`) with comforting editorial copy.
- [ ] **Off-Hours / Doctor Leave Card:** Info icon (`info`), title, `"Standard Protocol"` chip, and sample offline state row.

---

## 2. Admin Screens

### Screen A-01: Admin Google Authentication
- **Reference Screenshot:** `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/google_authentication/screen.png`
- **Resolution:** 487 x 1105 px
- **Flutter Target:** `AdminLoginView`

#### Mandatory Visual Components Checklist:
- [ ] **Ambient Background:** Off-white canvas with radial blurred orbs (top emerald orb, right blue orb).
- [ ] **Brand Center Stack:**
  - [ ] 64x64 rounded-xl white container with EasyCheck Admin square logo and green verified checkmark badge.
  - [ ] Subtitle `"EASYCHECK ONLINE"` in uppercase navy tracking-widest.
  - [ ] Headline H1: `"Clinic Admin"` in 28px Plus Jakarta Sans bold.
  - [ ] Subtext: `"Sign in to manage your clinic."`
- [ ] **Authentication Card:**
  - [ ] 56px height white button with shadow, Google 4-color SVG icon, and text `"Continue with Google"`.
  - [ ] OAuth Loading Overlay: Animated spinner with text `"Authenticating OAuth..."`.
  - [ ] Disclaimer: `"Authorized clinic staff access only."`
- [ ] **Dynamic Banner Container (`#status-card`):**
  - [ ] Identity Verified State: Green circle `check_circle`, `"IDENTITY VERIFIED"`, `"Dr. Sarah Jenkins"`, `"Lead Triage • Station 4 Ready"`, spinner.
  - [ ] Access Restricted State: Red circle `gpp_bad`, `"ACCESS RESTRICTED"`, `"Unassigned Account"`, and role elevation link.
- [ ] **Helpdesk Modal Dialog:** Access provisioning info, LDAP/Azure AD disclaimer, support phone ext `4092`, email `admin-it@metrohealth.net`, and dismiss button.

---

### Screen A-02: Clinic Admin Dashboard
- **Reference Screenshot:** `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/clinic_admin_dashboard/screen.png`
- **Resolution:** 487 x 1105 px
- **Flutter Target:** `AdminDashboardView`

#### Mandatory Visual Components Checklist:
- [ ] **Fixed Top App Bar:** 64px height with EasyCheck Admin logo, title column `"Clinic Admin • EasyCheck Admin"` and `"Apex Care Polyclinic"`, and staff avatar circle.
- [ ] **Operational Context Card:** Clinic name in Plus Jakarta Sans bold, subtitle `"Desk Registration & Doctor Status"`, and staff avatar button with green online badge.
- [ ] **Staff Account Popover:** Floating menu with staff photo, email `reception.apex@easycheck.med`, Clinic ID `CLN-84920`, and red `"Log out session"` button.
- [ ] **Doctor Availability Card:**
  - [ ] Doctor info: Stethoscope icon, `"Dr. Rajesh Sharma, MD"`, `"Internal Medicine • Room 104 Consultation"`, and `"Online"` status pill.
  - [ ] 3 Status Selector Buttons:
    - [ ] `"Available"`: Ring-2 green border (`ring-primary`), `check_circle`, active fill.
    - [ ] `"Delayed"`: Neutral fill, `schedule` icon.
    - [ ] `"Off-Duty"`: Neutral fill, `block` icon.
- [ ] **Main Parchi Counter Card:**
  - [ ] Title `"Today’s Parchi Count"`, date `"Wednesday, October 24"`, sequence badge `Seq: P-012`.
  - [ ] Decrement Button (`-`): 64x64 white circular button with `remove` icon. Disables at 0.
  - [ ] Giant Counter Display: 68px Plus Jakarta Sans bold tabular numbers (`12`), scale animation on change, and animated `"PARCHI ISSUED"` label.
  - [ ] Increment Button (`+`): 64x64 emerald circular button with `add` icon, shadow, and ring-4 glow.
  - [ ] Reset Link: Red text button with `restart_alt` icon + `"Reset count to 0"`.
- [ ] **Reset Confirmation Modal:** Warning dialog with red icon, explanation of permanent clinic audit ledger, `"Cancel"`, and `"Confirm Reset"` buttons.
- [ ] **Logout Confirmation Modal:** Logout dialog with red icon, session shift copy, `"Stay signed in"`, and `"Log out of Reception"` buttons.
- [ ] **Transient Toast Notification:** Floating top pill with `check_circle` icon and text `"Saved to Firebase • Updated just now"`.
- [ ] **Bottom Navigation Bar:** 64px height frosted bar with 4 tabs: `"Live Queue"` (active in green), `"Intake"`, `"Staff"`, and `"Clinic"`.

---

### Screen A-03: Reset Confirmation & Account State Studio
- **Reference Screenshot:** `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/reset_confirmation_account_state/screen.png`
- **Resolution:** 487 x 1105 px
- **Flutter Target:** `AdminResetStudioView` / Modal & Drawer state validation

#### Mandatory Visual Components Checklist:
- [ ] **Scenario Selector Toolbar:** Pill bar with 3 tabs: `"Reset Dialog"`, `"Feedback"`, and `"Staff Audit"`.
- [ ] **Live Dashboard Underlay:** Dimmed foundation displaying Dr. Rajesh Sharma, live parchi count `"12"`, and waiting queue preview (Meera Patel with doctor, Harshavardhan Rao next up).
- [ ] **Active Reset Modal:** Centered dialog with 56x56 red icon container (`restart_alt`), heading `"Reset today’s count?"`, clinic name, `"12 issued today"` chip, 52px red `"Confirm Reset to 0"` button, and 48px `"Cancel"` button.
- [ ] **Staff Audit Bottom Drawer:** Slide-up sheet with drag handle, Front Desk Lead identity, email, assigned clinic, Google OAuth 2.0 verification, Daily Reset Permissions granted status, Last Audit Checkpoint (`08:30 AM IST`), quick action buttons (`Audit Activity`, `Reprint Slip`), and logout button.
- [ ] **Bottom Navigation Bar:** 4 tabs matching Admin Dashboard, with `"Clinic"` tab active.

---

### Screen A-04: Unauthorized Security State Screen
- **Reference Screenshot:** `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/unauthorized_security_states/screen.png`
- **Resolution:** 487 x 1105 px
- **Flutter Target:** `AdminUnauthorizedView`

#### Mandatory Visual Components Checklist:
- [ ] **Fixed Top App Bar:** 64px height with back arrow (`arrow_back`), EasyCheck Admin logo, title `"Patient Triage Detail"`, and staff avatar.
- [ ] **Portal Badge Strip:** Red pulsing dot with `"CLINIC ADMIN PORTAL"` and right-aligned EasyCheck logo.
- [ ] **Access Denied Card:**
  - [ ] 64x64 rounded-2xl container housing 48x48 navy lock container with filled `shield_lock` icon.
  - [ ] Red pill badge: `lock` icon + `"PERMISSIONS REQUIRED"`.
  - [ ] Heading H2: `"Access Not Authorized"` in 22px bold navy.
  - [ ] Body copy explicitly stating unassigned Google account: `dr.guest@gmail.com`.
- [ ] **Action Buttons:**
  - [ ] Primary Button: 56px height emerald button with `switch_account` icon + `"Switch Google Account"`.
  - [ ] Secondary Button: 48px height surface-highest button with `contact_support` icon + `"Request Clinic Access"`.
- [ ] **Transient Feedback Toast:** Floating bottom-6 pill with sync icon, `"Re-authenticating permissions..."`, and status code `"200 OK"`.
