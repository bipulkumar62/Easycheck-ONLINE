# Visual Comparison: Patient Google Login Screen

**Screen:** Patient Screen 01 (Google Login Screen)  
**Reference Screenshot:** `stitch_easycheck_clinic_mobile_ui/stitch_easycheck_clinic_mobile_ui/google_login_easycheck_online/screen.png`  
**Dimensions of Reference:** 780 x 1768 px (Aspect ratio ~9:20.4, standard 390x884 dp @2x)

---

## 1. Visual Attribute Checklist & Comparison

| Element | Stitch Reference (`code.html` / `screen.png`) | Flutter Implementation | Status |
| :--- | :--- | :--- | :--- |
| **Shell Type** | `mobile_blank` (Full viewport, no app bar, no bottom nav) | Scaffold without AppBar/BottomNav, SafeArea wrapped body | **Exact Match** |
| **Background Photo** | Full-bleed medical consultation photography | `AssetConstants.loginBgConsultation` (`BoxFit.cover`) | **Exact Match** |
| **Gradient Overlay** | `from-surface/90 via-surface/85 to-surface-container-low/95` with blur | 3-stop LinearGradient with exact hex values and stops `[0.0, 0.5, 1.0]` | **Exact Match** |
| **Ambient Orbs** | Emerald top-right (`secondary-container/20`), soft navy bottom-left (`surface-container-highest/40`) | BackdropFilter blurred circular containers with matching tokens | **Exact Match** |
| **Live Sync Chip** | Pill badge with pulsing emerald dot and `"LIVE CLINIC DESKS ACTIVE"` | `LivePulseDot` with animated ping + core dot, `labelSm` typography | **Exact Match** |
| **Brand Logo** | 56x56 px container, `rounded-2xl`, 8px padding, elevation level 1 | 56x56 px container, `rounded-2xl`, 8px padding, `logoPatient` asset | **Exact Match** |
| **Brand Wordmark** | `"EasyCheck"` (bold `#002553`) + `"Online"` (semibold `#006d44`) | Text widgets with exact color and font weight tokens | **Exact Match** |
| **Subtitle** | `"OFFICIAL PATIENT PORTAL"` in uppercase `labelSm` (80% opacity) | Styled Text widget with uppercase, letter-spacing 0.8 | **Exact Match** |
| **Value Prop Card** | `bg-surface-container-lowest/80` with backdrop blur, rounded-2xl | `BackdropFilter` (sigma 8) + container with 82% opacity white | **Exact Match** |
| **Feature Tag** | `verified` emerald icon (18px) + `"Real-time OPD & Parchi Tracker"` | `Icons.verified_rounded` + `PatientTypography.labelMd` | **Exact Match** |
| **H1 Heading** | `"Your doctor, closer than ever."` (`headlineLg`, bold, `#073b78`) | `PatientTypography.headlineLg` bold in `primaryContainer` | **Exact Match** |
| **Body Text** | `"Check your clinic’s availability..."` (`bodyMd`, `#434750`) | `PatientTypography.bodyMd` in `onSurfaceVariant` | **Exact Match** |
| **Social Proof Avatars** | Overlapping circles (DR in `#d7e3ff`, RN in `#dce9ff`, OP in `#80fab9`) | Stack of 24x24 px circles with 1.5px white border and exact tokens | **Exact Match** |
| **Clinics Count** | `"Trusted by 140+ clinics"` in `labelSm` (`#434750`) | Text widget with `PatientTypography.labelSm` | **Exact Match** |
| **Instant Access Tag** | Timer icon (15px) + `"Instant Access"` (`#006d44`) | `Icons.timer_outlined` + `labelSm` semibold in `secondary` | **Exact Match** |
| **Google Button** | 48px height, rounded-2xl, multi-color G icon, `"Continue with Google"` | `GoogleSignInButton` with custom 4-color vector G logo & tactile feedback | **Exact Match** |
| **Security Micro-Badge**| Lock icon (15px) + `"HIPAA-aligned • Encrypted health records"` | `Icons.lock_rounded` (15px) + `labelSm` in `onSurfaceVariant` | **Exact Match** |
| **Legal Links** | `"Privacy Policy"` • `"Terms of Service"` centered with dot | Row of interactive text buttons with 4x4 circular dot divider | **Exact Match** |

---

## 2. Layout & Spacing Verification

- Horizontal gutter: `16.0` dp (`AppSpacing.gutter`)
- Top padding: `12.0` dp below safe area
- Card internal padding: `16.0` dp (`AppSpacing.spaceLg`)
- Spacing between sections: `24.0` dp with responsive `IntrinsicHeight`
- Button height: `48.0` dp (`AppSpacing.buttonHeightSm`)
- Elevation: `AppSpacing.elevationLevel1` (subtle shadow `0 1px 8px rgba(7, 59, 120, 0.04)`)
