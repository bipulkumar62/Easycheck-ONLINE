# Firestore Implementation

**Phase:** Task 19 — Firestore Foundation & User Profiles  
**Project:** EasyCheck Online  
**Date:** November 1, 2026

---

## 1. Overview

Firestore is now connected as the backend database for EasyCheck Online. User profiles are stored in the `users` collection with Firebase Auth UID as the document ID.

## 2. Collections

### users

| Field | Type | Description |
|-------|------|-------------|
| uid | string | Firebase Auth UID (document ID) |
| email | string | User's email address |
| displayName | string | Display name |
| photoUrl | string | Profile photo URL |
| role | string | 'patient' or 'clinic_admin' |
| createdAt | timestamp | Account creation time |
| updatedAt | timestamp | Last update time |
| isActive | boolean | Account active status |

## 3. Files Created

| File | Purpose |
|------|---------|
| `lib/features/authentication/user_profile_model.dart` | UserProfile model with toMap/fromDocument |
| `lib/features/authentication/user_profile_repository.dart` | CRUD operations for user profiles |
| `firestore.rules` | Security rules with RBAC |

## 4. Operations

- `getProfile(uid)` — Read user profile by UID
- `createProfile(profile)` — Create new user profile
- `updateProfile(uid, updates)` — Update specific fields
- `profileStream(uid)` — Real-time listener
- `profileExists(uid)` — Check if profile exists

## 5. Security Rules

- Users can only read/write their own profile
- Users cannot change their own role or UID
- Profile creation requires matching UID with auth
