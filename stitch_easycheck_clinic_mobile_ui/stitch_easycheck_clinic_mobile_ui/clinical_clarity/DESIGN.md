---
name: Clinical Clarity
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#434750'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#737781'
  outline-variant: '#c3c6d2'
  surface-tint: '#375e9d'
  primary: '#002553'
  on-primary: '#ffffff'
  primary-container: '#073b78'
  on-primary-container: '#82a7eb'
  inverse-primary: '#aac7ff'
  secondary: '#006d44'
  on-secondary: '#ffffff'
  secondary-container: '#7df7b6'
  on-secondary-container: '#007147'
  tertiary: '#002942'
  on-tertiary: '#ffffff'
  tertiary-container: '#004064'
  on-tertiary-container: '#4faef4'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d7e3ff'
  primary-fixed-dim: '#aac7ff'
  on-primary-fixed: '#001b3e'
  on-primary-fixed-variant: '#1a4683'
  secondary-fixed: '#80fab9'
  secondary-fixed-dim: '#62dd9e'
  on-secondary-fixed: '#002111'
  on-secondary-fixed-variant: '#005232'
  tertiary-fixed: '#cce5ff'
  tertiary-fixed-dim: '#93ccff'
  on-tertiary-fixed: '#001d31'
  on-tertiary-fixed-variant: '#004b73'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.75rem
  margin: 1rem
  margin-lg: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
  space-2xl: 2rem
---

## Brand & Style

This design system establishes an empathetic, pristine, and profoundly trustworthy environment tailored for mobile clinical experiences. It bridges medical authority with approachable care, reducing cognitive load and physiological stress for patients and caregivers across all age demographics.

### Visual Style
The aesthetic is **Clinical Minimalism**:
- **Purity & Breathability:** Uncluttered layouts anchored in crisp whites and neutral slate foundations, prioritizing glanceability and calm navigation.
- **Precision & Purpose:** Restrained UI chrome without decorative visual noise, artificial heavy gradients, or skeletal complexity.
- **Empathetic Tactility:** Soft, rounded surfaces with gentle elevation that emulate premium ambient stationery, instilling an immediate sense of quiet safety and operational competence.

## Colors

The palette balances authoritative deep medical blue with an organic, reassuring emerald accent to clearly demarcate structure from actionable vitality.

### Palette Architecture
- **Primary Navy (`#073B78`):** Anchors high-priority structural elements, critical display typography, active navigation nodes, and primary actions. Delivers deep clinical credibility and high contrast.
- **Brand Accent Emerald (`#16A36A`):** Designated exclusively for confirmed states, positive clinical statuses (e.g., "Clinic Open", "On Schedule"), vital signs indicators, and targeted secondary triggers.
- **Tertiary Cyan (`#0284C7`):** Used sparingly for informative callouts, active appointment badges, and telemetry tags.
- **Surfaces & Canvases:**
  - Base Background: `#F8FAFC` (Canvas off-white)
  - Surface Pure: `#FFFFFF` (Card decks, modal sheets, elevated controls)
  - Surface Subdued: `#F1F5F9` (List track states, inner segment wells, disabled inputs)
- **Borders & Dividers:** Subtle `#E2E8F0` hairline rules providing structural separation without visual friction.
- **Text & Contrast:**
  - High Emphasis / Headings: `#0F172A` and `#073B78`
  - Medium Emphasis / Body: `#334155`
  - Low Emphasis / Captions & Timestamps: `#64748B`

## Typography

The type system is powered entirely by **Inter**, selected for its tall x-height, neutral geometric clarity, and legibility across all age groups and visual acuity levels.

### Application Rules
- **Display & Headings:** Rendered primarily in Navy `#073B78` or Slate 900 `#0F172A`. Keep tight letter-tracking on display scales to maintain cohesion.
- **Body & Clinical Records:** Retain standard tracking with open line-heights (minimum 1.45x) to guarantee zero misreading of dosage numbers, appointment times, or medical directions.
- **Labels & Status Counters:** Rendered in Medium or Semi-bold weights with slight tracking expansion to ensure high-visibility at glance distances on mobile screens.

## Layout & Spacing

A strictly regimented 4px/8px layout system built specifically for handheld mobile devices, prioritizing single-thumb ergonomics and safe screen regions.

### Screen Layout Principles
- **Margins:** Standard mobile canvas boundary uses `margin` (`16px`), expanding to `margin-lg` (`24px`) on tablets or landscape views.
- **Vertical Rhythm:** Cards, appointment sections, and summary groups are separated by `space-lg` (`16px`) or `space-xl` (`24px`).
- **Touch Reachability:** Essential check-in actions and status overviews reside in the natural thumb sweep zone (lower 60% of the viewport). Android bottom sheets leverage safe-area padding directly linked to system navigation bars.

## Elevation & Depth

Visual hierarchy relies on soft, diffused ambient light and razor-thin hairline boundaries rather than dramatic z-axis drop shadows. This creates a clean clinical atmosphere reminiscent of organized paper records.

### Elevation Hierarchy
- **Level 0 (Canvas Base):** Background canvas (`#F8FAFC`), entirely flat.
- **Level 1 (Card & Content Blocks):** 
  - Background: `#FFFFFF`
  - Border: 1px solid `#E2E8F0`
  - Shadow: `0 1px 3px 0 rgba(7, 59, 120, 0.03), 0 1px 2px -1px rgba(7, 59, 120, 0.02)`
- **Level 2 (Active Cards & Floating Controls):**
  - Background: `#FFFFFF`
  - Border: 1px solid `#E2E8F0`
  - Shadow: `0 4px 12px -2px rgba(7, 59, 120, 0.06), 0 2px 6px -2px rgba(7, 59, 120, 0.03)`
- **Level 3 (Modals, Overlays & Sticky Sheets):**
  - Background: `#FFFFFF`
  - Shadow: `0 12px 28px -4px rgba(7, 59, 120, 0.10), 0 4px 12px -2px rgba(7, 59, 120, 0.04)`

## Shapes

The geometric architecture balances modern organic touchpoints with steady, dependable card forms.

### Shape Scale
- **Containers & Cards (`rounded-lg` / 16px):** Primary patient summary cards, clinic profile modules, and scheduling dialogs.
- **Interactive Controls (`rounded` / 8px):** Form fields, input dropdowns, and button containers.
- **Status Indicators & Action Chips (`rounded-full` / Pill):** Live telemetry indicators, doctor queue tokens, filter tags, and operational alerts.

## Components

### Buttons
- **Primary:** Filled `#073B78` with `#FFFFFF` text. Height `48px` (Android touch standard). Subtle ripple on touch. Disabled state uses `#E2E8F0` with `#94A3B8` text.
- **Secondary / Accent:** Filled `#E8F8F0` (soft emerald tint) with `#16A36A` text and `#A7F3D0` subtle border. Used for check-in triggers and queue entries.
- **Tertiary / Outlined:** Surface `#FFFFFF`, border 1px `#E2E8F0`, text `#073B78`.

### Live Status Pills
- **Active / Operational:** Compact pill (`rounded-full`, padding `4px 10px`), background `#E8F8F0`, text `#16A36A`, featuring a 6px static or pulsing emerald indicator dot to show real-time clinic queue status.
- **Delayed / Caution:** Background `#FEF3C7`, text `#D97706`, dot `#F59E0B`.
- **Closed / Inactive:** Background `#F1F5F9`, text `#64748B`.

### Cards
- Pure white `#FFFFFF` surface bordered with 1px `#E2E8F0`, with `rounded-lg` (16px) corners.
- Internal padding is strictly `16px` (`space-lg`).
- Divided sections inside cards use hairlines (`#F1F5F9`) rather than heavy structural borders.

### Input Fields
- Height `48px`. Surface `#FFFFFF`, border 1px `#CBD5E1`.
- Focused state: Border transitions to `#073B78` with a 2px outer ambient ring `rgba(7, 59, 120, 0.12)`.
- Labels sit outside the field using `label-md` in `#334155` for high accessibility and clarity.

### Checkboxes & Radios
- Size `20px x 20px`. Border 1.5px `#94A3B8`.
- Selected: Background fills with `#073B78` with a crisp `#FFFFFF` checkmark or inner circular pip.

### Queue & Clinic List Items
- Structured horizontal rows flanked by clinic room labels and doctor meta-information.
- Dividers between list items use `#E2E8F0` inset by 16px to maintain clear line separation without edge crowding.