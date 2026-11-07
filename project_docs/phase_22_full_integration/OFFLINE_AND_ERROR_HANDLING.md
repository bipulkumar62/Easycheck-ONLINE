# Offline and Error Handling

**Phase:** Task 22 — Full Integration  
**Project:** EasyCheck Online  
**Date:** November 1, 2026

## Offline Handling

| Aspect | Implementation |
|--------|---------------|
| Firestore local cache | Firestore SDK caches data locally for offline access |
| Reads when offline | Returns cached data when offline |
| Writes when offline | Queued and synced when connection returns |
| UI during network operations | Loading states shown |

## Error Handling

| Error Type | User-Facing Behavior | Logging |
|------------|---------------------|---------|
| Network failure | Error message shown | `debugPrint` |
| Permission denied | Access denied message | `debugPrint` |
| Missing clinic data | Empty state shown | `debugPrint` |
| Invalid clinic ID | Error message shown | `debugPrint` |
| Duplicate update | Sequential numbering | None (handled by transaction) |

## No False Success

- No operation displays success until Firestore confirms write
- Loading states shown during all async operations
- Error states shown on failure
- Retry available for failed operations

## FirebaseException Handling

All Firestore operations are wrapped in try-catch blocks that catch `FirebaseException` and throw `ServerFailure` with a descriptive message:

```dart
} on FirebaseException catch (e) {
  throw ServerFailure(e.message ?? 'Failed to get clinic');
}
```
