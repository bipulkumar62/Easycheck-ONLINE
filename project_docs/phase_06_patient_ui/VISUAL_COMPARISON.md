# Visual Comparison: Clinic Details & Live Parchi Screen

**Screen:** Patient Screen 03 (Clinic Details & Live Parchi Screen)  
**Reference Screenshot:** `stitch_easycheck_clinic_mobile_ui/stitch_easycheck_clinic_mobile_ui/clinic_details_easycheck_online/screen.png`  
**Dimensions of Reference:** 780 x 2394 px (Aspect ratio ~9:27.6, standard 390x1197 dp @2x)

---

## 1. Visual Attribute Checklist & Comparison

| Element | Stitch Reference (`code.html` / `screen.png`) | Flutter Implementation | Status |
| :--- | :--- | :--- | :--- |
| **Shell Type** | `mobile_stack` (Fixed top bar with back navigation, no bottom nav) | `Scaffold` with fixed `BackdropFilter` app bar + `CustomScrollView` | **Exact Match** |
| **Top App Bar** | 64px height (`h-16`), `surface/80` with `backdrop-blur-xl`, subtle shadow | 64px height + safe area, `BackdropFilter(sigma: 12)`, matching shadow | **Exact Match** |
| **Back Button** | 44x44 circular button, `arrow_back` icon (24px `#002553`), `history.back()` | 44x44 `IconButton` with `Icons.arrow_back_rounded` calling `Navigator.pop()` | **Exact Match** |
| **Header Logo & Title** | EasyCheck logo (32px) + `"Clinic Details"` in `title-md` bold | `AssetConstants.logoPatient` (32px) + `PatientTypography.titleMd` | **Exact Match** |
| **User Avatar** | 32x32 circular avatar filled `#002553` with white person icon | 32x32 Container, shape circle, white `Icons.person_rounded` (18px) | **Exact Match** |
| **Doctor Card Container**| `surface-container-lowest`, `rounded-xl`, shadow-md, overflow-hidden | Container with `PatientColors.surfaceContainerLowest`, 12px radius, shadow | **Exact Match** |
| **Ambient Accent** | Background decorative circle `w-40 h-40` at `-right-10 -bottom-10` | Positioned 160x160 circular container in `surfaceContainerLow` (60% opacity) | **Exact Match** |
| **Doctor Photo** | 96x96 rounded-2xl portrait of Dr. Rajesh Kumar with verified badge | `AssetConstants.drRajeshKumar` (96x96), 16px radius + verified check badge | **Exact Match** |
| **Availability Pill** | Pulsing emerald ping dot + `"Currently Available"` (`bg-secondary-container`) | `LivePulseDot` + `labelMd` semibold in `secondaryContainer` | **Exact Match** |
| **Doctor Name & Specialty** | `"Dr. Rajesh Kumar, MD"` (`headline-sm` `#002553`) + Consultant Cardiologist | `PatientTypography.headlineSm` + `PatientTypography.bodySm` | **Exact Match** |
| **Clinic Info Strip** | Hospital icon (18px) + `"Al-Shifa Family Health Clinic"` + full address | `Icons.local_hospital_rounded` + clinic name bold + address text | **Exact Match** |
| **Parchi Card Header** | `receipt_long` in rounded container + `"Today’s Parchi Count"` | Container with `Icons.receipt_long_rounded` + `titleMd` font-semibold | **Exact Match** |
| **Sync Toggle Button** | Pill button with sync icon + `"Simulate Syncing"` / `"Show Synced (42)"` | Interactive `InkWell` pill with animated rotation + matching state label | **Exact Match** |
| **Giant Metric Display**| 32px/40px bold number (`"42"` or `"—"`) in `surface-container-low` well | `PatientTypography.displayLg` in `PatientColors.primary` / `outline` | **Exact Match** |
| **Reception Chip** | `verified_user` (14px) + `"Verified by clinic reception"` pill | Pill in `surfaceContainerHighest` with primary colored icon and text | **Exact Match** |
| **Sync Status Ping** | Animated green ping dot + `"Real-time synchronization connected..."` | `LivePulseDot` (6px) + `labelMd` centered text in `onSurfaceVariant` | **Exact Match** |
| **Comparison Grid** | 2-column grid: Yesterday box (`surface-container-low`) vs Today box | Row of two `Expanded` containers with matching metrics and subtexts | **Exact Match** |
| **Sync Assurance Note** | `cloud_done` icon (16px) + `"Count synced directly with reception..."` | `Icons.cloud_done_rounded` + `bodySm` in `onSurfaceVariant` | **Exact Match** |
| **Planning Visit Card** | Lightbulb icon in circle container + `"Planning Your Visit"` + body | Container in `surfaceContainerLow` with `Icons.lightbulb_rounded` + copy | **Exact Match** |
| **Off-Hours Card** | Info icon + title + `"Standard Protocol"` chip + explanation + sample row | Container in `surfaceContainerLowest` with offline dot and `"—"` | **Exact Match** |

---

## 2. Layout & Spacing Verification

- Viewport padding: `16.0` dp (`AppSpacing.gutter`)
- Inter-card spacing: `16.0` dp (`AppSpacing.spaceLg`)
- Card internal padding: `16.0` dp (`AppSpacing.spaceLg`)
- Doctor portrait: `96.0 x 96.0` dp with `16.0` dp corner radius
- Fixed top bar height: `64.0` dp plus `MediaQuery.padding.top`
- Safe area bottom padding: `MediaQuery.padding.bottom + 32.0` dp
