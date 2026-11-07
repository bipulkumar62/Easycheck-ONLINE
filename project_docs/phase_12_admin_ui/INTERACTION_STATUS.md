# Interaction Status: Admin Screen 02 (Clinic Admin Dashboard)

**Phase:** Phase 12 — Admin UI Implementation  
**Screen Target:** Screen A-02 (Clinic Admin Dashboard)

---

## 1. Prototype Interactions Implemented

1. **Parchi Counter Increment (`_increment()`):**
   - **Trigger:** Tap on giant 64x64 emerald `+` button (`#counter-increment`).
   - **Action:** Increments `_parchiCount` by 1, updates sequence tag (`Seq: P-xxx`), triggers scale animation on display number, pulses `"PARCHI ISSUED"` label.
   - **Toast Feedback:** Displays floating toast `"Parchi issued • Seq P-xxx"`.
   - **Source Reference:** Matches JavaScript lines 205–216 of `clinic_admin_dashboard/code.html`.

2. **Parchi Counter Decrement (`_decrement()`):**
   - **Trigger:** Tap on 64x64 white `-` button (`#counter-decrement`).
   - **Action:** Decrements `_parchiCount` by 1 down to minimum 0 (disabled when count is 0).
   - **Toast Feedback:** Displays floating toast `"Parchi count updated to x"`.
   - **Source Reference:** Matches JavaScript lines 218–226 of `clinic_admin_dashboard/code.html`.

3. **Doctor Availability Selector (`_setDoctorStatus()`):**
   - **Trigger:** Tap on `"Available"`, `"Delayed"`, or `"Off-Duty"` button.
   - **Action:** Switches active border and container fill styling, sets saving state spinner for 1200ms, and updates online status pill.
   - **Toast Feedback:** Displays floating toast `"Saved to Firebase • Updated just now"`.
   - **Source Reference:** Matches JavaScript lines 242–260 of `clinic_admin_dashboard/code.html`.

4. **Reset Counter Dialog Flow (`_triggerReset()` & `_confirmReset()`):**
   - **Trigger:** Tap on `"Reset count to 0"` link.
   - **Action:** Opens the `#modal-reset` confirmation dialog.
   - **Confirmation:** Confirms permanent reset, resets count to 0, updates sequence to `P-000`, and displays toast `"Count reset to 0 • Audit logged"`.
   - **Dismissal:** Tapping `"Cancel"` dismisses the modal without altering the count.
   - **Source Reference:** Matches JavaScript lines 228–240 of `clinic_admin_dashboard/code.html`.

5. **Staff Profile Popover & Shift Logout:**
   - **Trigger:** Tap on staff avatar button in top app bar or context card.
   - **Action:** Toggles floating popover `#account-popover` displaying staff email and Clinic ID `CLN-84920`.
   - **Logout Modal:** Tapping `"Log out session"` reveals the `#modal-logout` confirmation dialog.
   - **Shift Exit:** Tapping `"Log out of Reception"` redirects to `/admin/login`.
   - **Dismissal:** Tapping outside the popover or tapping `"Stay signed in"` dismisses the modal.
   - **Source Reference:** Matches JavaScript lines 262–285 of `clinic_admin_dashboard/code.html`.

6. **Tab Navigation:**
   - Tapping the 4th tab (`Clinic`) navigates to `/admin/reset-studio` ([AdminResetStudioScreen](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_reset_studio_screen.dart)).

---

## 2. Backend Dependencies (Deferred to Firebase Milestone)

| Interaction | Frontend State Implemented | Backend Dependency |
| :--- | :--- | :--- |
| **Real-time Counter Increment** | Local state + sequence tag formatting | Cloud Firestore Atomic Increment: `FieldValue.increment(1)` on `clinics/{id}` |
| **Audit Ledger on Reset** | Local reset to 0 with confirmation dialog | Cloud Firestore batch write appending to `audit_logs/{id}` subcollection |
| **Doctor Availability Stream** | Local status state with 1200ms simulated saving | Cloud Firestore Document update: `clinics/{id}.update({'doctor.status': status})` |
| **Staff Profile Identity** | Static Reception Apex data model | Firebase Auth user profile claims and assigned clinic metadata |
