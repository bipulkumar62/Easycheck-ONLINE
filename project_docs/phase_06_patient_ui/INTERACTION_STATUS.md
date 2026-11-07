# Interaction Status: Clinic Details & Live Parchi Screen

**Phase:** Phase 06 — Patient Screen 03 Implementation  
**Screen:** Patient Screen 03 (Clinic Details & Live Parchi Screen)

---

## 1. Prototype Interactions Implemented

1. **Back Navigation:**
   - **Trigger:** Tap on the top left circular `arrow_back` button.
   - **Action:** Calls `Navigator.of(context).pop()` to return seamlessly to the Home / Discovery screen (`/patient/home`).
   - **Verification:** Preserves previous scroll position and search filter on the Home screen.

2. **Sync State Simulation Toggle:**
   - **Trigger:** Tap on the `"Simulate Syncing"` / `"Show Synced (42)"` chip (`#toggle-sync-state` in original prototype).
   - **Action:** Toggles between:
     - **Active Synced State:** Giant number displays `"42"` in `primary` blue, Today comparison box displays `"42"`, toggle button label reads `"Simulate Syncing"`.
     - **Syncing / Disconnected State:** Giant number displays `"—"` in muted `outline` grey, Today comparison box displays `"—"`, toggle button label reads `"Show Synced (42)"` with smooth icon rotation animation.
   - **Source Reference:** Matches JavaScript lines 135–159 of `clinic_details_easycheck_online/code.html`.

3. **Live Pulse Indicators:**
   - **Trigger:** Continuous animation loop on mount.
   - **Locations:**
     1. Doctor availability pill (`"Currently Available"`).
     2. Realtime ping subtitle in the counter display well (`"Real-time synchronization connected · Updated 2 mins ago"`).

4. **Smooth Inertial Scrolling:**
   - **Trigger:** Vertical swipe gesture.
   - **Behavior:** `CustomScrollView` with `ClampingScrollPhysics` smoothly scrolls cards behind the fixed frosted app bar without content jumping or clipping.

---

## 2. Backend-Dependent Interactions (Documented Limitations)

| Interaction | Frontend State Implemented | Backend Dependency | Status / Next Step |
| :--- | :--- | :--- | :--- |
| **Real-time Counter Sync** | Interactive toggle simulation between `"42"` and `"—"` | Firestore Realtime Document Snapshot Listener (`clinics/{id}`) | Hook during Firestore real-time integration phase |
| **Doctor Availability State** | Static chip with `LivePulseDot` (`"Currently Available"`) | Doctor check-in status stream from Admin shift controls | Hook during Admin-Patient synchronization phase |
| **Dynamic Clinic Routing** | Accepts `ClinicModel` parameter with fallback to Dr. Rajesh Kumar | Dynamic route arguments passing from Home card clicks | Ready and configured in `app_routes.dart` |
