# Patient Screen 03 Implementation: Clinic Details & Live Parchi Screen

**Screen Name:** Clinic Details & Live Parchi Screen  
**Source Prototype Directory:** `stitch_easycheck_clinic_mobile_ui/stitch_easycheck_clinic_mobile_ui/clinic_details_easycheck_online/`  
**HTML/CSS Source:** `clinic_details_easycheck_online/code.html`  
**Visual Reference:** `clinic_details_easycheck_online/screen.png` (780 x 2394 px)  
**Shell Type:** `mobile_stack` (Fixed top app bar with back navigation button, no bottom tab bar)  
**Design System:** Clinical Clarity (Patient Mobile UI)

---

## 1. Flutter Files Created or Modified

- `lib/features/clinic/clinic_details_screen.dart` — Core screen implementation matching Stitch HTML/CSS.
- `lib/core/constants/asset_constants.dart` — Asset constants used (`AssetConstants.logoPatient`, `AssetConstants.drRajeshKumar`).
- `lib/shared/models/clinic_model.dart` — Models for Clinic, Doctor, and Consultation Status.
- `lib/shared/widgets/shared_widgets.dart` — Reusable `LivePulseDot` indicator.
- `lib/app/theme/app_colors.dart` — Tokens for Clinical Clarity (`PatientColors`).
- `lib/app/theme/app_typography.dart` — Typography tokens with Inter font family.
- `lib/app/theme/app_spacing.dart` — Radii, elevation, and spacing tokens.
- `lib/app/routes/app_routes.dart` — Route configuration (`/patient/clinic-details`).

---

## 2. Assets Integrated

- **Doctor Portrait (Dr. Rajesh Kumar):** `assets/images/dr_rajesh_kumar.jpg` (96x96 px rounded-2xl with 14px verified badge).
- **Brand Logo:** `assets/images/easycheck_logo_patient.png` (32px height in fixed app bar).
- **Icons:** Material Icons matching Stitch reference:
  - `Icons.arrow_back_rounded` (24px `#002553` back button)
  - `Icons.person_rounded` (18px white in 32x32 navy circular avatar)
  - `Icons.verified_rounded` (14px emerald in doctor badge)
  - `Icons.local_hospital_rounded` (18px navy hospital icon)
  - `Icons.receipt_long_rounded` (20px navy in 32x32 rounded container)
  - `Icons.sync_rounded` (14px in toggle pill)
  - `Icons.verified_user_rounded` (14px navy in reception verification pill)
  - `Icons.cloud_done_rounded` (16px navy backend assurance icon)
  - `Icons.lightbulb_rounded` (20px navy in 36x36 circular container)
  - `Icons.info_rounded` (18px in off-hours card header)
- **Fonts:** Inter Variable font family.

---

## 3. Visual Hierarchy & Architecture Implemented

1. **Fixed Top App Bar:**
   - 64px height (`h-16`) with safe-area padding.
   - Background: `surface/80` with `BackdropFilter` (blur 12px) and subtle shadow (`0 1px 8px rgba(7, 59, 120, 0.04)`).
   - Left: Circular back button (`Icons.arrow_back_rounded`), EasyCheck Online logo (32px), title `"Clinic Details"` (`title-md` `#002553`).
   - Right: Circular user avatar (32x32 `#002553` with white person icon).

2. **Doctor & Clinic Header Card:**
   - Container: `surface-container-lowest`, `rounded-xl`, shadow-md, overflow-hidden with ambient decorative circle (`160x160` circle in `surface-container-low` at 60% opacity).
   - Doctor photo: 96x96 px rounded-2xl with verified check circle badge.
   - Metadata: `"VERIFIED CLINIC PROFILE"` in `label-sm` (`#006d44`), availability pill with `LivePulseDot` + `"Currently Available"`, doctor name (H2: `"Dr. Rajesh Kumar, MD"`), specialty subtitle, hospital icon + `"Al-Shifa Family Health Clinic"`, full address.

3. **Live Parchi Counter Card Section:**
   - Header: `receipt_long` icon + `"Today’s Parchi Count"` + Interactive Sync Toggle Pill (`"Simulate Syncing"` / `"Show Synced (42)"`).
   - Central Counter Display: `surface-container-low` well with giant number display (`"42"` or `"—"`), verification chip (`"Verified by clinic reception"`), and animated pulsing live sync subtitle.
   - Comparison Grid: Yesterday Box (`"38 slips"`) vs Today Box in `secondary-container` (`"42 slips"` in bold `#007147`).
   - Footer: `cloud_done` icon + `"Count synced directly with reception desk backend"`.

4. **"Planning Your Visit" Guidance Card:**
   - `surface-container-low`, `rounded-xl`, lightbulb icon in 36x36 container, `"Planning Your Visit"` heading with reassuring copy.

5. **Off-Hours & Doctor Leave Notice Card (Informative Preview):**
   - Info icon + `"Off-Hours & Doctor Leave Notice"` + `"Standard Protocol"` chip + explanation text + sample row with offline dot (`#737781`), `"Session Closed · Offline"`, and `"—”`.
