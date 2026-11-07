# Parcha Update Flow

**Phase:** Task 21 — Parcha Update  
**Project:** EasyCheck Online

## Flow

1. Staff taps "+" button on Admin Dashboard
2. `QueueRepository.incrementParcha(clinicId, date, staffUid)` is called
3. Firestore transaction:
   a. Reads current queue session
   b. Validates session is active
   c. Increments currentParchaNumber by 1
   b. Writes updated session
   c. Creates history entry
4. Returns new parcha number
5. Real-time listener updates patient UI

## Concurrency Protection

- Uses `firestore.runTransaction()` for atomicity
- Transaction retries automatically on conflict
- Two staff members incrementing simultaneously will both succeed with sequential numbers
- Duplicate button taps within the same transaction window will result in sequential increments

## Error Handling

- Session not active: Throws AppFailure
- Firebase error: Throws AppFailure with original message
- Network failure: Throws AppFailure
