# Patient Screen 01 Implementation: Google Login Screen

**Screen Name:** Google Login Screen  
**Source Prototype Directory:** `stitch_easycheck_clinic_mobile_ui/stitch_easycheck_clinic_mobile_ui/google_login_easycheck_online/`  
**HTML/CSS Source:** `google_login_easycheck_online/code.html`  
**Visual Reference:** `google_login_easycheck_online/screen.png` (780 x 1768 px)  
**Shell Type:** `mobile_blank` (Full viewport, no top app bar, no bottom nav)  
**Design System:** Clinical Clarity (Patient Mobile UI)

---

## 1. Flutter Files Created or Modified

- `lib/features/authentication/patient_login_screen.dart` — Full screen implementation matching Stitch HTML/CSS.
- `lib/core/constants/asset_constants.dart` — Asset reference mappings (`AssetConstants.logoPatient`, `AssetConstants.loginBgConsultation`).
- `lib/shared/widgets/shared_widgets.dart` — Reusable `LivePulseDot`, `GoogleSignInButton` with custom tactile feedback and vector G logo.
- `lib/app/theme/app_colors.dart` — Tokens for Clinical Clarity (`PatientColors`).
- `lib/app/theme/app_typography.dart` — Material 3 / Stitch typography tokens with Inter font family.
- `lib/app/theme/app_spacing.dart` — Elevation, radii, and spacing tokens.
- `pubspec.yaml` — Asset bundling and fonts.

---

## 2. Assets Used

- **Background Image:** `assets/images/login_bg_consultation.jpg` (Full-bleed medical clinic consultation photo).
- **Brand Logo:** `assets/images/easycheck_logo_patient.png` (56x56 px rounded container with 8px padding).
- **Google Icon:** Rendered via vector CustomPainter `_GoogleGLogo` and `_GoogleLogoPainter` in official 4 colors (`#4285F4`, `#34A853`, `#FBBC05`, `#EA4335`).
- **Icons:** Material Icons matching Stitch:
  - `Icons.verified_rounded` (18px, emerald `#006d44`)
  - `Icons.timer_outlined` (15px, emerald `#006d44`)
  - `Icons.lock_rounded` (15px, emerald `#006d44`)
- **Fonts:** Inter Variable (`assets/fonts/Inter-Variable.ttf`).

---

## 3. Visual Hierarchy & Architecture Implemented

1. **Background Layer:**
   - Full-bleed image (`BoxFit.cover`).
   - Vertical gradient overlay: `surface/90` (`0xE6F8F9FF`) -> `surface/85` (`0xD9F8F9FF`) -> `surface-container-low/95` (`0xF2EFF4FF`).
   - Ambient glow orbs:
     - Top-right: 320x320 blur-70 orb with `PatientColors.secondaryContainer` (20% opacity).
     - Bottom-left: 280x280 blur-60 orb with `PatientColors.surfaceContainerHighest` (35% opacity).

2. **Top Header Area:**
   - Live Sync Status Chip: `rounded-full` pill with `LivePulseDot` and `'LIVE CLINIC DESKS ACTIVE'` in `PatientTypography.labelSm` (`#007147`).
   - Brand container: 56x56 px `rounded-2xl` with patient logo.
   - Wordmark: `'EasyCheck'` (bold `#002553`) + `'Online'` (semi-bold `#006d44`).
   - Subtitle: `'OFFICIAL PATIENT PORTAL'` in uppercase `labelSm` (`#434750` at 80% opacity).

3. **Center Value Proposition Card:**
   - Elevation Level 1: `bg-surface-container-lowest/82` with `BackdropFilter` (sigma 8).
   - Verified badge + `'Real-time OPD & Parchi Tracker'` (`#006d44`).
   - Main Heading (H1): `'Your doctor, closer than ever.'` in bold `headlineLg` (`#073b78`).
   - Body: `'Check your clinic’s availability and live parchi updates in one calm, unified place.'` (`#434750`).
   - Social proof row: 3 overlapping avatar initials (DR `#d7e3ff`, RN `#dce9ff`, OP `#80fab9`) + `'Trusted by 140+ clinics'` + Timer icon + `'Instant Access'`.

4. **Bottom Action Zone:**
   - `GoogleSignInButton`: 48px height, rounded-2xl, tactile feedback (opacity shift to 0.85 for 180ms), with Google 4-color icon and `'Continue with Google'`.
   - Security badge: Lock icon + `'HIPAA-aligned • Encrypted health records'`.
   - Legal footer: `'Privacy Policy'` and `'Terms of Service'` with dot divider.
