# Known Issues & Observations: Patient Screen 01

**Screen:** Patient Screen 01 (Google Login Screen)  
**Phase:** Phase 04 — Patient UI Implementation

---

## 1. Resolved Issues During Implementation

1. **Screen Overflow on Small Mobile Dimensions:**
   - **Observation:** On smaller devices (e.g. 320x568 dp or 360x640 dp), fixed spacers caused a vertical RenderFlex overflow.
   - **Resolution:** Wrapped screen content in `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight))` with `ClampingScrollPhysics`. This ensures content occupies the full height on tall screens while scrolling naturally without clipping or overflowing on compact devices.

2. **Vector Google "G" Icon Quality:**
   - **Observation:** Standard bitmap icons can blur on high-DPI displays.
   - **Resolution:** Implemented `_GoogleLogoPainter` using precision canvas painting with exact Google brand colors (`#4285F4`, `#34A853`, `#FBBC05`, `#EA4335`) guaranteeing crisp rendering at any device pixel ratio.

3. **Status Pill Label Contrast:**
   - **Observation:** Original HTML had `text-on-secondary-container` (`#007147`).
   - **Resolution:** Bound directly to `PatientColors.onSecondaryContainer` for WCAG AA compliance.

---

## 2. Unresolved / Deferred Items

1. **Live Firebase Authentication Exchange:**
   - Real Firebase Auth (`FirebaseAuth.instance.signInWithCredential`) is deferred to the integration phase as strictly requested in Task 04 rules ("Do not connect Firebase", "Implement only one patient screen").
2. **Dynamic Legal URL Navigation:**
   - Privacy Policy and Terms of Service currently display local Clinical Clarity modal bottom sheets. Production web URL launching (via `url_launcher`) can be added when live hosting URLs are defined.
