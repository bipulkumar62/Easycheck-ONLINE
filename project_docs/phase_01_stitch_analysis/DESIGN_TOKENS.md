# Design Tokens: EasyCheck Online

**Document Version:** 1.0.0  
**Phase:** Phase 01 — Stitch Design Analysis  
**Project:** EasyCheck Online  

This document codifies the design tokens extracted from both Stitch design systems: **Clinical Clarity** (Patient Mobile UI) and **Clinical Precision** (Clinic Admin Mobile UI).

---

## 1. Color Palettes

### 1.1 Patient Mobile UI ("Clinical Clarity") Tokens

| Token Name | Hex Code | Usage / Semantic Role |
| :--- | :--- | :--- |
| `primary` | `#002553` | Primary structural brand blue; title headings, major chrome |
| `primary-container` | `#073b78` | Deep clinical navy; high-contrast cards, brand emphasis |
| `on-primary` | `#ffffff` | Foreground text on primary elements |
| `on-primary-container` | `#82a7eb` | Subtle text on navy container |
| `inverse-primary` | `#aac7ff` | Inverted primary accent |
| `primary-fixed` | `#d7e3ff` | Soft tinted chips, avatar badge background |
| `primary-fixed-dim` | `#aac7ff` | Dimmed variant for primary-fixed |
| `on-primary-fixed` | `#001b3e` | Dark text on tinted chips |
| `on-primary-fixed-variant` | `#1a4683`| Medium contrast text on tinted chips |
| `secondary` | `#006d44` | Clinical emerald; live indicators, verified badges, active tabs |
| `secondary-container` | `#7df7b6` | Bright emerald container; today's parchi badge, available pill |
| `on-secondary` | `#ffffff` | Text on secondary elements |
| `on-secondary-container` | `#007147` | Deep green text on emerald container |
| `secondary-fixed` | `#80fab9` | Soft emerald fixed tint |
| `secondary-fixed-dim` | `#62dd9e` | Dimmed emerald tint |
| `on-secondary-fixed` | `#002111` | Deep contrast text on emerald-fixed |
| `on-secondary-fixed-variant`| `#005232` | Medium contrast text on emerald-fixed |
| `tertiary` | `#002942` | Supporting medical teal/slate |
| `tertiary-container` | `#004064` | Tertiary container surface |
| `on-tertiary` | `#ffffff` | Text on tertiary |
| `on-tertiary-container` | `#4faef4` | Cyan accent on tertiary container |
| `surface` | `#f8f9ff` | Base screen canvas (cool crisp off-white) |
| `surface-dim` | `#cbdbf5` | Dimmed surface canvas |
| `surface-bright` | `#f8f9ff` | Bright surface canvas |
| `surface-container-lowest` | `#ffffff` | Pure white; cards, sheets, elevated surfaces |
| `surface-container-low` | `#eff4ff` | Subtle wells, search bar backgrounds, inactive chips |
| `surface-container` | `#e5eeff` | Container fill, avatar backgrounds |
| `surface-container-high` | `#dce9ff` | Elevated container fill |
| `surface-container-highest` | `#d3e4fe`| Highest container elevation |
| `surface-variant` | `#d3e4fe` | Surface tint variant |
| `on-surface` | `#0b1c30` | High-emphasis body text and primary labels |
| `on-surface-variant` | `#434750` | Medium-emphasis body text, secondary captions |
| `inverse-surface` | `#213145` | Toast backgrounds, inverted surfaces |
| `inverse-on-surface` | `#eaf1ff` | Text on inverse surfaces |
| `outline` | `#737781` | Inactive icon colors, border lines, subtle rules |
| `outline-variant` | `#c3c6d2` | Hairline dividers, separator dots |
| `surface-tint` | `#375e9d` | Ambient tinted overlay |
| `error` | `#ba1a1a` | Alert & error states |
| `error-container` | `#ffdad6` | Error badge background |
| `on-error` | `#ffffff` | Text on error |
| `on-error-container` | `#93000a` | Dark red text on error container |
| `background` | `#f8f9ff` | Base viewport background |
| `on-background` | `#0b1c30` | Text on base viewport |

---

### 1.2 Admin Mobile UI ("Clinical Precision") Tokens

| Token Name | Hex Code | Usage / Semantic Role |
| :--- | :--- | :--- |
| `primary` | `#006a42` | Primary emerald action color; increment button, active status |
| `primary-container` | `#008655` | Vivid emerald container; shift badge, active status pill |
| `on-primary` | `#ffffff` | White text on primary buttons |
| `on-primary-container` | `#f6fff6` | Light text on primary container |
| `inverse-primary` | `#62dd9e` | Dimmed emerald for dark toast icons |
| `primary-fixed` | `#80fab9` | Soft emerald background for active status buttons |
| `primary-fixed-dim` | `#62dd9e` | Dimmed variant for primary-fixed |
| `on-primary-fixed` | `#002111` | Deep contrast text on active status buttons |
| `on-primary-fixed-variant` | `#005232`| Medium contrast text |
| `secondary` | `#375e9d` | Deep authority navy; security headers, title tags |
| `secondary-container` | `#94b9fe` | Tinted blue container |
| `on-secondary` | `#ffffff` | Text on secondary elements |
| `on-secondary-container` | `#1d4886` | Contrast text on secondary container |
| `secondary-fixed` | `#d7e3ff` | Soft navy fixed tint; avatar backgrounds |
| `secondary-fixed-dim` | `#aac7ff` | Dimmed navy tint |
| `on-secondary-fixed` | `#001b3e` | Dark text on navy-fixed |
| `on-secondary-fixed-variant`| `#1a4683` | Medium contrast text |
| `tertiary` | `#535f59` | Neutral slate for sub-labels and timestamps |
| `tertiary-container` | `#6b7771` | Tertiary container fill |
| `on-tertiary` | `#ffffff` | Text on tertiary |
| `on-tertiary-container` | `#f5fff8` | Light text on tertiary container |
| `surface` | `#f8f9ff` | Cool off-white canvas |
| `surface-dim` | `#ccdbf3` | Dimmed surface |
| `surface-bright` | `#f8f9ff` | Bright surface |
| `surface-container-lowest` | `#ffffff` | Pure white; cards, modal bodies, popovers |
| `surface-container-low` | `#eff4ff` | Counter well background, inactive status buttons |
| `surface-container` | `#e6eeff` | Divider fills, pill backgrounds |
| `surface-container-high` | `#dce9ff` | Elevated toolbar containers |
| `surface-container-highest` | `#d5e3fc`| Highest container elevation |
| `surface-variant` | `#d5e3fc` | Drawer handle background |
| `on-surface` | `#0d1c2e` | Primary high-emphasis headline text |
| `on-surface-variant` | `#3d4a41` | Secondary labels, descriptions |
| `inverse-surface` | `#233144` | Toast background, dark scrim overlays |
| `inverse-on-surface` | `#eaf1ff` | Toast text |
| `outline` | `#6d7a70` | Hairline rules, inactive icons |
| `outline-variant` | `#bccabf` | Divider lines |
| `error` | `#ba1a1a` | Destructive reset button, reset warning |
| `error-container` | `#ffdad6` | Reset modal icon well, error pills |
| `on-error` | `#ffffff` | Text on destructive buttons |
| `on-error-container` | `#93000a` | Dark red text on error container |

---

## 2. Typography Hierarchy

### 2.1 Patient Mobile UI Typography (Inter)

| Token Name | Font Family | Size | Line Height | Weight | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `display-lg` | Inter | 32px | 40px | 700 (Bold) | -0.02em |
| `headline-lg` | Inter | 26px | 34px | 600 (Semi-bold) | -0.015em |
| `headline-md` | Inter | 22px | 28px | 600 (Semi-bold) | -0.01em |
| `headline-sm` | Inter | 18px | 24px | 600 (Semi-bold) | 0.0em |
| `title-md` | Inter | 16px | 22px | 600 (Semi-bold) | 0.0em |
| `body-lg` | Inter | 16px | 24px | 400 (Regular) | 0.0em |
| `body-md` | Inter | 14px | 20px | 400 (Regular) | 0.0em |
| `body-sm` | Inter | 13px | 18px | 400 (Regular) | 0.0em |
| `label-lg` | Inter | 14px | 20px | 600 (Semi-bold) | 0.01em |
| `label-md` | Inter | 12px | 16px | 500 (Medium) | 0.02em |
| `label-sm` | Inter | 11px | 14px | 600 (Semi-bold) | 0.03em |

---

### 2.2 Admin Mobile UI Typography (Plus Jakarta Sans + Inter)

| Token Name | Font Family | Size | Line Height | Weight | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `headline-xl` | Plus Jakarta Sans | 36px | 44px | 700 (Bold) | -0.03em |
| `headline-xl-mobile` | Plus Jakarta Sans | 28px | 34px | 700 (Bold) | -0.02em |
| `headline-lg` | Plus Jakarta Sans | 30px | 38px | 600 (Semi-bold) | -0.02em |
| `headline-lg-mobile` | Plus Jakarta Sans | 22px | 28px | 600 (Semi-bold) | -0.01em |
| `headline-md` | Plus Jakarta Sans | 20px | 26px | 600 (Semi-bold) | -0.01em |
| `headline-sm` | Plus Jakarta Sans | 16px | 22px | 600 (Semi-bold) | 0.0em |
| `counter-giant` | Plus Jakarta Sans | 68px | 68px (leading-none) | 700 (Bold) | -0.04em (`tnum`) |
| `body-lg` | Inter | 16px | 24px | 400 (Regular) | 0.0em |
| `body-md` | Inter | 14px | 20px | 400 (Regular) | 0.0em |
| `body-sm` | Inter | 12px | 16px | 400 (Regular) | 0.0em |
| `label-lg` | Inter | 14px | 20px | 600 (Semi-bold) | 0.01em |
| `label-md` | Inter | 12px | 16px | 600 (Semi-bold) | 0.02em |
| `label-sm` | Inter | 11px | 14px | 700 (Bold) | 0.04em |

---

## 3. Spacing & Dimensions

| Token Name | Value (rem) | Value (px) | Application |
| :--- | :--- | :--- | :--- |
| `space-xs` | 0.25rem | 4px | Micro spacing, icon gaps, dot margins |
| `space-sm` | 0.5rem | 8px | Button inner padding, pill vertical padding, badge gaps |
| `space-md` | 0.75rem / 1.0rem | 12px (Patient) / 16px (Admin) | Card gaps, input padding |
| `space-lg` | 1.0rem / 1.5rem | 16px (Patient) / 24px (Admin) | Card internal padding, section margins |
| `space-xl` | 1.5rem / 2.0rem | 24px (Patient) / 32px (Admin) | Outer section spacing, header margins |
| `space-2xl` | 2.0rem | 32px | Viewport boundaries |
| `gutter` | 1.0rem | 16px | Horizontal page gutter |
| `gutter-sm` | 0.75rem | 12px | Compact page gutter |
| `margin` | 1.0rem | 16px | Standard mobile viewport margin |
| `margin-lg` | 1.5rem | 24px | Expanded mobile/tablet margin |

---

## 4. Border Radii

| Token Name | Value (rem / px) | Application |
| :--- | :--- | :--- |
| `rounded-sm` | 0.25rem (4px) | Status dots, micro badges |
| `rounded` / `DEFAULT` | 0.5rem (8px) | Small chips, comparison sub-boxes |
| `rounded-md` | 0.75rem (12px) | Action cards, input fields |
| `rounded-lg` | 1.0rem (16px) | Standard cards, profile containers |
| `rounded-xl` | 1.25rem (20px) | Operational cards, doctor photos |
| `rounded-2xl` | 1.5rem (24px) | Primary cards, action buttons, modals |
| `rounded-3xl` | 2.0rem (32px) | Dialog containers, bottom sheets |
| `rounded-full` | 9999px | Status pills, avatars, circular action buttons |

---

## 5. Elevation & Shadows

Both design systems use tinted navy shadows rather than pitch black, preventing harsh dark edges and enhancing clinical cleanliness:

### Level 0 (Canvas Base)
- **Shadow:** `none`
- **Background:** `#F8F9FF`

### Level 1 (Standard Card / Content Blocks)
- **CSS:** `box-shadow: 0 1px 3px 0 rgba(7, 59, 120, 0.03), 0 1px 2px -1px rgba(7, 59, 120, 0.02);`
- **Border:** `1px solid #E2E8F0` (or `rgba(226, 232, 240, 0.8)`)
- **Background:** Pure White `#FFFFFF`

### Level 2 (Active Cards & Floating Sheets)
- **CSS:** `box-shadow: 0 4px 12px -2px rgba(7, 59, 120, 0.06), 0 2px 6px -2px rgba(7, 59, 120, 0.03);`
- **Border:** `1px solid #E2E8F0`

### Level 3 (Modals, Overlays & Sticky Bars)
- **CSS:** `box-shadow: 0 12px 28px -4px rgba(7, 59, 120, 0.10), 0 4px 12px -2px rgba(7, 59, 120, 0.04);`
- **Backdrop:** `backdrop-filter: blur(16px)`

---

## 6. Button & Card Component Styles

### 6.1 Buttons

#### Patient Primary Button (Google Sign-In)
- **Height:** 48px (`h-12`)
- **Background:** `#FFFFFF` (`surface-container-lowest`)
- **Border Radius:** `rounded-2xl` (16px)
- **Shadow:** `shadow-sm`
- **Typography:** `label-lg` (14px, font-weight 600, `#0b1c30`)
- **Active State:** Scale down to `0.99`, opacity `0.85` for 180ms

#### Admin Primary Action Button
- **Height:** 56px (`h-14`)
- **Background:** `#006A42` (`primary`)
- **Text:** `#FFFFFF` (`on-primary`)
- **Border Radius:** `rounded-2xl` (16px)
- **Shadow:** `shadow-md`
- **Typography:** `headline-sm` / `label-lg` (Semi-bold, 16px/14px)
- **Active State:** Scale down to `0.98`

#### Admin Oversized Counter Controls
- **Plus (`+`) Button:** 64x64 (`w-16 h-16`), circular (`rounded-full`), background `#006A42`, ring `ring-4 ring-primary-fixed/40`, shadow `shadow-lg`, icon `add` (34px `#ffffff`).
- **Minus (`-`) Button:** 64x64 (`w-16 h-16`), circular (`rounded-full`), background `#FFFFFF`, shadow `shadow-sm`, icon `remove` (32px `#0d1c2e`). Disabled state: `opacity: 0.40`.

#### Destructive Action Button (Reset Counter)
- **Height:** 52px
- **Background:** `#BA1A1A` (`error`)
- **Text:** `#FFFFFF` (`on-error`)
- **Border Radius:** `rounded-2xl` (16px)
- **Shadow:** `shadow-md`

---

### 6.2 Cards & Wells

#### Patient Clinic Discovery Card
- **Background:** `#FFFFFF`
- **Border Radius:** `rounded-2xl` (16px)
- **Padding:** 16px (`p-4`)
- **Shadow:** `shadow-sm` transitioning to `shadow-md` on hover/active
- **Internal Separators:** None or hairline `#F1F5F9`

#### Admin Counter Well
- **Background:** `#EFF4FF` (`surface-container-low`)
- **Border Radius:** `rounded-2xl` (16px)
- **Padding:** Vertical 24px (`py-6`), Horizontal 16px (`px-4`)
- **Shadow:** `shadow-inner`

#### Status Pills
- **Available / Active:** Pill `rounded-full`, background `#EAF7EF` (or `#7df7b6` in patient badge), text `#006d44` / `#16a36a`, 6px live pulsing emerald dot.
- **Delayed:** Pill `rounded-full`, background `#FEF3C7`, text `#D97706`.
- **Closed / Offline:** Pill `rounded-full`, background `#E5EEFF`, text `#434750`, static gray dot.
