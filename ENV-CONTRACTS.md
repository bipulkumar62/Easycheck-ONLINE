# ENV-CONTRACTS.md — EasyCheck Online Environment & Secrets Contract

## 1. Project Overview

- **Application Name:** EasyCheck Online (`easycheck_online`)
- **System Purpose:** Real-time outpatient & clinic parchi queue tracking mobile application.
- **Framework & Language:** Flutter (SDK `^3.13.0`) / Dart (SDK `^3.5.0` or higher).
- **Backend Architecture:** Serverless BaaS via Google Firebase (Cloud Firestore, Firebase Authentication with Google Sign-In, Firebase Hosting).
- **Primary Deployment Target:** Android APK / App Bundle (`com.easycheck.online.easycheck_online`), with Firebase Web Hosting configuration for SPA deployment.
- **Configuration Pattern:** Hybrid configuration utilizing `flutter_dotenv` runtime asset loading (`.env`), Dart compile-time flags (`--dart-define`), native Android Gradle configurations (`google-services.json`, `key.properties`, `local.properties`), and Firebase CLI specifications (`firebase.json`, `.firebaserc`).

---

## 2. Environment Configuration Architecture

The configuration pipeline is structured across four distinct layers:

```
[ Developer / CI/CD ]
       │
       ├─► .env (bundled as asset in pubspec.yaml)
       │         │
       │         └─► flutter_dotenv (dotenv.load at runtime)
       │                   │
       ├─► --dart-define   │
       │         │         ▼
       │         └─► String.fromEnvironment (compile-time fallback)
       │                   │
       │                   ▼
       │         lib/core/config/env_config.dart (EnvConfig getters)
       │
       ├─► android/app/google-services.json ──► Google Services Gradle Plugin (native Android GMS)
       │
       ├─► lib/firebase_options.dart ────────► DefaultFirebaseOptions.android (hardcoded fallback)
       │
       └─► android/key.properties ──────────► android/app/build.gradle.kts (release signing)
```

### Key Architectural Characteristics & Discrepancies
1. **Decoupled Configuration Sinks:**
   - [`lib/main.dart`](file:///d:/Easycheck%20ONLINE/lib/main.dart#L11) initializes `EnvConfig` via `await EnvConfig.initialize();`.
   - However, [`lib/main.dart`](file:///d:/Easycheck%20ONLINE/lib/main.dart#L17) initializes Firebase via `DefaultFirebaseOptions.currentPlatform` from [`lib/firebase_options.dart`](file:///d:/Easycheck%20ONLINE/lib/firebase_options.dart#L11), which uses statically hardcoded configuration parameters rather than reading dynamically from `EnvConfig`.
2. **Client-Side Bundling (`pubspec.yaml`):**
   - The `.env` file is declared under `assets:` in [`pubspec.yaml`](file:///d:/Easycheck%20ONLINE/pubspec.yaml#L35). This causes the `.env` file to be packaged in plaintext inside the compiled Android APK/AAB package (`assets/.env`).
3. **Graceful Fallback:**
   - If `.env` is absent or unreadable, `EnvConfig.initialize()` catches all exceptions silently (`try { await dotenv.load(...) } catch (_) {}`), allowing `String.fromEnvironment` defaults to take effect.

---

## 3. Complete Environment Variable Registry

### Application & Runtime Environment Variables (`.env` / `--dart-define`)

| Variable Name | Purpose | Req / Opt | Target Environment | Data Type | Code Default | Consumed In | Failure Impact | Sensitive | Validation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `ENVIRONMENT` | Defines execution tier (`development`, `staging`, `production`, `testing`) | Optional | All | String | `'development'` | [`lib/core/config/env_config.dart#L18-L20`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L18-L20) | Falls back to `'development'`; no active branching currently queries this getter | No | None |
| `APP_NAME` | User-facing display title for application | Optional | All | String | `'EasyCheck Online'` | [`lib/core/config/env_config.dart#L22-L24`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L22-L24) | Falls back to code default; [`app.dart#L36`](file:///d:/Easycheck%20ONLINE/lib/app/app.dart#L36) hardcodes title independently | No | None |
| `APP_PACKAGE_NAME` | Android package name & application ID | Optional | All | String | `'com.easycheck.online.easycheck_online'` | [`lib/core/config/env_config.dart#L26-L31`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L26-L31) | Falls back to default; native Gradle uses [`build.gradle.kts#L29`](file:///d:/Easycheck%20ONLINE/android/app/build.gradle.kts#L29) | No | None |
| `FIREBASE_PROJECT_ID` | GCP / Firebase project identifier | Optional (Fallback) | All | String | `'easycheck-online'` | [`lib/core/config/env_config.dart#L34-L39`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L34-L39) | If wired and invalid, Firebase API endpoints return project not found | Public ID | None |
| `FIREBASE_PROJECT_NUMBER` | Google Cloud project number / FCM sender ID | Optional (Fallback) | All | String | `'1085858861836'` | [`lib/core/config/env_config.dart#L41-L46`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L41-L46) | FCM message routing fails if mismatched | Public ID | None |
| `FIREBASE_STORAGE_BUCKET` | Google Cloud Storage bucket domain | Optional (Fallback) | All | String | `'easycheck-online.firebasestorage.app'` | [`lib/core/config/env_config.dart#L48-L53`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L48-L53) | Cloud Storage uploads/downloads fail if mismatched | Public ID | None |
| `FIREBASE_ANDROID_APP_ID` | Firebase Android application client ID | Optional (Fallback) | Android | String | `'1:1085858861836:android:f6c366f51fe48bac61ef29'` | [`lib/core/config/env_config.dart#L55-L60`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L55-L60) | Firebase SDK rejects registration if mismatched | Public ID | None |
| `FIREBASE_API_KEY` | Firebase Web/Android client API key | Required* | All | String | `''` (empty string) | [`lib/core/config/env_config.dart#L62-L65`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L62-L65) | If dynamic config is used, empty key halts Firebase initialization; [`firebase_options.dart#L22`](file:///d:/Easycheck%20ONLINE/lib/firebase_options.dart#L22) contains hardcoded fallback | Yes (Restricted) | None |
| `GOOGLE_WEB_CLIENT_ID` | OAuth 2.0 Web Client ID for Google Auth token exchange | Required* | Web / Auth | String | `''` (empty string) | [`lib/core/config/env_config.dart#L67-L70`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L67-L70) | Cross-platform or Web Google Sign-In fails token validation | Public OAuth ID | None |
| `GOOGLE_ANDROID_CLIENT_ID` | OAuth 2.0 Android Client ID | Optional | Android | String | `''` (empty string) | [`lib/core/config/env_config.dart#L71-L74`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L71-L74) | Native Android sign-in reads from `google-services.json` directly | Public OAuth ID | None |
| `ANDROID_DEBUG_SHA1` | Debug Keystore SHA-1 certificate fingerprint | Optional (DevOps) | Dev / Firebase Console | Hex-colon String | None | [`.env.example#L23`](file:///d:/Easycheck%20ONLINE/.env.example#L23) | If missing in Firebase Console, Google Sign-In fails on Android with `ApiException: 10` | No | None |
| `ANDROID_DEBUG_SHA256` | Debug Keystore SHA-256 certificate fingerprint | Optional (DevOps) | Dev / Firebase Console | Hex-colon String | None | [`.env.example#L24`](file:///d:/Easycheck%20ONLINE/.env.example#L24) | App Check / App Links validation fails in development | No | None |
| `SUPPORT_EMAIL` | Official administrative support contact email | Optional | All | String (Email) | `'bipulkumarsiwan6262@gmail.com'` | [`lib/core/config/env_config.dart#L76-L81`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L76-L81) | Fallback personal address exposed if unconfigured | Semi-sensitive | None |
| `SUPPORT_PHONE` | Official support contact telephone number | Optional | All | String (E.164) | `'+919876543210'` | [`lib/core/config/env_config.dart#L83-L88`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L83-L88) | Fallback dummy phone number rendered in helpdesk dialogs | No | None |

*\*Note on Required Status:* In the current codebase state, `lib/firebase_options.dart` provides static fallbacks for Firebase API credentials. However, if the application is switched to purely dynamic configuration via `EnvConfig`, `FIREBASE_API_KEY` and `GOOGLE_WEB_CLIENT_ID` become strictly required.

---

### Android Release Keystore Properties (`android/key.properties`)

Read by [`android/app/build.gradle.kts#L11-L15`](file:///d:/Easycheck%20ONLINE/android/app/build.gradle.kts#L11-L15) when generating release APKs/AABs:

| Property | Purpose | Req / Opt | Target Environment | Data Type | Code Default | Consumed In | Failure Impact | Sensitive |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `keyAlias` | Signing key alias inside the keystore | Required for Release | Production / Staging | String | None | [`build.gradle.kts#L45`](file:///d:/Easycheck%20ONLINE/android/app/build.gradle.kts#L45) | Build fails or falls back to debug signing | Semi-sensitive |
| `keyPassword` | Password for the signing key | Required for Release | Production / Staging | String | None | [`build.gradle.kts#L46`](file:///d:/Easycheck%20ONLINE/android/app/build.gradle.kts#L46) | Release build fails (authentication failed) | **Yes (Secret)** |
| `storeFile` | Relative path to release `.jks` / `.keystore` | Required for Release | Production / Staging | String (Path) | None | [`build.gradle.kts#L47`](file:///d:/Easycheck%20ONLINE/android/app/build.gradle.kts#L47) | Release build fails (file not found) | Semi-sensitive |
| `storePassword` | Master password for keystore file | Required for Release | Production / Staging | String | None | [`build.gradle.kts#L48`](file:///d:/Easycheck%20ONLINE/android/app/build.gradle.kts#L48) | Release build fails (keystore unlock failed) | **Yes (Secret)** |

---

### Local SDK & Build Properties (`android/local.properties`)

Generated automatically by Flutter tooling on local machines:

| Property | Purpose | Req / Opt | Source | Failure Impact | Sensitive |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `flutter.sdk` | Absolute path to Flutter SDK directory | Required | Flutter CLI | Gradle cannot locate Flutter Gradle plugins; build halts | Local Path |
| `sdk.dir` | Absolute path to Android SDK directory | Required | Android Studio / Flutter CLI | Gradle cannot compile Android sources | Local Path |
| `flutter.buildMode` | Target compilation mode (`debug`, `profile`, `release`) | Internal | Flutter build tool | None (managed by tool) | No |
| `flutter.versionName` | Semantic version string (from `pubspec.yaml`) | Internal | Flutter build tool | Defaults to 1.0.0 | No |
| `flutter.versionCode` | Numeric build number (from `pubspec.yaml`) | Internal | Flutter build tool | Defaults to 1 | No |

---

## 4. Required Variables

For a fully operational production deployment connecting to live Firebase infrastructure:

1. **`FIREBASE_API_KEY`:** Must be set to a valid Google Cloud API key authorized for the `easycheck-online` project with Android package `com.easycheck.online.easycheck_online` restrictions.
2. **`FIREBASE_PROJECT_ID`:** Must match the target Firebase project identifier (`easycheck-online`).
3. **`FIREBASE_PROJECT_NUMBER`:** Must match the numeric project ID (`1085858861836`).
4. **`FIREBASE_STORAGE_BUCKET`:** Must point to the provisioned Cloud Storage bucket (`easycheck-online.firebasestorage.app`).
5. **`FIREBASE_ANDROID_APP_ID`:** Must match the registered Android client application ID.
6. **`GOOGLE_WEB_CLIENT_ID`:** Must be supplied if running on Web or exchanging OAuth tokens with server-side components.
7. **`keyAlias`, `keyPassword`, `storeFile`, `storePassword`:** Strictly required in `android/key.properties` for production release builds; without them, Gradle falls back to `signingConfigs.debug`.

---

## 5. Optional Variables

The following variables provide default fallbacks in code and can be omitted without crashing the app:

1. **`ENVIRONMENT`:** Defaults to `'development'`.
2. **`APP_NAME`:** Defaults to `'EasyCheck Online'`.
3. **`APP_PACKAGE_NAME`:** Defaults to `'com.easycheck.online.easycheck_online'`.
4. **`GOOGLE_ANDROID_CLIENT_ID`:** Handled by `google-services.json` on Android.
5. **`ANDROID_DEBUG_SHA1` & `ANDROID_DEBUG_SHA256`:** External reference fingerprints for Firebase Console setup; not consumed by the runtime engine.
6. **`SUPPORT_EMAIL`:** Defaults to `'bipulkumarsiwan6262@gmail.com'`.
7. **`SUPPORT_PHONE`:** Defaults to `'+919876543210'`.

---

## 6. Frontend / Public Variables

In Flutter's client-side architecture, all variables compiled into the client binary or bundled as assets are publicly accessible:

- `ENVIRONMENT`
- `APP_NAME`
- `APP_PACKAGE_NAME`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_PROJECT_NUMBER`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_ANDROID_APP_ID`
- `FIREBASE_API_KEY`
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_ANDROID_CLIENT_ID`
- `ANDROID_DEBUG_SHA1`
- `ANDROID_DEBUG_SHA256`
- `SUPPORT_PHONE`

> **Security Classification:** Firebase Client API keys and Project IDs are **not** secrets—they are public identifiers for Firebase client SDKs. Security is enforced exclusively by **Firestore Security Rules** (`firestore.rules`) and **API key restrictions** in Google Cloud Console.

---

## 7. Backend / Private Variables

1. **Android Keystore Secrets (`android/key.properties`):**
   - `keyPassword`
   - `storePassword`
   - `storeFile`
   - **Classification:** Strictly confidential build secrets. Must **never** be committed to Git, bundled into assets, or included in client `.env` files.
2. **Server-Side Admin Credentials (Future / External):**
   - Firebase Service Account private keys (`service-account.json`) are **not** present in this repository and must never be added to mobile application code.

---

## 8. Development Configuration

- **Configuration File:** Root `.env` file (copied from `.env.example`).
- **Execution Command:** `flutter run`
- **Signing Mode:** Debug keystore automatically managed by Android SDK (`~/.android/debug.keystore`).
- **Fingerprint Requirements:** The SHA-1 and SHA-256 fingerprints of the local debug keystore must be added to the Firebase Console Android App configuration to allow Google Sign-In to function without developer errors (`ApiException: 10`).
- **Asset Loading:** `.env` is loaded from assets via `dotenv.load(fileName: '.env')`.

---

## 9. Testing Configuration

- **Harness:** Flutter Test runner (`flutter test`).
- **Test File:** [`test/widget_test.dart`](file:///d:/Easycheck%20ONLINE/test/widget_test.dart).
- **Firebase Behavior:**
  - `setUpAll()` in `test/widget_test.dart#L16-L22` wraps `Firebase.initializeApp` in `try / catch (_)`.
  - In headless CI or local environments without native platform channels, Firebase initialization fails gracefully, and widgets run in offline / UI simulation mode.
- **Environment Overrides:** Tests do not load `.env` by default; they rely on static code constants and in-memory mock data.

---

## 10. Staging Configuration

- **Configuration Recommendation:** Build with `--dart-define` flags to point to a distinct staging Firebase project:
  ```bash
  flutter build apk --dart-define=ENVIRONMENT=staging \
                    --dart-define=FIREBASE_PROJECT_ID=easycheck-staging \
                    --dart-define=FIREBASE_API_KEY=<staging-api-key>
  ```
- **Current Limitation:** Because `lib/firebase_options.dart` currently hardcodes the production project ID (`easycheck-online`), switching projects requires updating `firebase_options.dart` or refactoring it to consume `EnvConfig`.

---

## 11. Production Configuration

- **Build Command:**
  ```bash
  flutter build appbundle --release
  ```
- **Signing Requirement:** Requires `android/key.properties` pointing to a valid production upload keystore (`.jks`).
- **Firebase Project:** `easycheck-online` (Project Number: `1085858861836`).
- **Firestore Location:** `asia-south1` (configured in `firebase.json`).
- **Hosting Target:** `easycheck-online.web.app` / `easycheck-online.firebaseapp.com`.
- **Security Check:** Ensure `.env` bundled in production does not contain unauthorized administrative keys or raw keystore passwords.

---

## 12. Docker and CI/CD Variables

- **Current Repository State:** No Dockerfiles, `docker-compose.yml`, GitHub Actions workflows (`.github/workflows`), or cloud build pipelines exist in the repository.
- **CI/CD Compatibility Matrix:**
  - When setting up CI/CD (e.g., GitHub Actions, Codemagic, Fastlane), the following pipeline secrets must be provisioned:
    - `KEYSTORE_BASE64` (Base64-encoded release `.jks` file)
    - `KEY_ALIAS`
    - `KEY_PASSWORD`
    - `STORE_PASSWORD`
    - `GOOGLE_SERVICES_JSON_BASE64` (Base64-encoded `google-services.json`)

---

## 13. Variable Dependencies and Relationships

```
                     FIREBASE_PROJECT_ID (easycheck-online)
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
FIREBASE_ANDROID_APP_ID              FIREBASE_STORAGE_BUCKET
(1:1085858861836:android:...)        (easycheck-online.firebasestorage.app)
            │
            ├─────────────────────────────────────┐
            ▼                                     ▼
GOOGLE_ANDROID_CLIENT_ID              GOOGLE_WEB_CLIENT_ID
(Android OAuth Client)                (Web Token Exchange Client)
            │
            ▼
ANDROID_DEBUG_SHA1 & ANDROID_DEBUG_SHA256
(Must match Keystore Certificate Fingerprint in Firebase Console)
```

- Changing `FIREBASE_PROJECT_ID` necessitates corresponding updates to `FIREBASE_PROJECT_NUMBER`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_ANDROID_APP_ID`, and `GOOGLE_WEB_CLIENT_ID`.
- Mismatches between `APP_PACKAGE_NAME`, `FIREBASE_ANDROID_APP_ID`, and the keystore SHA-1 will cause Google Sign-In to reject authentication requests.

---

## 14. Defaults and Fallback Behavior

```
Variable Lookup Order:
1. dotenv.env['KEY'] (read from .env asset at runtime)
2. const String.fromEnvironment('KEY') (passed via --dart-define at compile time)
3. Hardcoded defaultValue in EnvConfig getter (e.g. 'easycheck-online')
4. Statically defined constants in lib/firebase_options.dart
```

- **Robustness:** The application will never crash solely due to a missing `.env` file because `EnvConfig.initialize()` handles load exceptions gracefully and every getter supplies a non-null string fallback.
- **Downside:** Hardcoded fallbacks make it easy for production builds to silently fall back to development/default project settings if environment injection fails during CI builds.

---

## 15. Security and Exposure Risks

### 1. Plaintext Asset Bundling (`.env` in `pubspec.yaml`)
- **Severity:** Medium / High
- **Evidence:** [`pubspec.yaml:35`](file:///d:/Easycheck%20ONLINE/pubspec.yaml#L35) includes `- .env` under `flutter.assets`.
- **Finding:** Any `.env` file present at build time is embedded unencrypted into the APK's `assets/` directory. Anyone downloading the APK can extract `.env` with standard decompression tools.
- **Mitigation:** Ensure `.env` contains only public client configuration. Never store database passwords, private keys, or keystore credentials in `.env`.

### 2. Hardcoded Personal Email Address
- **Severity:** Low / Privacy
- **Evidence:** [`lib/core/config/env_config.dart:80`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L80) and [`firebase.json:13`](file:///d:/Easycheck%20ONLINE/firebase.json#L13).
- **Finding:** A personal Gmail address is hardcoded as the default `SUPPORT_EMAIL` and OAuth brand support email.
- **Mitigation:** Replace with an organizational support address (e.g., `support@easycheck.online`).

### 3. Duplicated Google Services Configuration
- **Severity:** Low / Hygiene
- **Evidence:** `android/app/google-services (1).json` exists alongside `android/app/google-services.json`.
- **Finding:** Duplicate artifact from previous downloads.

### 4. Lack of Runtime Configuration Validation
- **Severity:** Medium
- **Evidence:** [`lib/core/config/env_config.dart:18-88`](file:///d:/Easycheck%20ONLINE/lib/core/config/env_config.dart#L18-L88).
- **Finding:** No validation or assertions check that API keys, client IDs, or bucket names match expected formats or non-empty strings before initializing network services.

---

## 16. Missing or Undocumented Variables

The following configuration parameters are hardcoded in application code and should be converted to environment variables:

1. **`ADMOB_BANNER_WIDTH` & `ADMOB_BANNER_HEIGHT`:** Hardcoded in [`lib/core/constants/app_constants.dart:10-11`](file:///d:/Easycheck%20ONLINE/lib/core/constants/app_constants.dart#L10-L11).
2. **`DEFAULT_CITY`:** Hardcoded as `'Lahore, Punjab'` in [`lib/core/constants/app_constants.dart:7`](file:///d:/Easycheck%20ONLINE/lib/core/constants/app_constants.dart#L7).
3. **CDN Image URLs:** Hardcoded remote image URLs in [`lib/features/authentication/patient_login_screen.dart:38-41`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/patient_login_screen.dart#L38-L41) and [`admin_login_screen.dart:29-30`](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_login_screen.dart#L29-L30).

---

## 17. Unused or Potentially Obsolete Variables

1. **`ANDROID_DEBUG_SHA1` & `ANDROID_DEBUG_SHA256`:**
   - Present in `.env` and `.env.example`.
   - **Status:** Unused by application and build code. Kept as documentation metadata for Firebase Console setup.
2. **`GOOGLE_ANDROID_CLIENT_ID`:**
   - Declared in `EnvConfig` and `.env.example`.
   - **Status:** Unused in Dart code. Native Android Google Sign-In relies on `google-services.json`.
3. **`SUPPORT_PHONE`:**
   - Declared in `EnvConfig` and `.env.example`.
   - **Status:** Defined as a getter, but not referenced by any UI screen.

---

## 18. Configuration Validation

Currently, **no automated validation** is performed on environment variables at compile time or startup.

### Recommended Validation Contract (for future implementation)
```dart
void validateEnvironment() {
  assert(EnvConfig.firebaseApiKey.isNotEmpty, 'FIREBASE_API_KEY must not be empty');
  assert(EnvConfig.firebaseProjectId.isNotEmpty, 'FIREBASE_PROJECT_ID must not be empty');
  assert(EnvConfig.firebaseProjectId.matches(r'^[a-z0-9-]+$'), 'Invalid FIREBASE_PROJECT_ID');
}
```

---

## 19. Safe Setup Instructions

### Local Development Setup

1. Copy the example template to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Populate `.env` with project parameters (Safe Template):
   ```ini
   ENVIRONMENT=development
   APP_NAME="EasyCheck Online"
   APP_PACKAGE_NAME=com.easycheck.online.easycheck_online

   # Firebase Configuration
   FIREBASE_PROJECT_ID=<your-firebase-project-id>
   FIREBASE_PROJECT_NUMBER=<your-firebase-project-number>
   FIREBASE_STORAGE_BUCKET=<your-project-id>.firebasestorage.app
   FIREBASE_ANDROID_APP_ID=<your-android-app-id>
   FIREBASE_API_KEY=<your-google-api-key>

   # Google OAuth Client IDs
   GOOGLE_WEB_CLIENT_ID=<your-web-client-id>.apps.googleusercontent.com
   GOOGLE_ANDROID_CLIENT_ID=<your-android-client-id>.apps.googleusercontent.com

   # Keystore Fingerprints for Firebase Console
   ANDROID_DEBUG_SHA1=00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
   ANDROID_DEBUG_SHA256=00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00

   # Support Contacts
   SUPPORT_EMAIL=support@easycheck.online
   SUPPORT_PHONE=+910000000000
   ```
3. Ensure [`android/app/google-services.json`](file:///d:/Easycheck%20ONLINE/android/app/google-services.json) matches the target Firebase project.
4. Verify debug keystore SHA-1 is added in Firebase Console.
5. Launch the app:
   ```bash
   flutter run
   ```

### Production Release Setup

1. Create `android/key.properties` (never commit to version control):
   ```properties
   keyAlias=<your-release-key-alias>
   keyPassword=<your-release-key-password>
   storeFile=<path-to-your-keystore-file.jks>
   storePassword=<your-keystore-password>
   ```
2. Build the release App Bundle:
   ```bash
   flutter build appbundle --release
   ```

---

## 20. Known Limitations and Unknowns

1. **`lib/firebase_options.dart` vs `EnvConfig` Coupling:**
   - *Status:* **Architectural Disconnect**
   - *Detail:* Modifying `FIREBASE_API_KEY` or `FIREBASE_PROJECT_ID` in `.env` does not alter Firebase initialization in `lib/main.dart` because `DefaultFirebaseOptions.android` contains hardcoded values.
2. **Missing Backend Cloud Functions Configuration:**
   - *Status:* **Unknown / Unverified**
   - *Detail:* The repository does not contain a `functions/` directory or server-side environment contracts. All operations currently execute directly from the client against Cloud Firestore.
3. **Absence of CI/CD Pipelines:**
   - *Status:* **Verified Absent**
   - *Detail:* No automated build or deployment pipelines are configured in the repository.

