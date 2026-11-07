# Interaction Status: Patient Google Login Screen

**Phase:** Phase 04 — Patient UI Implementation  
**Screen:** Patient Screen 01 (Google Login Screen)

---

## 1. Prototype Interactions Implemented

1. **Google Sign-In Button Feedback:**
   - **Trigger:** Tap on `"Continue with Google"`.
   - **Tactile Response:** Button opacity temporarily decreases to `0.85` for tactile feedback and displays a subtle loading indicator.
   - **Navigation Action:** Transitions to `/patient/home` (Patient Home / Discovery Screen).

2. **Live Pulse Dot Indicator:**
   - **Trigger:** Automatic continuous loop on render.
   - **Animation:** Expanding outer ring (scale `1.0` -> `2.4`, opacity `0.6` -> `0.0` over 1200ms) with persistent solid green core dot.
   - **Purpose:** Indicates live connection to clinic desks.

3. **Privacy Policy Link:**
   - **Trigger:** Tap on `"Privacy Policy"`.
   - **Action:** Opens a Clinical Clarity bottom modal sheet displaying the privacy policy terms, encryption details, and close action.

4. **Terms of Service Link:**
   - **Trigger:** Tap on `"Terms of Service"`.
   - **Action:** Opens a Clinical Clarity bottom modal sheet displaying terms of service, medical disclaimer, and close action.

5. **Scroll & Safe Area Handling:**
   - **Behavior:** On small screens or orientation changes, the content smoothly scrolls with `ClampingScrollPhysics` and preserves bottom padding.

---

## 2. Backend-Dependent Interactions (Documented Limitations)

| Interaction | Frontend State Implemented | Backend Dependency | Status / Next Step |
| :--- | :--- | :--- | :--- |
| **Real Google OAuth** | Tactile loading animation + navigation to `/patient/home` | `google_sign_in` / `firebase_auth` OAuth credential exchange | Hook during backend integration phase |
| **User Profile Sync** | Local avatar display and guest session handling | Firestore `users` collection document creation/update | Hook during backend integration phase |
| **Live Desks Count** | Static count label (`"Live Clinic Desks Active"`) | Firestore live listener for active clinic desks | Hook during real-time data phase |
