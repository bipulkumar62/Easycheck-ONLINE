# Doctor Timing Integration

**Project:** EasyCheck Online  
**Phase:** Task 23  
**Date:** November 5, 2026

---

## 1. Requirement

The clinic admin must be able to enter doctor/clinic timing manually in the admin dashboard, and that exact text must appear on the patient side (patient home clinic cards and clinic details).

No hardcoded timing may override the admin’s value.

---

## 2. Data Model

Field: `doctorTiming` on `clinics/{clinicId}`.

| Property | Value |
|----------|-------|
| Type | string |
| Example | `Mon–Sat · 9:00 AM – 5:00 PM` |
| Maximum input | 80 characters |
| Empty value | Allowed; patient UI hides the timing row |
| Backward compatibility | Missing field parses to empty string |

### 2.1 `lib/features/clinics/clinic_model.dart`

- Added `final String doctorTiming`.
- Parsed with `data['doctorTiming'] as String? ?? ''`.
- Serialized in `toMap()`.
- Supported in `copyWith(doctorTiming: ...)`.
- Passed to `toDisplayModel()` as `DoctorModel.timing`.

### 2.2 Display model

`lib/shared/models/clinic_model.dart` already exposes `DoctorModel.timing`. The Firestore model now supplies the admin-entered value instead of a hardcoded string.

---

## 3. Admin Dashboard

### 3.1 Entry point

On the clinic card in `AdminDashboardScreen`, the doctor timing row is tappable while the dashboard is not busy.

- Row label: `Doctor timing` / clinic hours.
- If empty: shows a prompt to add timing.
- Tapping opens the editor dialog.

### 3.2 Editor dialog

`_editDoctorTiming`:

- Text field prefilled with the current value.
- Label: `Clinic hours`.
- Hint: `Mon–Sat · 9:00 AM – 5:00 PM`.
- Helper: `This text is shown to patients on the clinic screen.`
- `maxLength: 80`.
- Actions: **Cancel** and **Save timing**.
- Input is trimmed before saving.

### 3.3 Save

`_saveDoctorTiming`:

```dart
await _clinicRepository.updateClinic(clinic.clinicId, {
  'doctorTiming': timing,
});
```

- Updates only the `doctorTiming` field.
- Updates the in-memory clinic with `copyWith`.
- Shows `Doctor timing updated for patients.` on success.
- Shows `Doctor timing cleared.` when the value is empty.
- Shows a real error message on failure.
- Prevents concurrent saves with the existing `_busy` guard.

The Firestore update is authorized by the existing clinic update rule: the caller must be `clinics.adminUid` or an active `clinic_admin`, and `adminUid` must not change.

---

## 4. Patient Side

### 4.1 Patient home clinic card

`lib/features/patient/patient_home_screen.dart` renders the timing only when non-empty:

```dart
if (clinic.doctorTiming.trim().isNotEmpty) ...[
  // schedule icon + clinic.doctorTiming
]
```

This keeps cards compact for clinics that have not entered timing.

### 4.2 Clinic details

`lib/features/clinic/clinic_details_screen.dart` renders the timing under the doctor specialty when non-empty, with a schedule icon and the patient secondary color.

### 4.3 Live updates

Patient home listens to the active clinics stream, so a saved timing reaches the patient UI through the existing real-time Firestore listener. No app restart is required.

---

## 5. Seed Data

The three seeded clinics now contain:

| Clinic | Doctor timing |
|--------|---------------|
| `CLN-84920` — Al-Shifa Family Health Clinic | Mon–Sat · 9:00 AM – 5:00 PM |
| `CLN-84921` — Crescent Memorial Hospital | Mon–Fri · 10:00 AM – 6:00 PM |
| `CLN-84922` — St. Jude Community Medicare | Mon–Sat · 8:30 AM – 2:00 PM |

### 5.1 Unicode handling

PowerShell 5.1 corrupted the en dash and middle dot when the patch script was authored with literal characters. The documents were rewritten using explicit code points:

- En dash: `[char]0x2013`
- Middle dot: `[char]0x00B7`

The stored values were verified by character-code inspection:

- `Mon–Sat · 9:00 AM – 5:00 PM`
- `Mon–Fri · 10:00 AM – 6:00 PM`
- `Mon–Sat · 8:30 AM – 2:00 PM`

### 5.2 Seed script

`tools/seed_firestore.ps1` now uses ASCII timing strings (`Mon-Sat, 9:00 AM - 5:00 PM`) to avoid encoding corruption on future re-seeds. Admins can replace them with typographic characters through the dashboard editor.

---

## 6. Tests

`test/clinic_model_test.dart`:

1. Parses and round-trips `doctorTiming`.
2. Tolerates missing timing for older documents.
3. Passes timing and doctor status into the patient display model.

`test/widget_test.dart`:

4. Clinic details renders `Mon–Sat · 9:00 AM – 5:00 PM` from the model.

All tests pass (see `TEST_REPORT.md`).

---

## 7. Manual Verification Steps

1. Sign in as an authorized clinic admin.
2. Open the admin dashboard.
3. Tap the doctor timing row.
4. Enter a new value and tap **Save timing**.
5. Confirm the success message.
6. Open the patient home on a patient account.
7. Confirm the clinic card shows the new text.
8. Open clinic details and confirm the same text appears under the doctor specialty.
9. Clear the timing in admin and confirm the patient row disappears.

Manual verification requires a provisioned clinic admin account; see `KNOWN_ISSUES.md`.
