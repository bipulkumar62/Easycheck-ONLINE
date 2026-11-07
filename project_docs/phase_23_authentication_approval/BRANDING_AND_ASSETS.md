# Branding & Asset Fixes

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 5, 2026

---

## 1. Problem

The in-app brand marks and launcher icons were not consistently using the EasyCheck identity. Android could show a default/placeholder launcher icon, and web/PWA icons did not match the in-app logo.

---

## 2. In-App Logo Assets

### 2.1 Canonical mark

`assets/images/easycheck_logo_mark_square.png` is now the single canonical in-app mark:

| Property | Value |
|----------|-------|
| Size | 512 × 512 |
| Shape | Square |
| Background | Transparent, already padded |
| Content | Navy “C”, teal medical cross, navy check |

The square mark replaces the old wide wordmark in square tiles. The old 136 × 84 `easycheck_logo_mark.png`, `easycheck_logo_patient.png` and `easycheck_logo_admin.png` files remain for compatibility, but no screen uses them as the primary mark.

`AssetConstants.logoMark` points at the square mark:

```dart
static const String logoMark =
    'assets/images/easycheck_logo_mark_square.png';
```

### 2.2 Shared `BrandMark` widget

`lib/core/widgets/brand_mark.dart` wraps the square mark in a consistent white, rounded, bordered tile:

- Prevents the old wide-wordmark-in-a-square distortion.
- Keeps optical centring on every surface.
- Accepts `size`, `padding`, `radius`, `background`, `borderColor` and `showShadow`.
- Uses `cacheWidth` based on device pixel ratio for crisp rendering and lower memory use.
- Includes an `errorBuilder` fallback icon, so a missing asset cannot break a screen.

Used by role selection, patient login, patient home, clinic details, admin login, admin auth shell, reset studio and auth gate.

### 2.3 Live status dots

`lib/core/widgets/live_dot.dart` provides:

- `LiveDot` — pulsing green dot with reduced-motion support.
- `LiveStatusPill` — dot plus label inside a rounded pill.

All “live” indicators use these widgets instead of hand-built coloured circles, so the green is consistent and the pulse respects accessibility settings.

---

## 3. Android Launcher Icons

### 3.1 Legacy mipmap icons

| Density | Size | File |
|---------|------|------|
| mdpi | 48 × 48 | `mipmap-mdpi/ic_launcher.png` |
| hdpi | 72 × 72 | `mipmap-hdpi/ic_launcher.png` |
| xhdpi | 96 × 96 | `mipmap-xhdpi/ic_launcher.png` |
| xxhdpi | 144 × 144 | `mipmap-xxhdpi/ic_launcher.png` |
| xxxhdpi | 192 × 192 | `mipmap-xxxhdpi/ic_launcher.png` |

Each icon is drawn on a white plate with the EasyCheck mark centered and padded so the mark is not clipped by launcher masks.

### 3.2 Adaptive icon (Android 8.0+)

| File | Purpose |
|------|---------|
| `res/values/colors.xml` | `ic_launcher_background = #FFFFFF` |
| `res/drawable-nodpi/ic_launcher_foreground.png` | 432 × 432 foreground |
| `res/mipmap-anydpi-v26/ic_launcher.xml` | Adaptive icon |
| `res/mipmap-anydpi-v26/ic_launcher_round.xml` | Round adaptive icon |

`ic_launcher.xml`:

```xml
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
```

`AndroidManifest.xml` now declares both:

```xml
android:icon="@mipmap/ic_launcher"
android:roundIcon="@mipmap/ic_launcher_round"
```

The white background matches the mark’s existing white plate and avoids a colored square behind the logo.

### 3.3 Branded launch screen

| File | Purpose |
|------|---------|
| `res/drawable-nodpi/launch_mark.png` | 200 × 200 centred mark |
| `res/drawable/launch_background.xml` | White background + centred mark |
| `res/drawable-v21/launch_background.xml` | White background + centred mark |

The launch screen shows the EasyCheck mark on white instead of the default blank Flutter splash.

---

## 4. Web / PWA Icons

| Asset | Size | Purpose |
|-------|------|---------|
| `web/favicon.png` | 32 × 32 | Browser favicon |
| `web/icons/Icon-180.png` | 180 × 180 | Apple touch icon |
| `web/icons/Icon-192.png` | 192 × 192 | PWA icon |
| `web/icons/Icon-512.png` | 512 × 512 | PWA icon |
| `web/icons/Icon-maskable-192.png` | 192 × 192 | Maskable PWA icon |
| `web/icons/Icon-maskable-512.png` | 512 × 512 | Maskable PWA icon |

`web/index.html` references the favicon, Apple touch icon, 192 px icon and manifest. `web/manifest.json` references the standard and maskable icons, with theme color `#002553` and background `#F8F9FF`.

Maskable icons use extra padding so the mark stays inside the safe zone when a platform applies a circle or squircle mask.

---

## 5. Asset Pipeline

Icons were generated with `System.Drawing` from the square source mark:

1. Load `easycheck_logo_mark_square.png`.
2. Create a square canvas at the target size.
3. Fill white.
4. Use high-quality bicubic interpolation.
5. Fit the mark inside the padded area while preserving aspect ratio.
6. Center and save as PNG.

`tools/generate_store_assets.ps1` reproduces the Play Store icon and feature graphic. This keeps all launcher, web and store assets visually consistent with the in-app mark.

---

## 6. Play Store Listing Assets

| Asset | Size | File | Notes |
|-------|------|------|-------|
| App icon | 512 × 512 | `store_assets/app_icon_512.png` | White plate, centred mark, 89.5 KB |
| Feature graphic | 1024 × 500 | `store_assets/feature_graphic_1024x500.png` | Navy gradient, brand mark, “Live parchi tracking for clinics and patients”, 105.8 KB |

The feature graphic avoids unverifiable claims and does not name any internal technology or backend.

---

## 7. Verification

| Check | Result |
|-------|--------|
| Canonical square mark exists and is 512 × 512 | ✅ |
| `BrandMark` uses `AssetConstants.logoMark` | ✅ |
| `LiveDot` / `LiveStatusPill` used for live indicators | ✅ |
| Premium Google button uses the official G mark | ✅ |
| Android legacy icons exist at all five densities | ✅ |
| Adaptive foreground is 432 × 432 | ✅ |
| Adaptive icon XML exists for square and round | ✅ |
| Manifest declares `roundIcon` | ✅ |
| Branded launch screen XML and 200 × 200 mark exist | ✅ |
| Web favicon and PWA icons exist | ✅ |
| Play Store icon is 512 × 512 | ✅ |
| Feature graphic is 1024 × 500 | ✅ |
| `flutter analyze` after asset changes | ✅ No issues |
| `flutter build apk --release` after asset changes | ✅ Built and installed on Pixel_7 |
| In-app image `errorBuilder` fallbacks | ✅ Present on all usages |

---

## 8. Notes

- Launcher icons only refresh on Android after reinstalling the app or clearing the launcher’s icon cache; this is platform behavior, not an app bug.
- The web build must be redeployed to Firebase Hosting for the new icons to appear on the hosted site.
- No third-party or copyrighted logo was introduced; the mark is the project’s own EasyCheck identity.
- Play Store may apply its own rounded mask to the 512 × 512 icon. The mark is padded so the “C” and check remain inside the safe area.
