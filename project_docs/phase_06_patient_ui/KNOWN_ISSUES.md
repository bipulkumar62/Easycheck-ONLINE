# Known Issues & Observations: Patient Screen 03

**Screen:** Patient Screen 03 (Clinic Details & Live Parchi Screen)  
**Phase:** Phase 06 — Patient Screen 03 Implementation

---

## 1. Resolved Issues During Implementation

1. **Backdrop Blur for Fixed Header:**
   - **Observation:** In the Stitch prototype, the header has `bg-surface/80` with `backdrop-blur-xl`.
   - **Resolution:** Encapsulated the fixed top bar in `ClipRect` with `BackdropFilter(filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0))`, ensuring content scrolling underneath creates the authentic frosted clinical glass aesthetic.

2. **Ambient Decorative Background Accent:**
   - **Observation:** In `code.html` line 7, the doctor card has an ambient circle: `absolute -right-10 -bottom-10 w-40 h-40 bg-surface-container-low rounded-full opacity-60 pointer-events-none`.
   - **Resolution:** Positioned a 160x160 circular container inside the doctor card stack behind content, accurately matching the visual depth of the Stitch card.

3. **Sync Simulation State Toggle:**
   - **Observation:** Original prototype JS toggles both the giant counter display and the today comparison box between `"42"` and `"—"`, and toggles button label between `"Simulate Syncing"` and `"Show Synced (42)"`.
   - **Resolution:** Fully wired the stateful toggle into `_ClinicDetailsScreenState` with rotation animation on the sync icon.

---

## 2. Documented Deferred Items

1. **Live Firestore Stream Subscription:**
   - Live parchi counts currently use prototype initial data (`42`). Real-time document updates via `FirebaseFirestore.instance.collection('clinics')` are deferred to the backend integration phase per project roadmap.
2. **Dynamic Route Parameter Fallback:**
   - When opened via direct deep link without explicit arguments, the screen falls back gracefully to `sampleClinics.first` (Dr. Rajesh Kumar / Al-Shifa Family Health Clinic).
