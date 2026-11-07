# Firebase Project Configuration

**Phase:** Task 17 — Firebase Project Setup & Backend Architecture  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Project Identification

| Field | Value |
|-------|-------|
| Project Name | EasyCheck ONLINE |
| Project ID | `easycheck-online` |
| Project Number | `1085858861836` |
| Firebase Console URL | `https://console.firebase.google.com/project/easycheck-online` |
| Firestore Location | `asia-south1` (Mumbai, India) |
| Default Database | `(default)` |

---

## 2. Android Application Configuration

| Field | Value |
|-------|-------|
| Package Name | `com.easycheck.online.easycheck_online` |
| SHA-1 Certificate Fingerprint | `65:B4:62:EA:69:9E:65:F7:20:FF:75:B0:6A:E5:9B:EE:DD:D5:1A:57` |
| SHA-256 Certificate Fingerprint | `79:93:39:19:16:EF:EE:D0:40:9F:1C:8A:D6:B6:1C:AA:54:D8:6D:90:6E:B1:C5:B9:27:69:06:D3:1C:3A:68:70` |
| google-services.json | `android/app/google-services.json` |

---

## 3. Firebase Services Configuration

### 3.1 Firebase Authentication

| Setting | Value |
|---------|-------|
| Providers enabled | Anonymous, Google Sign-In |
| OAuth brand display name | EasyCheck Online |
| Support email | `bipulkumarsiwan6262@gmail.com` |
| Auto-delete anonymous accounts | Not configured (default) |

**Google Sign-In Client IDs:**
- Web Client ID: `1085858861836-4jc9tuhipf15bv0h2cq71530qra11i5g.apps.googleusercontent.com`
- Android Client ID: `1085858861836-oq3b6r9jbblcecv7o269vqk5p2g1ij7e.apps.googleusercontent.com`

### 3.2 Cloud Firestore

| Setting | Value |
|---------|-------|
| Database ID | `(default)` |
| Location | `asia-south1` |
| Rules file | `firestore.rules` |
| Indexes file | `firestore.indexes.json` |
| Current rules mode | Permissive (expires 2026-11-29) — **MUST BE REPLACED** |

### 3.3 Firebase App Check

| Setting | Value |
|---------|-------|
| Status | Not yet configured |
| Recommended provider | Play Integrity (Android) |
| Enforcement | Not enforced yet |

### 3.4 Firebase Cloud Functions

| Setting | Value |
|---------|-------|
| Status | Evaluated — not required for MVP |
| Rationale | All clinic operations can be handled via Firestore Security Rules + client-side atomic increments |

### 3.5 Firebase Storage

| Setting | Value |
|---------|-------|
| Status | Not required |
| Rationale | No file upload requirements in approved scope (doctor photos and clinic logos are referenced via URL, not uploaded) |

### 3.6 Firebase Crashlytics

| Setting | Value |
|---------|-------|
| Status | Planned for production |
| Priority | Low for MVP |

---

## 4. Environment Configuration (`.env`)

All Firebase credentials are stored in `.env` and loaded via `EnvConfig` class:

| Variable | Value | Status |
|----------|-------|--------|
| `FIREBASE_PROJECT_ID` | `easycheck-online` | ✅ Set |
| `FIREBASE_PROJECT_NUMBER` | `1085858861836` | ✅ Set |
| `FIREBASE_STORAGE_BUCKET` | `easycheck-online.firebasestorage.app` | ✅ Set |
| `FIREBASE_ANDROID_APP_ID` | `1:1085858861836:android:f6c366f51fe48bac61ef29` | ✅ Set |
| `FIREBASE_API_KEY` | `AIzaSyDdsNd9BbNjnyVS0p-m-5hMnRf0GYcqGx8` | ✅ Set |
| `GOOGLE_WEB_CLIENT_ID` | `1085858861836-4jc9tuhipf15bv0h2cq71530qra11i5g.apps.googleusercontent.com` | ✅ Set |
| `GOOGLE_ANDROID_CLIENT_ID` | `1085858861836-oq3b6r9jbblcecv7o269vqk5p2g1ij7e.apps.googleusercontent.com` | ✅ Set |

---

## 5. Firebase Console Setup Instructions

If the Firebase project needs to be recreated or verified:

1. **Create Project:**
   - Go to https://console.firebase.google.com/
   - Click "Add Project"
   - Project name: "EasyCheck ONLINE"
   - Disable Google Analytics (not required for MVP)

2. **Register Android App:**
   - Project Settings > General > Your apps > Add app > Android
   - Package name: `com.easycheck.online.easycheck_online`
   - Register app and download `google-services.json`
   - Place at `android/app/google-services.json`

3. **Enable Authentication:**
   - Authentication > Get Started
   - Enable: Anonymous, Google
   - Configure OAuth consent screen with support email

4. **Enable Firestore:**
   - Firestore Database > Create Database
   - Start in test mode (rules will be replaced)
   - Location: `asia-south1`

5. **Generate FlutterFire Config:**
   ```
   flutterfire configure --project easycheck-online
   ```

---

## 6. Services NOT Enabled (Cost Control)

| Service | Reason |
|---------|--------|
| Cloud Functions | Not required for MVP — all operations via Firestore Security Rules + client atomic increments |
| Firebase Storage | No file upload requirements — images referenced via URL |
| Realtime Database | Firestore is sufficient |
| Cloud Messaging | Not in approved scope |
| Remote Config | Not in approved scope |
| Performance Monitoring | Not in approved scope |
