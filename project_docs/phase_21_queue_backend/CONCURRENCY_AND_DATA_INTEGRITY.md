# Concurrency & Data Integrity

**Phase:** Task 21 — Concurrency  
**Project:** EasyCheck Online

## Concurrency Control

All counter updates use `firestore.runTransaction()`:

```
Transaction Steps:
1. Read current queue session document
2. Validate session is active
3. Compute new parcha number (current + 1)
4. Write updated session within transaction
5. Create history entry within same transaction
```

## Guarantees

- **No lost updates**: If two staff increment simultaneously, both succeed with sequential numbers
- **No negative numbers**: Transaction validates currentParchaNumber >= 0 before decrement
- **No duplicate updates**: Each transaction reads latest state before writing
- **Atomic history**: History entry is created in same transaction as counter update

## Duplicate Tap Protection

- Rapid successive taps each create a separate transaction
- Each transaction reads the latest state, so numbers increment sequentially
- No double-counting or skipped numbers
