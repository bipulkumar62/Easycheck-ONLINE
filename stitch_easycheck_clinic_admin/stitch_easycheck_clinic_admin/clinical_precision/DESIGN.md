---
name: Clinical Precision
colors:
  surface: '#f8f9ff'
  surface-dim: '#ccdbf3'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e6eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d5e3fc'
  on-surface: '#0d1c2e'
  on-surface-variant: '#3d4a41'
  inverse-surface: '#233144'
  inverse-on-surface: '#eaf1ff'
  outline: '#6d7a70'
  outline-variant: '#bccabf'
  surface-tint: '#006d44'
  primary: '#006a42'
  on-primary: '#ffffff'
  primary-container: '#008655'
  on-primary-container: '#f6fff6'
  inverse-primary: '#62dd9e'
  secondary: '#375e9d'
  on-secondary: '#ffffff'
  secondary-container: '#94b9fe'
  on-secondary-container: '#1d4886'
  tertiary: '#535f59'
  on-tertiary: '#ffffff'
  tertiary-container: '#6b7771'
  on-tertiary-container: '#f5fff8'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#80fab9'
  primary-fixed-dim: '#62dd9e'
  on-primary-fixed: '#002111'
  on-primary-fixed-variant: '#005232'
  secondary-fixed: '#d7e3ff'
  secondary-fixed-dim: '#aac7ff'
  on-secondary-fixed: '#001b3e'
  on-secondary-fixed-variant: '#1a4683'
  tertiary-fixed: '#d9e6de'
  tertiary-fixed-dim: '#bdcac2'
  on-tertiary-fixed: '#131e19'
  on-tertiary-fixed-variant: '#3e4944'
  background: '#f8f9ff'
  on-background: '#0d1c2e'
  surface-variant: '#d5e3fc'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: 0em
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
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  gutter-desktop: 2rem
  margin: 1rem
  margin-tablet: 1.5rem
  margin-desktop: 2.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an ultra-refined, high-focus mobile operating environment tailored for clinic operations, triage coordinators, and administrative practitioners. The emotional goal is immediate clinical composure: clarity without sterile coldness, rapid triage without cognitive strain, and high-velocity workflow execution on mobile handhelds.

The aesthetic fuses **Precision Minimalism** with **Restrained Soft Glassmorphism**. Extraneous decorative elements, generic dashboards, vanity metrics, and marketing detritus are eliminated. Every viewport pixel serves operational throughput: patient intake status, practitioner assignment, real-time queues, and alert resolution. 

Key attributes:
- **Zero Fluff**: Data-dense yet uncluttered layouts built for scanning under ambient clinical lighting.
- **Ergonomic Authority**: Action targets calibrated for rapid one-handed thumb entry on mobile devices (48px–64px tap bounds).
- **Subtle Modernity**: Pure off-white foundations layered with crisp, translucent structural borders, gentle emerald confirmations, and deep navy structural anchors.

## Colors

The palette establishes high semantic rigor to maintain legibility during fast-paced clinical shifts. It prioritizes contrast ratios that exceed WCAG AAA standards for critical legibility.

### Primary & Action
- **Primary Emerald (`#16A36A`)**: Primary positive actions, check-ins, validation, live queue states, active patient confirmations.
- **Surface Emerald Tint (`#EAF7EF`)**: Active pill backgrounds, subtle highlights, focus halos, validated state cards.

### Authority & Hierarchy
- **Deep Navy (`#073B78`)**: Primary text, structural navigation bars, active counters, critical data points. Ensures authoritative weight without relying on stark `#000000`.
- **Secondary Slate (`#475569`)**: Secondary labels, metadata, patient sub-identifiers, time stamps.
- **Muted Slate (`#64748B`)**: Supporting helper labels, disabled states, unselected icons.

### Surface & Canvas
- **Base Canvas (`#F8FAFC`)**: Soft cool off-white canvas that minimizes screen glare across prolonged screen shifts.
- **Pure Surface (`#FFFFFF`)**: Card surfaces, modal sheets, floating utility rails.
- **Border Stroke (`#E2E8F0`)**: Structural boundary lines.
- **Glass Stroke Overlay (`rgba(203, 213, 225, 0.8)`)**: Translucent surface containment lines for elevated sheets.

### Status Semantics
- **Warning Amber (`#D97706`)** with **Warning Tint (`#FEF3C7`)**: Delayed check-ins, triage queues pending physician review.
- **Danger Red (`#DC2626`)** with **Danger Tint (`#FEE2E2`)**: Room unavailable, emergency reassignment, missed appointment, hard blocks.

## Typography

The type scale combines **Plus Jakarta Sans** for headlines and high-priority numeric data with **Inter** for dense transactional labels and body copy. 

- **Display & Numerical Indicators**: Plus Jakarta Sans provides refined geometric curves with wide counters, making patient triage numbers, queue counts, and timestamps instant to register.
- **Transactional Precision**: Inter manages all clinical notes, intake histories, and field descriptors to eliminate letterform confusion under high operational loads.
- **Tabular Numerics**: Apply `font-feature-settings: "tnum"` to all timestamps, room identifiers, and queue counters to prevent jitter in live-updating queues.

## Layout & Spacing

A strictly thumb-driven, mobile-first grid governs this system. 

### Breakpoints & Grid Structure
- **Mobile (< 640px)**: Single-column fluid view with `1rem` outer canvas margin. Critical operational triggers, primary actions, and filters anchor directly to the viewport thumb zone (bottom 35% of the mobile frame).
- **Tablet / Clinic Station (640px - 1024px)**: 6-column fluid grid, `1.5rem` gutters. Splits queue management and detail views side-by-side.
- **Desktop (> 1024px)**: 12-column fixed grid (max-width `1280px`), `2rem` gutters. Centered console layout for central reception stations.

### Spatial Hygiene
- Components maintain clear physical separation to avoid mistaps during urgent operations.
- Patient queue list items enforce `space-md` gaps.
- Action strips pinned to mobile bottom safe areas leverage `space-lg` internal padding with zero lateral leakage.

## Elevation & Depth

Visual hierarchy uses **tonal surfaces** and **whisper-soft ambient diffusion** rather than heavy drop shadows. Glassmorphism is restrained to structural overlays, maintaining 99% surface opacity for accessibility.

- **Level 0 (Base)**: Flat canvas (`#F8FAFC`). No shadow.
- **Level 1 (Clinical Cards & Rows)**: Pure white background (`#FFFFFF`), outlined by `1px solid rgba(226, 232, 240, 0.8)`. Soft ambient elevation: `0 1px 3px rgba(7, 59, 120, 0.03), 0 6px 12px -2px rgba(7, 59, 120, 0.04)`.
- **Level 2 (Interactive Floating Sheets & Drawers)**: Pure white background with `backdrop-filter: blur(12px)`, bordered by `1px solid rgba(203, 213, 225, 0.8)`. Elevation: `0 8px 24px -4px rgba(7, 59, 120, 0.08)`.
- **Level 3 (Modal Alerts & Overrides)**: `#FFFFFF`, `0 20px 40px -8px rgba(7, 59, 120, 0.16)`, bordered with crisp `#CBD5E1`.

All shadows use Deep Navy tinting (`#073B78`) rather than neutral pitch black, keeping elevated cards clean and clinically modern.

## Shapes

The design uses a friendly yet precise curve philosophy:
- **Base Components (Inputs, Small Badges)**: `rounded-xl` (12px / 0.75rem) maintains structural containment without turning childishly round.
- **Containers & Clinical Cards**: `rounded-2xl` (16px / 1rem) to `rounded-3xl` (24px / 1.5rem) provide clean, calming boundaries that prevent visual tension.
- **Interactive Action Buttons & State Chips**: Pill-shaped or soft-rectilinear (`rounded-2xl`) for effortless thumb targeting.

## Components

### Buttons & Primary Operational Actions
- **Height**: Minimum 48px for secondary tools; 56px to 64px for primary mobile dispatch buttons (e.g., "Admit Patient", "Confirm Check-In").
- **Primary Positive Button**: Solid `#16A36A`, high-contrast white text (`#FFFFFF`), `font-weight: 600`, shape `rounded-2xl`. Active state triggers subtle scale down (`scale: 0.98`) with zero lag.
- **Secondary Authority Button**: Background `#FFFFFF`, border `1px solid #E2E8F0`, Deep Navy text (`#073B78`).
- **Emergency Override Button**: `#FEE2E2` background, `#DC2626` text, border `1px solid rgba(220, 38, 38, 0.2)`.

### Operational Cards (Patient Queue Item)
- **Container**: `#FFFFFF` background, `border: 1px solid rgba(226, 232, 240, 0.8)`, `rounded-2xl`, internal padding `1.25rem`.
- **Left Status Indicator**: Solid 4px lateral border pill directly mapping to triage state (Emerald `#16A36A`, Amber `#D97706`, Red `#DC2626`).
- **Typography Layout**: Deep Navy for patient name and ID, Slate `#64748B` for wait-time metadata, paired with tabular Plus Jakarta Sans figures.

### Status Chips & Badges
- **Shape**: `rounded-full`, padding `4px 12px`.
- **Verified / Arrived**: Background `#EAF7EF`, Text `#16A36A`, dot pulse indicator.
- **Delayed**: Background `#FEF3C7`, Text `#D97706`.
- **Unavailable / Cancelled**: Background `#FEE2E2`, Text `#DC2626`.
- **Font**: Inter Label-Sm (`11px`, bold, uppercase, `letterSpacing: 0.04em`).

### Input Fields & Triage Selectors
- **Height**: 52px minimum.
- **Surface**: Pure White (`#FFFFFF`), border `1.5px solid #E2E8F0`, placeholder text `#94A3B8`.
- **Focus State**: Border `#16A36A`, outer soft halo `0 0 0 3px #EAF7EF`.
- **Labeling**: Sticky floating or persistent high-contrast label in `#073B78` (Inter Label-Md).

### Sticky Bottom Workflow Bar (Mobile-Only)
- Pinned bottom bar wrapped in `backdrop-filter: blur(16px)`, background `rgba(255, 255, 255, 0.92)`, bordered top `1px solid #E2E8F0`.
- Houses dual actions: Large 56px Primary Action (65% width) + Rapid Secondary Action (35% width) for one-handed operation.