# Daily Reset Architecture

**Phase:** Task 21 — Daily Reset  
**Project:** EasyCheck Online

## Flow

1. Staff taps "Reset count to 0" on Admin Dashboard
2. Confirmation dialog appears
3. Staff confirms reset
4. `QueueRepository.resetParcha(clinicId, date, staffUid)` is called
5. Firestore transaction:
   a. Reads current session
   b. Archives current count to queue_history
   c. Sets currentParchaNumber to 0
   d. Updates session
6. Returns 0
7. Real-time listener updates patient UI

## Rules

- New day starts with parcha number 0
- Previous day's final number is preserved in queue_history
- Old sessions are not overwritten
- Only staff with `reset_tally` permission can reset
- Repeated resets create new history entries
- Uses clinic's configured timezone for date
