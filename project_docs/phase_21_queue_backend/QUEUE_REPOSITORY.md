# Queue Repository

**Phase:** Task 21 — Queue Repository  
**Project:** EasyCheck Online

## Class: QueueRepository

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getSession(clinicId, date)` | `Future<QueueSessionModel?>` | Get queue session |
| `getOrCreateTodaySession(clinicId, date)` | `Future<QueueSessionModel>` | Get or create today's session |
| `incrementParcha(clinicId, date, performedBy)` | `Future<int>` | Atomic increment (transaction) |
| `resetParcha(clinicId, date, performedBy)` | `Future<int>` | Reset to 0 (transaction) |
| `getHistory(clinicId, date)` | `Future<List<QueueHistoryEntry>>` | Get history |
| `sessionStream(clinicId, date)` | `Stream<QueueSessionModel?>` | Real-time listener |
| `activeSessionsStream()` | `Stream<List<QueueSessionModel>>>` | All active sessions |
| `updateSessionStatus(clinicId, date, status)` | `Future<void>` | Update session status |

### Concurrency

All counter updates use `firestore.runTransaction()` to ensure atomicity under concurrent access. The transaction:
1. Reads the current session
2. Validates the session is active
3. Computes the new number
4. Writes the updated session
5. Creates a history entry

All within a single transaction, preventing race conditions.
