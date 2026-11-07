# Patient Screen Map: EasyCheck Online

**Design System:** Clinical Clarity  
**Source Directory:** `stitch_easycheck_clinic_mobile_ui/stitch_easycheck_clinic_mobile_ui/`  
**Total Screens:** 3 Screens  

---

## Screen 1: Google Login Screen

- **Folder Path:** `google_login_easycheck_online/`
- **Source Code:** `google_login_easycheck_online/code.html`
- **Visual Reference:** `google_login_easycheck_online/screen.png` (780 x 1768 px)
- **Shell Type:** `mobile_blank` (Full viewport, no top app bar, no bottom navigation)

### 1. Visual Hierarchy & Exact Visible Components

1. **Background Layer:**
   - Full-bleed background photograph showing a bright medical clinic environment with patient consultation.
   - Reassuring soft glass gradient overlay: Vertical gradient from `surface/90` (`#f8f9ff` at 90%) through `surface/85` to `surface-container-low/95` (`#eff4ff` at 95%) with `backdrop-blur-[2px]`.
   - Ambient micro-glow orbs:
     - Top-right orb: `w-80 h-80 rounded-full bg-secondary-container/20 blur-3xl`.
     - Bottom-left orb: `w-72 h-72 rounded-full bg-surface-container-highest/40 blur-2xl`.

2. **Top Header Area (Brand & Status):**
   - Live Sync Status Chip: Pill badge (`rounded-full bg-surface-container-lowest/90 px-3 py-1.5 shadow-sm backdrop-blur-md`). Contains a live pulsing emerald ping indicator (2x2 animated ping circle + solid emerald circle `#006d44`) and uppercase label `"LIVE CLINIC DESKS ACTIVE"` in `label-sm` (`11px`, font-weight 600, tracking 0.03em).
   - Brand Icon Container: `w-14 h-14 rounded-2xl bg-surface-container-lowest p-2 shadow-sm` housing the EasyCheck Online logo.
   - Brand Wordmark: Two-tone typography: `"EasyCheck"` in `headline-sm` bold (`#002553`), followed by `"Online"` in `headline-sm` semi-bold (`#006d44`).
   - Subtitle: `"OFFICIAL PATIENT PORTAL"` in uppercase `label-sm` (`#434750` with 80% opacity).

3. **Center-Bottom Card (Value Proposition - Elevation Level 1):**
   - Card Container: `bg-surface-container-lowest/80 backdrop-blur-md rounded-2xl p-4 shadow-sm`.
   - Feature Header: Verified icon (`verified`, 18px emerald) + text `"Real-time OPD & Parchi Tracker"` in `label-md` (`12px`, font-weight 500, `#006d44`).
   - Main Heading (H1): `"Your doctor, closer than ever."` in `headline-lg` (`26px`, line-height 34px, font-weight 700, `#073b78`).
   - Body Description: `"Check your clinic’s availability and live parchi updates in one calm, unified place."` in `body-md` (`14px`, `#434750`).
   - Social Proof Micro-Strip:
     - Avatar Initials Stack: Overlapping 24x24 avatar circles (`DR` in `#d7e3ff`, `RN` in `#dce9ff`, `OP` in `#80fab9`).
     - Clinic Trust Count: `"Trusted by 140+ clinics"` in `label-sm` (`#434750`).
     - Access Tag: Timer icon (`timer`, 15px) + `"Instant Access"` in `label-sm` semi-bold (`#006d44`).

4. **Bottom Action & Assurance Zone:**
   - Primary Action Button (`#googleLoginBtn`): Full-width 48px height (`h-12`) pill button (`rounded-2xl bg-surface-container-lowest shadow-sm hover:shadow-md`).
     - Google Official Multi-color 4-color SVG Icon (20x20).
     - Text: `"Continue with Google"` in `label-lg` (`14px`, font-weight 600, `#0b1c30`).
   - Security Micro-Badge: Lock icon (`lock`, 15px emerald) + text `"HIPAA-aligned • Encrypted health records"` in `label-sm` (`#434750`).
   - Legal Footer Links: Centered horizontal link pair separated by a dot divider (`w-1 h-1 rounded-full bg-outline-variant`):
     - Link 1: `"Privacy Policy"` (`href="#privacy"`).
     - Link 2: `"Terms of Service"` (`href="#terms"`).

### 2. Navigation & User Interactions

- **Button Tap Feedback:** Tapping the Google Sign-in button triggers an opacity shift to `0.85` for 180ms before restoring to `1.0`.
- **Destination:** On authentication success, transitions to the Home / Discovery screen (`home_easycheck_online/`).
- **Footer Links:** Opens respective privacy policy and terms web views or modals.

### 3. Asset & Resource References

- **Logo Image:** `https://lh3.googleusercontent.com/aida/AEtjO1WVmNW9QbQpLrhtE6HOF13318Wx2ICVaLaZ0DnaqTAbSVPQ4QBmZqDMVw01L5cqMDVRU_Bdni3hOxxmEU5vP2jJUAIANswcBgrpocSbdnTB3isNerhQzWCscZyCrMjcbVthDDmrhqIj0kFhdmTu3US0U3sspFlPvWrhSw0ZeUpPy0eLAMjYpcZUP2DPFdKq-nTreKO61VzX58k_jxfYJzQWiKw-2JRknBLIWT_bZtQ`
- **Background Image:** `https://lh3.googleusercontent.com/aida-public/AB6AXuB6QM4rhOgjYoHEDGnJKpPCrK69_E-20Z7kWXeLUm4RcVV6xb1sM7jEB8qDjefbi2ZU5eBqUnZUK8GfFu1CRXsnLtNMbLvKCk3xZ4FGIFF15yHDhouoRbUf0o7XiHvs2pCoJA4fBUNoxmZzZbEtZEQ2JZK_mufaT_putKXJip40qee0dJLMzu8IZ_Xl2rGApWcSDHVLwAOSiwPRUUy98gc2PhD3TTwCiszf7rYMhg`
- **Icons:** `verified`, `timer`, `lock`.
- **Fonts:** Inter (400, 500, 600, 700).

---

## Screen 2: Home / Clinic Discovery Screen

- **Folder Path:** `home_easycheck_online/`
- **Source Code:** `home_easycheck_online/code.html`
- **Visual Reference:** `home_easycheck_online/screen.png` (780 x 1956 px)
- **Shell Type:** `mobile_tab` (Fixed blurred top app bar + fixed blurred bottom tab navigation)

### 1. Visual Hierarchy & Exact Visible Components

1. **Fixed Top App Bar (Header):**
   - Height 64px (`h-16`), fixed at top with safe-area padding (`pt-safe`), background `surface/80` with `backdrop-blur-xl`, subtle shadow `0 1px 8px rgba(7,59,120,0.04)`.
   - Left Cluster:
     - EasyCheck Online Logo (height 32px / `h-8`).
     - Text Column: Uppercase brand mark `"EasyCheck"` in `label-sm` (`#006d44`) above screen title `"Home"` in `title-md` (`16px`, font-weight 600, `#002553`).
   - Right Cluster:
     - Notification Button: 44x44 circular button with `notifications` icon (22px).
     - User Avatar: 32x32 circle filled with `#002553` containing white `person` icon (18px).

2. **Location & Search Section:**
   - Location Selector Pill: Interactive chip (`px-2 py-1 rounded-full bg-surface-container-low`):
     - Pin Icon (`location_on`, filled, 18px `#002553`).
     - Location Text: `"Lahore, Punjab"` in `label-lg` (`14px`, font-weight 600, `#002553`).
     - Dropdown Caret: `keyboard_arrow_down` (18px).
   - Live Status Pill: Right-aligned pill (`bg-surface-container-lowest shadow-sm`) with green pulsing dot and `"Live Queue"` label (`#006d44`).
   - Search Input Bar: 48px height (`h-12`) rounded container (`rounded-xl bg-surface-container-lowest shadow-sm`):
     - Search Icon (`search`, 20px `#737781`).
     - Input Field (`#clinic-search`): Placeholder `"Search hospital or doctor"` in `body-md` (`14px`).

3. **Section Header:**
   - Left: Title `"Registered Clinics"` in `title-md` (`#002553`) + Pill count `"3 Active"` in `surface-container`.
   - Right: Label `"Live Sync"` in `label-sm` (`#737781`).

4. **Clinic Cards Feed (3 Prototype Clinics):**

   - **Card 1: Al-Shifa Family Health Clinic**
     - Container: `rounded-2xl bg-surface-container-lowest p-4 shadow-sm hover:shadow-md`.
     - Left Column:
       - Clinic Name: `"Al-Shifa Family Health Clinic"` in `headline-sm` (`18px`, font-weight 600, `#002553`).
       - Doctor Name: `"Dr. Rajesh Kumar, MD"` in `body-md` font-semibold (`#0b1c30`).
       - Doctor Specialty: `"Consultant Cardiologist & General Physician"` in `label-md` (`#006d44`).
       - Address: Navigation pin (`near_me`, 15px) + `"Suite 402, Medical City Blvd, Near Civic Center"` in `body-sm` (`13px`, `#434750`).
     - Right Column:
       - Doctor Photo: 72x72 rounded-xl portrait (`Dr. Rajesh Kumar`) with 14x14 green online status pip on the bottom-right corner.
     - Footer Row:
       - Availability Pill: Green dot + `"Available"` in `label-sm` font-semibold (`#006d44`, background `surface-container-low`).
       - Live Parchi Badge: Pill in `secondary-container` (`#7df7b6`) with `confirmation_number` icon + text `"Today’s Parchi: 42"` in `label-md` font-semibold (`#007147`).

   - **Card 2: Crescent Memorial Hospital**
     - Left Column:
       - Clinic Name: `"Crescent Memorial Hospital"` in `headline-sm` (`#002553`).
       - Doctor Name: `"Dr. Fatima Zahra, MBBS, FCPS"` in `body-md` font-semibold (`#0b1c30`).
       - Doctor Specialty: `"Pediatric Specialist"` in `label-md` (`#006d44`).
       - Address: Navigation pin (`near_me`) + `"72 Gulberg Road, Block B, Main Market"`.
     - Right Column:
       - Doctor Photo: 72x72 rounded-xl portrait (`Dr. Fatima Zahra`) with green online status pip.
     - Footer Row:
       - Availability Pill: Green dot + `"Available"`.
       - Live Parchi Badge: Secondary container pill with `confirmation_number` + `"Today’s Parchi: 28"`.

   - **Card 3: St. Jude Community Medicare**
     - Left Column:
       - Clinic Name: `"St. Jude Community Medicare"` in `headline-sm` (`#002553`).
       - Doctor Name: `"Dr. Tariq Mahmood, FRCS"` in `body-md` font-semibold.
       - Doctor Specialty: `"Orthopedic Consultant"` in `label-md` (`#737781`).
       - Address: Navigation pin (`near_me`) + `"Plot 18, Commercial Zone, Phase 3"`.
     - Right Column:
       - Doctor Photo: 72x72 rounded-xl portrait (`Dr. Tariq Mahmood`) with 30% grayscale and gray inactive status pip (`#737781`).
     - Footer Row:
       - Unavailable Pill: Gray dot + `"Unavailable"` in `label-sm` (`#434750`, background `surface-container`).
       - Closed Parchi Badge: Pill with `event_busy` icon + text `"Today’s Parchi: Closed for session"` in `label-md` (`#434750`).

5. **Advertisement Slot (Reserved AdMob 320x50 Container):**
   - Centered container (`w-full max-w-[320px] h-[50px] rounded-xl bg-surface-container-low`).
   - Ad icon (`ad_units`, 12px) + label `"ADVERTISEMENT"` (`10px`, uppercase, `#737781`).
   - Subtext: `"Google AdMob (320x50 SDK Container)"` (`9px`, `#737781`).

6. **Fixed Bottom Tab Navigation Bar:**
   - Height 64px (`h-16`), fixed at bottom with `pb-safe`, background `surface/90` with `backdrop-blur-xl`, shadow `0 -2px 12px rgba(7,59,120,0.05)`.
   - 3 Tabs:
     1. **Home (`data-path="home"`):** Icon `home` (24px) + label `"Home"`. Active state styled with `text-secondary` (`#006d44`) and pill background `bg-surface-container-low`.
     2. **My Clinics (`data-path="my-clinics"`):** Icon `local_hospital` (24px) + label `"My Clinics"`.
     3. **Settings (`data-path="settings"`):** Icon `settings` (24px) + label `"Settings"`.

### 2. Navigation & User Interactions

- **Search Filtering:** Typing in `#clinic-search` performs instant client-side case-insensitive substring filtering on `.clinic-item` elements.
- **Card Selection:** Tapping any clinic card navigates to the Clinic Details Screen (`clinic_details_easycheck_online/`).
- **Location Selector:** Interactive dropdown trigger to switch city/region.
- **Tab Switching:** Switches between Home, My Clinics, and Settings tabs.

### 3. Asset & Resource References

- **Logo Image:** `https://lh3.googleusercontent.com/aida/AEtjO1WVmNW9QbQpLrhtE6HOF13318Wx2ICVaLaZ0DnaqTAbSVPQ4QBmZqDMVw01L5cqMDVRU_Bdni3hOxxmEU5vP2jJUAIANswcBgrpocSbdnTB3isNerhQzWCscZyCrMjcbVthDDmrhqIj0kFhdmTu3US0U3sspFlPvWrhSw0ZeUpPy0eLAMjYpcZUP2DPFdKq-nTreKO61VzX58k_jxfYJzQWiKw-2JRknBLIWT_bZtQ`
- **Doctor 1 Portrait (Dr. Rajesh Kumar):** `https://lh3.googleusercontent.com/aida-public/AB6AXuBsE60GLjfIk7jBC_KGtWPMnX56RZCkGJ-Xr3N_L8toVRI3-vszBTzkHOg1tJXYUETFAC96oxILWJMWhMcxTwkKo2sMIp7YIEaiY2rUEOgK7p6nTT_HoCEEbyvB4QDhJyBU_-GNZCr_hiWeaAJOxxJ4a3Ow0V0LGCThbaFnrYuCzTOlY3CadhLvNZvPCLDQTP4sMjWNm3R7gMvY1B6UlEXsDkXP1zlV_IJ28bRABA`
- **Doctor 2 Portrait (Dr. Fatima Zahra):** `https://lh3.googleusercontent.com/aida-public/AB6AXuBzxtZLIaK6FGJ0R_THaZvY_3ijkrRXbo9hbnaYDLh6Ip9rZ6FhvLW-GqJ8C9F5YsubBoSdbN18XDojMmHXCYfGtcDMokI-yYO4clQFOXVOpbEzPVCabA65E9NzeWN4sDtecx-rHxXSR4WvQfE9aDQpv5UFHW095eYdFWGIOwNsvrO8lT-aQbAGbGT_P4RkDKwDAQtRW19BuTlEON3vi-iDTv03B6plxWBvgzdFvA`
- **Doctor 3 Portrait (Dr. Tariq Mahmood):** `https://lh3.googleusercontent.com/aida-public/AB6AXuC9ZWg64nIx1WMaY2P2LyJln0e5I2Q16AhsXDe0OtI3zP2sDAziim4Aks9P3uAjdiV1PPQ0n6EnwAp2ZZYG2zePs0w4xgR7gOd2_-p8ImfyMAm0qf3maEtzcSwK6-FD6z4DH_TMYZX1nYLRbGjAErhILVesMVeLPBsNi0GvR-KzY_8yaWDoCR-xxjX7IrKUBVFF3lqune_UKrkh7V5RpLK_kq6D9OWJhq4To9X7Dw`
- **Icons:** `notifications`, `person`, `location_on`, `keyboard_arrow_down`, `search`, `near_me`, `confirmation_number`, `event_busy`, `ad_units`, `home`, `local_hospital`, `settings`.

---

## Screen 3: Clinic Details & Live Parchi Screen

- **Folder Path:** `clinic_details_easycheck_online/`
- **Source Code:** `clinic_details_easycheck_online/code.html`
- **Visual Reference:** `clinic_details_easycheck_online/screen.png` (780 x 2394 px)
- **Shell Type:** `mobile_stack` (Fixed top app bar with back navigation button, no bottom tab bar)

### 1. Visual Hierarchy & Exact Visible Components

1. **Fixed Top App Bar (Header):**
   - Height 64px (`h-16`), fixed at top with safe-area padding (`pt-safe`), background `surface/80` with `backdrop-blur-xl`.
   - Left Cluster:
     - Back Button: Circular button (`w-11 h-11`) with `arrow_back` icon (24px `#002553`), invoking `history.back()`.
     - EasyCheck Logo: 32px height.
     - Title: `"Clinic Details"` in `title-md` (`16px`, font-weight 600, `#002553`).
   - Right Cluster:
     - User Avatar: 32x32 circle filled with `#002553` containing white `person` icon.

2. **Doctor & Clinic Header Card:**
   - Card Container: `bg-surface-container-lowest rounded-xl shadow-md p-4 relative overflow-hidden`.
   - Doctor Photo: 96x96 (`w-24 h-24 sm:w-28 sm:h-28`) rounded-2xl portrait of Dr. Rajesh Kumar with verified badge circle (`w-6 h-6 rounded-full bg-secondary-container`) containing filled `verified` icon (14px).
   - Doctor & Clinic Metadata:
     - Header tag: `"VERIFIED CLINIC PROFILE"` in `label-sm` (`#006d44`).
     - Availability Pill: Live pulsing emerald ping dot + `"Currently Available"` in `label-md` semi-bold (`bg-secondary-container text-on-secondary-container`).
     - Doctor Name (H2): `"Dr. Rajesh Kumar, MD"` in `headline-sm` (`18px`, font-weight 600, `#002553`).
     - Subtitle: `"Consultant Cardiologist & General Physician"` in `body-sm` (`13px`, `#434750`).
     - Clinic Section: Hospital icon (`local_hospital`, 18px filled `#002553`) + Clinic Name `"Al-Shifa Family Health Clinic"` in `title-md` bold + full address: `"Suite 402, 4th Floor, Medical City Boulevard, Near Civic Center, Lahore"` in `body-sm` (`#434750`).

3. **Live Parchi Counter Card Section:**
   - Card Container: `bg-surface-container-lowest rounded-xl shadow-md p-4 space-y-4`.
   - Card Header:
     - Icon & Title: Receipt icon (`receipt_long`, 20px) in a rounded container + `"Today’s Parchi Count"` in `title-md` semi-bold.
     - Sync Status Toggle Pill (`#toggle-sync-state`): Interactive chip (`bg-surface-container px-3 py-1 rounded-full`) with `sync` icon (14px) and label `"Simulate Syncing"`.
   - Central Counter Display:
     - Container: `bg-surface-container-low rounded-xl py-4 px-4 text-center`.
     - Giant Number Display (`#parchi-count-display`): `"42"` in `display-lg` (`32px`, font-weight 700, `#002553`).
     - Reception Verification Chip: Verified user icon (`verified_user`, 14px) + `"Verified by clinic reception"` in `label-sm` (`bg-surface-container-highest text-primary`).
     - Realtime Ping Subtitle: Animated green ping dot + `"Real-time synchronization connected · Updated 2 mins ago"` in `label-md` (`#434750`).
   - Direct Comparison Section (2 Grid Columns):
     - Yesterday Box: `bg-surface-container-low rounded-lg p-3`. Label `"Yesterday"`, metric `"38 slips"` in `headline-md`, subtext `"Previous day’s verified count"`.
     - Today Box: `bg-secondary-container rounded-lg p-3`. Label `"Today"`, metric `"42 slips"` in `headline-md` font-bold (`#007147`), subtext `"Current day’s verified count"`.
   - Footer Sync Assurance: Cloud check icon (`cloud_done`, 16px `#002553`) + `"Count synced directly with reception desk backend"` in `body-sm`.

4. **"Planning Your Visit" Guidance Card:**
   - Container: `bg-surface-container-low rounded-xl p-4 flex items-start gap-3`.
   - Lightbulb Icon: `w-9 h-9 rounded-full bg-surface-container` with `lightbulb` icon (20px `#002553`).
   - Content: Heading `"Planning Your Visit"` in `title-md` font-semibold (`#002553`), body copy: `"A little more clarity before your visit. Check the latest clinic updates and plan your time with greater confidence."`

5. **Off-Hours & Doctor Leave Notice Card (Informative Preview):**
   - Container: `bg-surface-container-lowest rounded-xl shadow-sm p-4 space-y-3`.
   - Header: Info icon (`info`, 18px) + `"Off-Hours & Doctor Leave Notice"` + Protocol Pill `"Standard Protocol"`.
   - Explanatory Text: `"When clinic session is closed or doctor is unavailable, a calm notice replaces the active count rather than an ambiguous status."`
   - Visual Sample Row: `p-3 bg-surface-container-low rounded-lg flex justify-between`. Offline dot (`#737781`) + `"Session Closed · Offline"` + placeholder metric `"—"`.

### 2. Navigation & User Interactions

- **Back Navigation:** Back button in top app bar executes `history.back()` to return to the Home screen.
- **Sync Simulation Interaction:** Tapping `#toggle-sync-state` toggles between the active count state (`42`) and the syncing/disconnected state (`—` with muted text style).

### 3. Asset & Resource References

- **Logo Image:** Same as Home screen.
- **Doctor Photo:** Dr. Rajesh Kumar portrait (same as Home screen Card 1).
- **Icons:** `arrow_back`, `person`, `verified`, `local_hospital`, `receipt_long`, `sync`, `verified_user`, `cloud_done`, `lightbulb`, `info`.
- **Fonts:** Inter (400, 500, 600, 700).
