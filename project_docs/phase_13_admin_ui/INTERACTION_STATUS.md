# Interaction Status: Admin Screen 03 (Reset Confirmation & Account State Studio)

**Phase:** Phase 13 — Admin UI Implementation  
**Screen Target:** Screen A-03 (Reset Confirmation & Account State Studio)

---

## 1. Prototype Interactions Implemented

### 1.1 Scenario Selector Toolbar (_selectScenario())
| Tab | Trigger | Action | Source Reference |
|-----|---------|--------|------------------|
| **Reset Dialog** | Tap toolbar button | Switches to reset modal view; shows reset dialog over dimmed underlay | `openModal()` / `setTabState(btnShowModal)` |
| **Feedback** | Tap toolbar button | Displays feedback toast overlay with dynamic title/subtitle | `triggerToasts()` / `setTabState(btnShowToast)` |
| **Staff Audit** | Tap toolbar button | Opens slide-up staff audit drawer from bottom | `openDrawer()` / `setTabState(btnShowDrawer)` |

### 1.2 Reset Confirmation Flow
| Interaction | Trigger | Action | Toast Feedback |
|-------------|---------|--------|----------------|
| Open Reset Dialog | Tap "Reset Dialog" tab or "Reset Tally" button | Shows centered modal with warning icon and confirmation text | None |
| Confirm Reset | Tap "Confirm Reset to 0" (52px error button) | Resets `_parchiCount` to 0; switches scenario to feedback; closes modal | `"Parchi tally reset to 0"` + `"Audit logged: reception.apex@easycheck.med"` |
| Cancel Reset | Tap "Cancel" (48px secondary button) | Dismisses modal; switches scenario to feedback | None |

### 1.3 Feedback Toast Overlay
| Interaction | Trigger | Content |
|-------------|---------|---------|
| Feedback Toast | Tap "Feedback" tab | Title: `"Parchi counter incremented to X"`, Subtitle: `"Sync confirmed with Apex Cloud Ledger"` |
| Reset Confirmation Toast | Confirm Reset action | Title: `"Parchi tally reset to 0"`, Subtitle: `"Audit logged: reception.apex@easycheck.med"` |
| Quick Increment | Tap "Issue Next (13)" button | Increments count by 1; updates button label; shows increment toast |

### 1.4 Staff Audit Drawer
| Interaction | Trigger | Action |
|-------------|---------|--------|
| Open Drawer | Tap "Staff Audit" tab | Slide-up bottom sheet with staff identity, audit metadata, quick actions, logout |
| Close Drawer | Tap backdrop or "Close Panel" | Dismisses drawer; switches scenario to feedback |
| Logout Terminal | Tap "Log out of Apex Terminal" | Redirects to `/admin/login` |
| Audit Activity Card | Tap card | Displays "View 18 shift actions" (no-op, informational only) |
| Reprint Slip Card | Tap card | Displays "Bluetooth Desk Printer" (no-op, informational only) |

### 1.5 Tab Navigation
- Tapping "Live Queue" tab navigates to `/admin/dashboard`
- Tapping "Clinic" tab stays on reset studio (already active)

---

## 2. Backend Dependencies (Deferred to Firebase Milestone)

| Interaction | Frontend State Implemented | Backend Dependency |
|-------------|--------------------------|-------------------|
| **Parchi Count Reset** | Local state reset to 0 with two-step confirmation | Cloud Firestore batch write to `audit_logs/` subcollection |
| **Daily Reset Permissions** | Static `"Granted (Lead Tier)"` display | Firestore role-based access control |
| **Audit Activity** | Static `"View 18 shift actions"` display | Real-time audit ledger collection |
| **Staff Identity** | Static `reception.apex@easycheck.med` | Firebase Auth user profile claims |

---

## 3. Honest State Handling

- **No fabricated backend success:** All toast messages are labeled as simulation/feedback only
- **No Firebase connection:** No Firestore reads/writes for reset operations
- **No fake database responses:** Counter increment/decrement is purely local state
- **Two-step confirmation for destructive actions:** Reset requires explicit "Confirm Reset to 0" tap
