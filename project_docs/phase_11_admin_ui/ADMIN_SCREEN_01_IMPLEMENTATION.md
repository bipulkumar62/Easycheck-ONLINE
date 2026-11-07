# Admin Screen 01 Implementation: Google Authentication Screen

**Screen Name:** Google Authentication Screen (Clinic Admin Login)  
**Phase:** Phase 11 — Admin UI Implementation  
**Project:** EasyCheck Online  
**Design System:** Clinical Precision  
**Stitch Source:** `stitch_easycheck_clinic_admin/stitch_easycheck_clinic_admin/google_authentication/`  
**HTML/CSS Source:** `google_authentication/code.html`  
**Visual Reference:** `google_authentication/screen.png` (487 x 1105 px)  
**Shell Type:** `mobile_blank` (Full viewport, no top app bar, no bottom tab bar)  
**Flutter Target:** `AdminLoginScreen` (`lib/features/authentication/admin_login_screen.dart`)  
**Route:** `/admin/login`

---

## 1. Visual Hierarchy & Exact Components Implemented

1. **Ambient Background:**
   - Soft off-white base (`#f8f9ff`).
   - Radial ambient blur orbs:
     - Top-left orb: 256x256 px `AdminColors.primaryContainer` at 10% opacity with `blur-3xl`.
     - Top-right orb: 192x192 px `AdminColors.secondary` at 10% opacity with `blur-2xl`.

2. **Centered Brand Identity Stack:**
   - 64x64 px container in `AdminColors.surfaceContainerLowest` with soft elevation shadow.
   - Admin square logo asset (`AssetConstants.logoAdmin`).
   - Verified checkmark badge pip in `AdminColors.primary` at bottom-right corner.
   - Brand Wordmark: `"EASYCHECK ONLINE"` in uppercase `label-sm` bold (`#375E9D`, tracking 2.5).
   - Headline H1: `"Clinic Admin"` in 28px Plus Jakarta Sans bold (`#0D1C2E`).
   - Subtitle: `"Sign in to manage your clinic."` in `body-md` (`#3D4A41`).

3. **Primary Authentication Card:**
   - Maximum width constrained to 384px, rounded 16px (`rounded-2xl`).
   - 56px height Google Sign-in button with official 4-color Google "G" vector.
   - Simulated OAuth loading overlay with circular spinner and `"Authenticating OAuth..."`.
   - Access restriction disclaimer: `"Authorized clinic staff access only."`.

4. **Dynamic State Transition Banner:**
   - Verified State: Green circle `check_circle`, `"IDENTITY VERIFIED"`, `"Dr. Sarah Jenkins"`, `"Lead Triage • Station 4 Ready"`, and animated spinner `"Redirecting to Live Queue..."`.
   - Denied State: Red circle `gpp_bad`, `"ACCESS RESTRICTED"`, `"Unassigned Account"`, explanation copy, and `"Request role elevation →"` trigger.

5. **Access Provisioning Helpdesk Modal Dialog:**
   - Translucent dark backdrop (`rgba(33, 49, 69, 0.40)`).
   - Key icon (`vpn_key_rounded`), title `"Access Provisioning"`, explanation of hospital Directory Services (LDAP/Azure AD).
   - Internal Support Contacts: `Ext: 4092 (Triage Operations)` and `admin-it@metrohealth.net`.
   - Dismiss button: `"Understood • Return to Login"`.

---

## 2. Flutter Files Created or Verified

- `lib/features/authentication/admin_login_screen.dart` — Full screen implementation.
- `lib/app/theme/app_colors.dart` — `AdminColors` tokens (Clinical Precision palette).
- `lib/app/theme/app_typography.dart` — `AdminTypography` tokens (Plus Jakarta Sans + Inter).
- `lib/app/routes/app_routes.dart` — Centralized route `/admin/login`.
- `lib/app/app.dart` — Route table registration with `_AdminThemed` wrapper.
- `test/widget_test.dart` — Automated widget test coverage.
