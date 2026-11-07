# Profile Repository

**Phase:** Task 19 — Firestore Foundation  
**Project:** EasyCheck Online

## Class: UserProfileRepository

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getProfile(String uid)` | `Future<UserProfile?>` | Read user profile by UID |
| `createProfile(UserProfile profile)` | `Future<void>` | Create new profile |
| `updateProfile(String uid, Map updates)` | `Future<void>` | Update specific fields |
| `profileStream(String uid)` | `Stream<UserProfile?>` | Real-time listener |
| `profileExists(String uid)` | `Future<bool>` | Check if profile exists |

### Error Handling

All methods throw `AppFailure` on Firebase errors with the original Firebase error message.

### Usage Example

```dart
final repo = UserProfileRepository();
final profile = await repo.getProfile(currentUser.uid);
if (profile == null) {
  await repo.createProfile(UserProfile(...));
}
```
