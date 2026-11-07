# Known Issues & Observations: Admin Screen 03

**Phase:** Phase 13 — Admin UI Implementation  
**Date:** October 31, 2026

---

## 1. Resolved Observations During Implementation

1. **Modal Dialog Icon Well Border Radius:**
   - Stitch specifies `rounded-2xl` (24px) for the red icon container
   - Initial implementation used 14px radius
   - Fixed to 24px to match Stitch design

2. **Modal Dialog Container Border Radius:**
   - Stitch specifies `rounded-3xl` (32px) for the reset dialog
   - Initial implementation used 24px radius
   - Fixed to 32px to match Stitch design

3. **Staff Audit Drawer Top Border Radius:**
   - Stitch specifies `rounded-t-3xl` (32px) for the slide-up drawer
   - Initial implementation used 24px radius
   - Fixed to 32px to match Stitch design

4. **Staff Audit Header Icon Container:**
   - Stitch specifies `rounded-2xl` (24px) radius with `shield_person` icon
   - Initial implementation used 16px radius with `admin_panel_settings` icon
   - Fixed radius to 24px and icon to `shield_rounded`

5. **Backdrop Blur on Modals:**
   - Stitch specifies `backdrop-blur-md` (modal) and `backdrop-blur-sm` (drawer)
   - Initial implementation had no backdrop blur
   - Fixed by wrapping backdrops with `ClipRect` + `BackdropFilter(ImageFilter.blur)`

---

## 2. Deferred Technical Items

1. **Real Firebase Reset Audit Trail:**
   - The reset confirmation dialog shows "Audit logged" toast but does not write to Firestore
   - Deferred to Firebase backend milestone per Task restrictions

2. **Dynamic Staff Identity:**
   - Staff email `reception.apex@easycheck.med` is hardcoded static data
   - Deferred to Firebase Auth integration milestone

3. **Real-time Counter Sync:**
   - Parchi count increment/decrement is local state only
   - Deferred to Cloud Firestore atomic increment milestone

---

## 3. Blocking Issues

- **None.** Admin Screen 03 is fully functional locally and builds cleanly.

---

## 4. Notes

- All fixes applied are visual fidelity corrections only — no redesign of the screen
- Original Stitch files remain unmodified
- No Firebase, authentication, or super-admin functionality added
- Patient screens remain unchanged
