# Stitch Design Analysis: EasyCheck Online

**Document Version:** 1.0.0  
**Phase:** Phase 01 — Stitch Design Analysis  
**Project:** EasyCheck Online (Mobile Clinical Ecosystem)  
**Analyzed Folders:**  
- Patient Mobile UI: `stitch_easycheck_clinic_mobile_ui/stitch_easycheck_clinic_mobile_ui/`  
- Admin Mobile UI: `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/`  

---

## 1. Executive Summary

A comprehensive, forensic analysis was conducted on the original Stitch prototypes for the **EasyCheck Online** ecosystem. EasyCheck Online is a dual-interface mobile application designed for outpatient clinics in Pakistan/South Asia (specifically Lahore/Punjab context) to digitize real-time clinic availability and token ("Parchi") queue tracking.

The ecosystem comprises two distinct user experiences:
1. **Patient Mobile Application ("Clinical Clarity"):** A reassuring, high-clarity interface designed for patients and caregivers to discover clinics, view live doctor availability, and monitor live OPD parchi/token progress without physiological stress or cognitive friction.
2. **Clinic Admin Mobile Application ("Clinical Precision"):** A data-dense, ergonomic handheld console designed for clinic receptionists, triage coordinators, and administrative practitioners to toggle real-time doctor statuses, issue/revoke token numbers with large thumb touch-targets, trigger audited daily resets, and manage session authentications.

---

## 2. Design Systems & Architecture

Both applications share a common medical heritage but implement deliberate inversions in primary token roles and typographic treatment to optimize for their distinct user personas.

| Dimension | Patient Experience (`Clinical Clarity`) | Admin Console (`Clinical Precision`) |
| :--- | :--- | :--- |
| **Design Ethos** | Reassuring, calming, empathetic, glanceable | High-velocity, tactile, ergonomic, audit-grade |
| **Shell Types** | `mobile_blank`, `mobile_tab`, `mobile_stack` | `mobile_blank`, `mobile_tab`, `mobile_stack` |
| **Primary Color** | Deep Navy (`#002553` / `#073B78`) | Clinical Emerald (`#006A42` / `#16A36A`) |
| **Secondary Color** | Clinical Emerald (`#006D44` / `#16A36A`) | Deep Authority Navy (`#375E9D` / `#073B78`) |
| **Display Font** | **Inter** (Semi-bold, Bold, 22px–32px) | **Plus Jakarta Sans** (Bold, 20px–36px) |
| **Body & Label Font**| **Inter** (Regular, Medium, Semi-bold) | **Inter** (Regular, Medium, Semi-bold, Bold) |
| **Elevation Style** | Soft ambient diffusion (Navy tinted `rgba(7,59,120,0.03)`) | Translucent borders, hairline rules, soft blur overlays |
| **Bottom Navigation**| 3 Tabs: Home, My Clinics, Settings | 4 Tabs: Live Queue, Intake, Staff, Clinic |
| **Primary Tap Target**| 48px height | 52px – 64px height (thumb sweep calibrated) |

---

## 3. Discovered Screens Catalog

### 3.1 Patient Screens (Total: 3 Screens)
1. **Google Login Screen (`google_login_easycheck_online/`)**
   - **Shell Type:** `mobile_blank`
   - **Purpose:** Secure patient authentication entrypoint.
   - **Key Visual Elements:** Full-bleed ambient clinic photograph background, soft glass gradient overlay, live sync desk active pill, official EasyCheck Online logo mark, value proposition card ("Your doctor, closer than ever"), social proof badges ("Trusted by 140+ clinics"), Google sign-in button, HIPAA/encryption notice, legal links.
2. **Home / Discovery Screen (`home_easycheck_online/`)**
   - **Shell Type:** `mobile_tab`
   - **Purpose:** Primary discovery feed of registered clinics with live availability and parchi count.
   - **Key Visual Elements:** Fixed blurred header, location selector ("Lahore, Punjab"), live queue pulse, search bar with client-side filter, registered clinics list (Al-Shifa Family Health Clinic, Crescent Memorial Hospital, St. Jude Community Medicare), doctor portraits with status pips, today's parchi badge, Google AdMob 320x50 reserved banner slot, fixed 3-tab navigation bar.
3. **Clinic Details Screen (`clinic_details_easycheck_online/`)**
   - **Shell Type:** `mobile_stack`
   - **Purpose:** In-depth real-time queue tracker and clinic status profile for a selected doctor.
   - **Key Visual Elements:** Fixed header with back navigation, verified doctor & clinic profile card, prominent Today's Parchi metric display (42), real-time sync status indicator, yesterday vs today comparison cards, "Planning Your Visit" guidance card, off-hours / doctor leave notice card.

### 3.2 Admin Screens (Total: 4 Screens)
1. **Google Authentication Screen (`google_authentication/`)**
   - **Shell Type:** `mobile_blank`
   - **Purpose:** Restricted staff sign-in for clinic administrators.
   - **Key Visual Elements:** Subtle ambient radial glow orbs, verified EasyCheck admin logo, "Clinic Admin" title, single Google OAuth sign-in button with simulated loader, access restriction disclaimer, dynamic feedback state container (identity verified vs access restricted), access provisioning support modal.
2. **Clinic Admin Dashboard (`clinic_admin_dashboard/`)**
   - **Shell Type:** `mobile_tab`
   - **Purpose:** Primary desk operational console for live parchi issuance and doctor availability control.
   - **Key Visual Elements:** Fixed header with clinic branding and staff avatar, operational clinic card, staff popover menu with clinic ID and logout trigger, doctor availability selector (Available, Delayed, Off-Duty), giant parchi counter with oversized `-` and `+` action buttons, reset counter trigger, reset confirmation modal, logout confirmation modal, transient toast notifications, fixed 4-tab navigation bar.
3. **Reset Confirmation & Account State Studio (`reset_confirmation_account_state/`)**
   - **Shell Type:** `mobile_tab`
   - **Purpose:** Interactive testing and state documentation for dangerous actions (daily tally reset) and staff audit inspection.
   - **Key Visual Elements:** Scenario selector toolbar (Reset Dialog, Feedback, Staff Audit), live dashboard underlay with active waiting queue preview (Meera Patel, Harshavardhan Rao), active centered Reset Confirmation Dialog with audit warning, slide-up Account & Audit bottom drawer with LDAP details and printer actions, non-blocking toast notifications.
4. **Unauthorized Security State Screen (`unauthorized_security_states/`)**
   - **Shell Type:** `mobile_stack`
   - **Purpose:** Zero-trust access denial screen when an authenticated Google account lacks clinic admin authorization.
   - **Key Visual Elements:** Top app bar with back navigation, portal indicator badge, locked shield visual asset, "Access Not Authorized" headline, explicit user account disclaimer (`dr.guest@gmail.com`), "Switch Google Account" primary button, "Request Clinic Access" secondary button, re-authentication feedback toast.

---

## 4. Key Architectural & Paradigm Differences

### 4.1 Color Role Inversion
The most crucial difference between the two interfaces is the color role inversion:
- In the **Patient UI**, **Navy (`#073B78` / `#002553`)** is the primary structural foundation (headers, high-contrast headings, active tabs, buttons). **Emerald (`#16A36A` / `#006D44`)** acts strictly as an accent for positive medical availability, live pulse pips, and confirmed badges.
- In the **Admin UI**, **Emerald (`#006A42` / `#16A36A`)** becomes the primary brand action color (primary buttons, active doctor state, `+` increment button, verified badges). **Navy (`#375E9D` / `#0d1c2e`)** serves as the secondary structural authority for labels, titles, and high-contrast typography.

### 4.2 Typographic Roles
- The **Patient UI** maintains typographic uniformity by using **Inter** across all sizes, maximizing calm legibility for users under stress.
- The **Admin UI** introduces **Plus Jakarta Sans** for large display numbers, headlines, and queue sequences (`P-012`, `12`, `42`). It enforces tabular figures (`font-feature-settings: "tnum"`) so live counter updates do not jitter horizontally on mobile screens.

### 4.3 Navigation Layouts
- **Patient Shell:** Uses a 3-tab layout: `Home` (`home`), `My Clinics` (`local_hospital`), and `Settings` (`settings`).
- **Admin Shell:** Uses a 4-tab layout: `Live Queue` (`format_list_bulleted`), `Intake` (`how_to_reg`), `Staff` (`medical_services`), and `Clinic` (`manage_accounts`).

### 4.4 Interaction Modes
- **Patient:** Passive/Observational. Interactivity is limited to location picking, searching/filtering clinic lists, viewing live updates, and toggling simulation states.
- **Admin:** Active/Operational. High tactile feedback, 64px tap bounds for one-thumb incrementing/decrementing, two-step confirmation modals for destructive resets, popovers for shift termination, and quick status switches.

---

## 5. Existing Prototype Behaviors & Interactions

The original HTML files contain rich prototype JavaScript simulating real-time behaviors. These behaviors must be translated into reactive state logic in Flutter:

1. **Patient Google Login (`google_login_easycheck_online/code.html`):**
   - Tactile button press feedback modifying button opacity for 180ms.
2. **Patient Clinic Search (`home_easycheck_online/code.html`):**
   - Real-time client-side substring search filtering `.clinic-item` DOM nodes by clinic name, doctor name, and specialty.
3. **Patient Sync Simulation (`clinic_details_easycheck_online/code.html`):**
   - Toggle button `#toggle-sync-state` alternating between live count `42` and placeholder `—` to preview offline/syncing states.
4. **Admin Google OAuth Handshake (`google_authentication/code.html`):**
   - Loading spinner overlay on `#btn-google-login` for 1200ms simulating OAuth exchange.
   - Dynamic injection of verified state (`#status-card`) showing identity preview ("Dr. Sarah Jenkins", "Lead Triage").
   - Dynamic injection of denied state ("Unassigned Account") with access request trigger.
   - Access provisioning modal opening and closing.
5. **Admin Parchi Counter (`clinic_admin_dashboard/code.html`):**
   - Increment button: Adds 1 to count, updates `P-xxx` badge, triggers scale-110 animation on number, reveals "Parchi Issued" label, triggers toast notification.
   - Decrement button: Subtracts 1 from count down to min 0 (disables at 0), triggers toast notification.
   - Reset button: Opens modal dialog `#modal-reset`. Confirming resets count to 0.
   - Doctor status group: Switches active styling between "Available", "Delayed", and "Off-Duty", displays "Saving to Firebase...", and shows toast confirmation.
   - Staff account menu: Toggles floating popover `#account-popover` and opens `#modal-logout`.
6. **Admin State Studio (`reset_confirmation_account_state/code.html`):**
   - Scenario bar switching between Reset Dialog modal, Toast notification stack, and slide-up Staff Audit drawer (`#account-drawer-content`).
7. **Unauthorized Security Screen (`unauthorized_security_states/code.html`):**
   - Account switcher trigger, retry connection with spinning icon, and access request ticket toast dispatch (`#REQ-883`).

---

## 6. Prototype Data vs Production Contract

The Stitch prototypes contain embedded sample data that must be identified as prototype data and replaced with clean data models in Flutter:

| Entity | Prototype Sample Value | Production Flutter Model Requirement |
| :--- | :--- | :--- |
| **Location** | `"Lahore, Punjab"` | User selected city/region model |
| **Clinic 1** | `"Al-Shifa Family Health Clinic"`, Dr. Rajesh Kumar, MD, Cardiologist, Today's Parchi: 42, Available | `Clinic` entity with `id`, `name`, `address`, `doctorList`, `status`, `todayParchiCount` |
| **Clinic 2** | `"Crescent Memorial Hospital"`, Dr. Fatima Zahra, MBBS, FCPS, Pediatrician, Today's Parchi: 28, Available | Dynamic Firestore document / API response |
| **Clinic 3** | `"St. Jude Community Medicare"`, Dr. Tariq Mahmood, FRCS, Orthopedic, Today's Parchi: Closed, Unavailable | Clinic status enum (`available`, `delayed`, `unavailable`, `closed`) |
| **Admin Clinic** | `"Apex Care Polyclinic"`, Clinic ID: `CLN-84920`, Dr. Rajesh Sharma, MD | Admin authenticated clinic profile |
| **Admin Staff** | `"Reception Apex"`, `reception.apex@easycheck.med`, Lead Tier | `AdminUser` model with permissions & role |
| **Waitlist Patients**| Meera Patel (BP Check, #10), Harshavardhan Rao (Viral Consult, #11) | Real-time intake queue collection |
| **AdMob Banner** | Hardcoded 320x50 placeholder | Native Google Mobile Ads SDK AdWidget slot |
