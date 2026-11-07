# IMPACT-MAP.md — EasyCheck Online

## 1. Purpose

This document provides a verified architectural and operational impact map for **EasyCheck Online** (Flutter + Firebase / Cloud Firestore outpatient and parchi queue tracking platform).

### What This Map Protects Against
1. **Cascading Startup & Runtime Breakage:** Altering bootstrap dependencies (e.g., `EnvConfig`, `Firebase.initializeApp`, `AppTheme`, `AppRoutes`) without tracing their downstream consumers can cause black screens, uncaught platform exceptions, or broken navigation stacks.
2. **Dual-Model Desynchronization:** The project maintains two distinct `ClinicModel` representations (`lib/features/clinics/clinic_model.dart` for Firestore documents and `lib/shared/models/clinic_model.dart` for UI presentation). Changes to either model or the `toDisplayModel()` adapter can break patient screen rendering and route argument passing.
3. **Security Rule & Backend Repository Contract Inconsistencies:** Client repositories (`QueueRepository`, `ClinicMembershipRepository`, `UserProfileRepository`) and Firestore Security Rules (`firestore.rules`) have strict architectural assumptions regarding document IDs, RBAC permissions, and transactional increments. Breaking these contracts causes runtime `PERMISSION_DENIED` errors in production.
4. **Theme & Typography Regressions:** The application enforces two distinct design systems: "Clinical Clarity" for patients and "Clinical Precision" for clinic administrators. Unverified edits to color tokens, typography classes, or spacing constants impact multiple screens simultaneously.
5. **Accidental Codebase Degradation:** Serves as a defensive guardrail for AI agents and human developers to consult **before** modifying, refactoring, or extending any file, function, schema, or configuration.

---

## 2. Impact Map

---

### Entrypoint & App Shell

#### Component: `lib/main.dart` → `main()`
- **Role:** Application entrypoint; initializes Flutter bindings, loads environment variables via `EnvConfig.initialize()`, initializes Firebase with fallback error-handling, and runs the root widget inside a guarded zone (`runZonedGuarded`).
- **Directly affected:**
  - `lib/app/app.dart` (`EasyCheckApp`)
  - `lib/core/config/env_config.dart` (`EnvConfig.initialize()`)
  - `lib/firebase_options.dart` (`DefaultFirebaseOptions.currentPlatform`)
- **Potentially affected:**
  - All screens and repositories requiring Firebase (`FirebaseAuth`, `FirebaseFirestore`)
  - Global error logging and diagnostics
- **API impact:** None directly.
- **Data impact:** Determines whether Cloud Firestore and Firebase Auth can establish remote connections or fallback to offline/UI-only mode.
- **Security impact:** Controls startup authentication listener availability.
- **Runtime impact:** Failure inside `main()` halts app boot immediately; uncaught asynchronous errors are caught by `runZonedGuarded` and logged via `debugPrint`.
- **Frontend impact:** Controls whether the app successfully renders `EasyCheckApp` or crashes on launch.
- **Tests to review:** `test/widget_test.dart` (Test: `EasyCheckApp bootstraps and renders patient login`).
- **Infrastructure impact:** Requires `assets/.env` asset bundling in `pubspec.yaml` and platform channel availability for Firebase native plugins.
- **Confidence:** Verified
- **Evidence:** `lib/main.dart:9-27`, `lib/app/app.dart:22-66`.

---

#### Component: `lib/app/app.dart` → `EasyCheckApp` & `_AdminThemed`
- **Role:** Root `StatelessWidget` configuring `MaterialApp`, multi-locale localization (`AppLocalizations`), routing table (`AppRoutes`), dual-theme injection (`AppTheme.patientTheme` and `_AdminThemed`), and dynamic `initialRoute` based on `FirebaseAuth.instance.authStateChanges()`. Also houses custom route parameter adapter for `AppRoutes.patientClinicDetails`.
- **Directly affected:**
  - `lib/main.dart` (calls `runApp(const EasyCheckApp())`)
  - `lib/app/routes/app_routes.dart` (maps all string routes)
  - `lib/app/theme/app_theme.dart` (consumes `patientTheme` and `adminTheme`)
  - `lib/app/localization/app_localizations.dart` (configures locale delegates)
  - `lib/features/authentication/patient_login_screen.dart` (route `/` and `/patient/login`)
  - `lib/features/authentication/admin_login_screen.dart` (route `/admin/login`)
  - `lib/features/patient/patient_home_screen.dart` (route `/patient/home`)
  - `lib/features/clinic/clinic_details_screen.dart` (route `/patient/clinic-details`)
  - `lib/features/admin/admin_dashboard_screen.dart` (route `/admin/dashboard`)
  - `lib/features/admin/admin_reset_studio_screen.dart` (route `/admin/reset-studio`)
  - `lib/features/admin/admin_unauthorized_screen.dart` (route `/admin/unauthorized`)
  - `lib/features/clinics/clinic_model.dart` (`toDisplayModel()`)
  - `lib/shared/models/clinic_model.dart` (`display_clinic.ClinicModel`)
- **Potentially affected:**
  - Authentication redirects across all user sessions
  - Role-based theming (admin screens wrapped in `_AdminThemed`)
- **API impact:** None.
- **Data impact:** None directly; reads `FirebaseAuth.instance.authStateChanges()`.
- **Security impact:** High. Determines whether an authenticated user bypasses login directly to `AppRoutes.patientHome`. Admin routes are registered publicly but expected to be role-guarded by admin screens.
- **Runtime impact:** Real-time stream rebuild when auth state transitions between logged-in and logged-out.
- **Frontend impact:** Controls root navigator, theme changes, and locale resolution for the entire application.
- **Tests to review:** `test/widget_test.dart` (All tests instantiate widgets wrapped in `MaterialApp` or run `EasyCheckApp`).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/app/app.dart:1-92`, `lib/app/routes/app_routes.dart:1-17`.

---

#### Component: `lib/app/routes/app_routes.dart` → `AppRoutes`
- **Role:** Centralized repository of named route constants for both Patient and Admin navigation trees.
- **Directly affected:**
  - `lib/app/app.dart` (builds `routes` map and `initialRoute`)
  - `lib/features/authentication/patient_login_screen.dart` (navigates to `AppRoutes.patientHome`)
  - `lib/features/patient/patient_home_screen.dart` (navigates to `AppRoutes.patientClinicDetails`)
- **Potentially affected:**
  - Deep linking, web routing, or push notification navigation handlers.
  - Admin navigation triggers in `AdminLoginScreen`, `AdminDashboardScreen`, `AdminResetStudioScreen`, and `AdminUnauthorizedScreen`.
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** Changing route constants without updating route guard maps can expose guarded views or cause navigation failure.
- **Runtime impact:** Calling `Navigator.pushNamed()` with an unmapped route throws runtime `FlutterError` (e.g. `Could not find a generator for route RouteSettings(...)`).
- **Frontend impact:** Controls screen transitions and named navigation across the application.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/app/routes/app_routes.dart:1-17`, `lib/app/app.dart:52-76`, `lib/features/patient/patient_home_screen.dart:1210-1215`.

---

### Configuration & Infrastructure

#### Component: `lib/core/config/env_config.dart` → `EnvConfig`
- **Role:** Centralized secrets and environment configuration service. Reads variables from `.env` via `flutter_dotenv` with static fallbacks via `String.fromEnvironment`.
- **Directly affected:**
  - `lib/main.dart` (invokes `EnvConfig.initialize()`)
- **Potentially affected:**
  - Firebase and Google OAuth authentication flows
  - Administrative and support contact links (email/phone)
- **API impact:** Provides OAuth client IDs (`googleWebClientId`, `googleAndroidClientId`) used by Google Sign-In SDK.
- **Data impact:** Supplies `firebaseProjectId`, `firebaseStorageBucket`, `firebaseAndroidAppId`.
- **Security impact:** High. Exposing or altering API keys, Project IDs, or OAuth Client IDs will disrupt Google Sign-In authentication or route traffic to invalid Firebase environments.
- **Runtime impact:** Silent fallback if `.env` fails to load; values fall back to default compile-time constants.
- **Frontend impact:** Supplies support contact info (`supportEmail`, `supportPhone`) displayed in helpdesk and error modals.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** Tied to `.env`, `.env.example`, `assets/.env` packaging in `pubspec.yaml`, and Google Cloud console OAuth 2.0 Client credentials.
- **Confidence:** Verified
- **Evidence:** `lib/core/config/env_config.dart:1-89`, `pubspec.yaml:35`.

---

#### Component: `lib/firebase_options.dart` → `DefaultFirebaseOptions`
- **Role:** Supplies platform-specific `FirebaseOptions` (API key, appId, messagingSenderId, projectId, storageBucket) for Android and fallback platforms.
- **Directly affected:**
  - `lib/main.dart` (passed to `Firebase.initializeApp`)
  - `test/widget_test.dart` (passed to `Firebase.initializeApp` in `setUpAll`)
- **Potentially affected:**
  - All Firebase services (`FirebaseAuth`, `FirebaseFirestore`).
- **API impact:** Targets Google Firebase API endpoints.
- **Data impact:** Direct connection string to Firebase project `easycheck-online`.
- **Security impact:** Contains public client identifiers (API key, App ID). Restricting API keys in GCP console must whitelist the Android SHA-1 fingerprint.
- **Runtime impact:** Invalid options cause `FirebaseException` during `Firebase.initializeApp()`.
- **Frontend impact:** Controls whether live backend feeds work or UI falls back to offline/simulated mode.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** Synchronized with `android/app/google-services.json` and `.firebaserc`.
- **Confidence:** Verified
- **Evidence:** `lib/firebase_options.dart:1-28`, `android/app/google-services.json`.

---

#### Component: `firestore.rules` → Security & Access Control Rules
- **Role:** Defines declarative server-side access control, role authorization, and validation rules for Cloud Firestore collections (`users`, `clinics`, `clinic_members`, `queue_sessions`, `queue_history`).
- **Directly affected:**
  - `lib/features/authentication/user_profile_repository.dart`
  - `lib/features/clinics/clinic_repository.dart`
  - `lib/features/clinics/clinic_membership_repository.dart`
  - `lib/features/clinics/queue_repository.dart`
- **Potentially affected:**
  - All patient and admin UI screens attempting to read or write Firestore data.
- **API impact:** Rejects unauthorized client-side REST/gRPC queries from the mobile SDK with `PERMISSION_DENIED`.
- **Data impact:**
  - Enforces clinic ID format regex: `^CLN-\\d{5}$`
  - Restricts `queue_sessions` creation: `allow create: if false;` (sessions must be created server-side or by admin systems).
  - Restricts `queue_sessions` update: `currentParchaNumber` can ONLY be incremented by 1 (`request.resource.data.currentParchaNumber == resource.data.currentParchaNumber + 1`).
  - Restricts `queue_history`: Immutable (create allowed for staff with `update_tally` or `reset_tally`, update/delete forbidden).
- **Security impact:** Critical. Prevents privilege escalation, cross-tenant data leakage, unauthorized parchi count resets, and tampering with audit logs.
- **Runtime impact:** Inconsistencies between client repositories and `firestore.rules` cause runtime exceptions during Firestore operations.
  - *Known Architectural Conflict:* `QueueRepository.resetParcha()` attempts to set `currentParchaNumber: 0`, which is rejected by `firestore.rules` line 142 unless rules are updated.
  - *Known Architectural Conflict:* `ClinicMembershipRepository` uses document ID `${userId}_${clinicId}`, whereas `firestore.rules` line 102 expects document ID `${clinicId}` with a nested map `members[userId]`.
- **Frontend impact:** Unhandled permission errors trigger error widgets (`_buildErrorState`) in `PatientHomeScreen` and failure toasts in Admin screens.
- **Tests to review:** Firebase Emulator security rules test suite (outside Flutter unit tests).
- **Infrastructure impact:** Deployed via `firebase deploy --only firestore:rules` or Firebase Console.
- **Confidence:** Verified
- **Evidence:** `firestore.rules:1-174`, `firebase.json:5`, `lib/features/clinics/queue_repository.dart:102-140`.

---

#### Component: `firestore.indexes.json` → Composite Query Indexes
- **Role:** Defines Firestore composite indexes required for compound queries on `clinics` collection group.
- **Directly affected:**
  - `lib/features/clinics/clinic_repository.dart` (compound queries involving `city`, `isActive`, `updatedAt`, `adminUid`)
- **Potentially affected:**
  - Search and filter queries in `PatientHomeScreen`.
- **API impact:** None.
- **Data impact:** Required for queries:
  1. `clinics` where `city == X` and `isActive == Y` ordered by `updatedAt DESC`.
  2. `clinics` where `adminUid == X` ordered by `updatedAt DESC`.
- **Security impact:** None.
- **Runtime impact:** Executing a query requiring a missing composite index throws `FirebaseException: The query requires an index`.
- **Frontend impact:** Queries fail and screens display error states if index is missing.
- **Tests to review:** Integration tests querying filtered clinics.
- **Infrastructure impact:** Deployed via `firebase deploy --only firestore:indexes`.
- **Confidence:** Verified
- **Evidence:** `firestore.indexes.json:1-37`, `firebase.json:6`.

---

### Design System & Theming

#### Component: `lib/app/theme/app_colors.dart` → `PatientColors` & `AdminColors`
- **Role:** Centralized color token palettes. Defines "Clinical Clarity" tokens for patients (`PatientColors`: Navy primary, Emerald secondary, Soft Blue canvas) and "Clinical Precision" tokens for administrators (`AdminColors`: Emerald primary, Navy secondary).
- **Directly affected:**
  - `lib/app/theme/app_theme.dart`
  - `lib/core/widgets/status_pill.dart`
  - `lib/shared/widgets/shared_widgets.dart`
  - `lib/features/clinic/clinic_details_screen.dart`
  - `lib/features/admin/admin_dashboard_screen.dart`
  - `lib/features/admin/admin_reset_studio_screen.dart`
  - `lib/features/admin/admin_unauthorized_screen.dart`
- **Potentially affected:**
  - `lib/features/patient/patient_home_screen.dart` (uses direct hex constants matching these tokens)
  - `lib/features/authentication/patient_login_screen.dart` (uses local constants matching these tokens)
  - `lib/features/authentication/admin_login_screen.dart` (uses local constants matching these tokens)
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** None.
- **Runtime impact:** None.
- **Frontend impact:** Visual branding, contrast ratios, and theme compliance across all 7 application screens.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/app/theme/app_colors.dart:1-112`, `lib/app/theme/app_theme.dart:9-57`.

---

#### Component: `lib/app/theme/app_typography.dart` → `AppTypography`
- **Role:** Typography hierarchy defining font families (`Inter`, `Plus Jakarta Sans`), font sizes, weights, line heights, and letter spacings.
- **Directly affected:**
  - `lib/shared/widgets/shared_widgets.dart`
  - `lib/core/widgets/status_pill.dart`
  - `lib/features/clinic/clinic_details_screen.dart`
  - `lib/features/admin/admin_reset_studio_screen.dart`
  - `lib/features/admin/admin_unauthorized_screen.dart`
- **Potentially affected:**
  - `lib/app/theme/app_theme.dart` (references typography styles)
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** None.
- **Runtime impact:** None.
- **Frontend impact:** Text rendering across all components and screens.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** Requires `assets/fonts/Inter-Variable.ttf` and `assets/fonts/PlusJakartaSans-Variable.ttf` in `pubspec.yaml`.
- **Confidence:** Verified
- **Evidence:** `lib/app/theme/app_typography.dart:1-106`, `pubspec.yaml:38-43`.

---

#### Component: `lib/app/theme/app_spacing.dart` → `AppSpacing`
- **Role:** Design token utility for layout spacing increments (`spaceXs` to `space2xl`), gutters, margins, and border radii (`roundedSm` to `roundedFull`).
- **Directly affected:**
  - `lib/core/widgets/status_pill.dart`
  - `lib/shared/widgets/shared_widgets.dart`
  - `lib/features/clinic/clinic_details_screen.dart`
  - `lib/features/admin/admin_reset_studio_screen.dart`
  - `lib/features/admin/admin_unauthorized_screen.dart`
- **Potentially affected:**
  - Layout dimensions and padding on patient and admin cards.
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** None.
- **Runtime impact:** None.
- **Frontend impact:** Component alignment, button corner radiuses, card padding.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/app/theme/app_spacing.dart:1-26`.

---

#### Component: `lib/app/theme/app_theme.dart` → `AppTheme`
- **Role:** Generates `ThemeData` instances for the application: `patientTheme` (Material 3 with `PatientColors`) and `adminTheme` (Material 3 with `AdminColors`).
- **Directly affected:**
  - `lib/app/app.dart` (applies `patientTheme` to `MaterialApp` and `adminTheme` to `_AdminThemed`)
  - `test/widget_test.dart` (injects `patientTheme` and `adminTheme` into test harnesses)
- **Potentially affected:**
  - Default widget styling for buttons, text fields, cards, dialogs, and navigation bars.
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** None.
- **Runtime impact:** Material 3 widget rendering.
- **Frontend impact:** Global theming across both patient and admin user journeys.
- **Tests to review:** `test/widget_test.dart` (lines 36, 65, 78, 91, 105, 119).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/app/theme/app_theme.dart:1-58`, `lib/app/app.dart:38, 75`.

---

#### Component: `lib/app/localization/app_localizations.dart` → `AppLocalizations`
- **Role:** Manages internationalization and string translations. Sets Hindi (`hi`, `hi_IN`) as the default locale, with English (`en`, `en_US`) fallbacks.
- **Directly affected:**
  - `lib/app/app.dart` (supplies `locale`, `supportedLocales`, and `localizationsDelegates`)
- **Potentially affected:**
  - Future localized string accessors in patient and admin screens (`AppLocalizations.of(context)`).
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** None.
- **Runtime impact:** Locale resolution during startup.
- **Frontend impact:** Screen text, titles, button labels, and system status indicators when wired via localizations delegate.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** Depends on `flutter_localizations` SDK package.
- **Confidence:** Verified
- **Evidence:** `lib/app/localization/app_localizations.dart:1-223`, `lib/app/app.dart:39-46`.

---

### Core Utilities, Constants, & Shared UI

#### Component: `lib/core/constants/app_constants.dart` → `AppConstants`
- **Role:** Global constants: app name, version, default city (`Lahore, Punjab`), AdMob banner slot dimensions (320x50), and touch target minimums (48.0, 56.0, 64.0).
- **Directly affected:** None currently imports directly (screens use inline or doc-derived values).
- **Potentially affected:**
  - AdMob advertising integrations (`_buildAdBanner` in `PatientHomeScreen`)
  - Accessibility touch-target audits
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** None.
- **Runtime impact:** None.
- **Frontend impact:** Dimensions for ad banners and accessibility targets.
- **Tests to review:** None directly.
- **Infrastructure impact:** AdMob slot identifiers.
- **Confidence:** Verified
- **Evidence:** `lib/core/constants/app_constants.dart:1-17`.

---

#### Component: `lib/core/constants/asset_constants.dart` → `AssetConstants`
- **Role:** Centralized asset path registry for logo images, doctor avatars, Google SVG icons, and typography family identifiers.
- **Directly affected:**
  - `lib/features/patient/patient_home_screen.dart` (`AssetConstants.logoPatient`)
  - `lib/features/clinic/clinic_details_screen.dart` (`AssetConstants.logoPatient`)
  - `lib/features/admin/admin_reset_studio_screen.dart` (`AssetConstants.logoAdmin`, `AssetConstants.avatarReceptionApex`)
  - `lib/features/admin/admin_unauthorized_screen.dart` (`AssetConstants.logoAdmin`, `AssetConstants.avatarReceptionApex`)
- **Potentially affected:**
  - Missing asset paths cause red error boxes (`Image not found`) at runtime.
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** None.
- **Runtime impact:** Image rendering via `Image.asset`.
- **Frontend impact:** Logos, reception avatars, and brand visuals.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** Assets must exist under `assets/images/` and `assets/icons/` and be declared in `pubspec.yaml:33-34`.
- **Confidence:** Verified
- **Evidence:** `lib/core/constants/asset_constants.dart:1-20`, `pubspec.yaml:32-35`.

---

#### Component: `lib/core/errors/app_failure.dart` → `AppFailure` & Subclasses
- **Role:** Domain failure representations: `ServerFailure`, `ConnectionFailure`, `UnauthorizedFailure`.
- **Directly affected:**
  - `lib/features/authentication/user_profile_repository.dart`
  - `lib/features/clinics/clinic_repository.dart`
  - `lib/features/clinics/clinic_membership_repository.dart`
  - `lib/features/clinics/queue_repository.dart`
- **Potentially affected:**
  - Repository catch blocks and error handling logic in UI callers.
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** Standardizes reporting of security/unauthorized access without leaking raw backend errors.
- **Runtime impact:** Thrown by repositories when Firestore operations fail or Firebase is disconnected.
- **Frontend impact:** Converted into UI error states and error messages.
- **Tests to review:** Repository unit tests.
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/core/errors/app_failure.dart:1-25`, `lib/features/clinics/clinic_repository.dart:35, 45, 56`.

---

#### Component: `lib/core/widgets/status_pill.dart` → `StatusPill` & `ClinicOperationalStatus`
- **Role:** Reusable status badge widget displaying operational status (`available`, `delayed`, `unavailable`) with dot indicators and themed colors.
- **Directly affected:**
  - `lib/features/patient/patient_home_screen.dart` (renders status on each clinic card)
- **Potentially affected:**
  - Clinic list and search cards.
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** None.
- **Runtime impact:** None.
- **Frontend impact:** Displays live doctor/clinic availability on patient discovery screens.
- **Tests to review:** `test/widget_test.dart` (Test: `PatientHomeScreen renders discovery header and registered clinics`).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/core/widgets/status_pill.dart:1-76`, `lib/features/patient/patient_home_screen.dart:1105`.

---

#### Component: `lib/shared/widgets/shared_widgets.dart` → `LiveStatusPill`, `LivePulseDot`, `StatusButton`
- **Role:** Shared UI components: pulsing live dots (`LivePulseDot`), operational toggle buttons (`StatusButton`), and live status indicators (`LiveStatusPill`).
- **Directly affected:**
  - `lib/features/clinic/clinic_details_screen.dart` (uses `LivePulseDot`)
- **Potentially affected:**
  - Admin operational controls if wired to `StatusButton`.
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** None.
- **Runtime impact:** Subtle animation controller in `LivePulseDot`.
- **Frontend impact:** Visual feedback for live queue status and parchi updates.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/shared/widgets/shared_widgets.dart:1-134`, `lib/features/clinic/clinic_details_screen.dart:338, 605`.

---

### Authentication & User Identity Domain

#### Component: `lib/features/authentication/user_profile_model.dart` → `UserProfile`
- **Role:** Domain model representing a user document in Firestore (`users/{uid}`). Stores `uid`, `email`, `displayName`, `photoUrl`, `role` (`patient` or `clinic_admin`), timestamps, and `isActive`.
- **Directly affected:**
  - `lib/features/authentication/user_profile_repository.dart`
- **Potentially affected:**
  - Auth state listeners and role checks in patient and admin authentication flows.
- **API impact:** Maps directly to Firestore `users` collection documents.
- **Data impact:** Governs schema for `users/{uid}`.
- **Security impact:** Critical. The `role` attribute (`patient` vs `clinic_admin`) is evaluated by Firestore Security Rules (`firestore.rules:15-17`) to permit or deny admin actions.
  - *Identified Discrepancy:* `firestore.rules` line 32 (`isClinicMember`) expects an array `clinicIds` on `users/{uid}`, but `UserProfile` model does not currently declare `clinicIds`.
- **Runtime impact:** Serialization/deserialization during profile fetches.
- **Frontend impact:** Supplies user details for profile badges, headers, and authorization routing.
- **Tests to review:** User profile model unit tests.
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/features/authentication/user_profile_model.dart:1-77`, `firestore.rules:15-33`.

---

#### Component: `lib/features/authentication/user_profile_repository.dart` → `UserProfileRepository`
- **Role:** Firestore data repository for CRUD operations and real-time streaming on `users/{uid}` collection.
- **Directly affected:**
  - `lib/features/authentication/user_profile_model.dart`
  - `lib/core/errors/app_failure.dart` (`ServerFailure`)
- **Potentially affected:**
  - Login screens post-authentication hook (creating profile if not existing).
  - Admin authorization guards checking user roles.
- **API impact:** Communicates with Firestore `users` collection.
- **Data impact:** Reads/writes `users/{uid}` documents.
- **Security impact:** High. Enforces that profile operations target the authenticated user's UID under `firestore.rules:50-69`.
- **Runtime impact:** Asynchronous Firestore reads/writes; real-time `profileStream(uid)` listener.
- **Frontend impact:** Informs UI of user role and profile changes.
- **Tests to review:** Integration tests for user profile repository.
- **Infrastructure impact:** Cloud Firestore database availability.
- **Confidence:** Verified
- **Evidence:** `lib/features/authentication/user_profile_repository.dart:1-60`.

---

#### Component: `lib/features/authentication/patient_login_screen.dart` → `PatientLoginScreen`
- **Role:** Patient Google OAuth sign-in screen designed under the "Clinical Clarity" design system. Shell: `mobile_blank`. Initiates `FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider())` and navigates to `AppRoutes.patientHome`.
- **Directly affected:**
  - `lib/app/app.dart` (registered as `/` and `/patient/login`)
  - `lib/app/routes/app_routes.dart` (`AppRoutes.patientLogin`)
- **Potentially affected:**
  - Patient onboarding and authentication flow.
- **API impact:** Triggers Google OAuth sign-in flow via Firebase Auth native plugin.
- **Data impact:** Creates/authenticates Firebase Auth user record.
- **Security impact:** High. Entry gate for patients. Allows authenticated patients into `AppRoutes.patientHome`.
- **Runtime impact:** Launches external browser or Google Play Services account picker.
- **Frontend impact:** Splash/login screen rendering, ambient background, brand logos, and legal bottom sheet modal.
- **Tests to review:** `test/widget_test.dart` (Test: `EasyCheckApp bootstraps and renders patient login`).
- **Infrastructure impact:** Requires Google Sign-In configuration in Firebase console and matching SHA-1 debug keystore fingerprints.
- **Confidence:** Verified
- **Evidence:** `lib/features/authentication/patient_login_screen.dart:1-739`, `lib/app/app.dart:53-54`.

---

#### Component: `lib/features/authentication/admin_login_screen.dart` → `AdminLoginScreen`
- **Role:** Administrator Google OAuth sign-in screen under the "Clinical Precision" design system. Shell: `mobile_blank`. Demonstrates authenticated vs. denied states. Intentionally shows denied state pending clinic admin role elevation via helpdesk.
- **Directly affected:**
  - `lib/app/app.dart` (registered as `/admin/login`)
  - `lib/app/routes/app_routes.dart` (`AppRoutes.adminLogin`)
- **Potentially affected:**
  - Clinic admin dashboard entry; dispatching access elevation requests.
- **API impact:** Calls `FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider())`.
- **Data impact:** Authenticates Firebase user.
- **Security impact:** High. Enforces principle of least privilege: authenticating via Google does NOT automatically grant admin privileges without verification against Firestore membership records.
- **Runtime impact:** Interactive UI state toggles between sign-in, access denied card, and helpdesk modal.
- **Frontend impact:** Displays administrative login UI, security badges, access denied alerts, and contact dialogs.
- **Tests to review:** `test/widget_test.dart` (Test: `AdminLoginScreen renders clinic admin title and Google button`).
- **Infrastructure impact:** Same Google OAuth credentials as patient sign-in.
- **Confidence:** Verified
- **Evidence:** `lib/features/authentication/admin_login_screen.dart:1-617`, `lib/app/app.dart:68-69`.

---

### Clinic & Queue Domain

#### Component: `lib/features/clinics/clinic_model.dart` → `ClinicModel` (Firestore Entity)
- **Role:** Firestore data entity representing a clinic in `clinics/{clinicId}`. Contains clinic metadata, doctor information, operational flags (`isActive`, `isOnline`), parchi tallies (`todayParchiCount`, `yesterdayParchiCount`), and the critical adapter method `toDisplayModel()`.
- **Directly affected:**
  - `lib/app/app.dart` (imports as `firestore_clinic`, invokes `toDisplayModel()`)
  - `lib/features/clinics/clinic_repository.dart`
  - `lib/features/patient/patient_home_screen.dart`
  - `lib/shared/models/clinic_model.dart` (target of `toDisplayModel()`)
- **Potentially affected:**
  - `lib/features/clinic/clinic_details_screen.dart` (indirectly receives transformed model)
- **API impact:** Defines serialization structure for Firestore `clinics` collection.
- **Data impact:** Maps directly to `clinics/{clinicId}` documents.
- **Security impact:** Validated against `firestore.rules:75-94`.
- **Runtime impact:** Informs real-time streams and UI state updates when documents mutate.
- **Frontend impact:** Powers clinic cards on `PatientHomeScreen` and adapts data for `ClinicDetailsScreen`.
- **Tests to review:** `test/widget_test.dart` (Test: `PatientHomeScreen renders discovery header and registered clinics`).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/features/clinics/clinic_model.dart:1-188`, `lib/app/app.dart:61-65`.

---

#### Component: `lib/shared/models/clinic_model.dart` → UI Presentation Models
- **Role:** Defines UI-level models strictly mapped to the Stitch design specifications: `ClinicModel`, `DoctorModel`, `ClinicStatus`, `DoctorStatus`, and `AdminUserModel`.
- **Directly affected:**
  - `lib/app/app.dart` (imports as `display_clinic`)
  - `lib/features/clinic/clinic_details_screen.dart` (expects this `ClinicModel`)
  - `lib/features/clinics/clinic_model.dart` (constructed in `toDisplayModel()`)
  - `test/widget_test.dart` (instantiates mock `ClinicModel` and `DoctorModel`)
- **Potentially affected:**
  - All widgets on `ClinicDetailsScreen`.
- **API impact:** None.
- **Data impact:** In-memory view models.
- **Security impact:** None.
- **Runtime impact:** None.
- **Frontend impact:** Drives doctor credentials, status badges, and visit guidance on `ClinicDetailsScreen`.
- **Tests to review:** `test/widget_test.dart` (Test: `ClinicDetailsScreen renders Today Parchi Count card`).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/shared/models/clinic_model.dart:1-63`, `lib/features/clinic/clinic_details_screen.dart:14, 32`.

---

#### Component: `lib/features/clinics/clinic_repository.dart` → `ClinicRepository`
- **Role:** Data repository for clinic operations in Firestore (`clinics` collection). Provides `getClinic`, `createClinic`, `updateClinic`, `clinicStream`, `activeClinicsStream`, `getAllClinics`, `isClinicActive`, `isClinicOnline`. Implements safe fallback if Firebase is uninitialized.
- **Directly affected:**
  - `lib/features/clinics/clinic_model.dart`
  - `lib/features/patient/patient_home_screen.dart` (invokes `activeClinicsStream()`)
  - `lib/core/errors/app_failure.dart` (`ServerFailure`)
- **Potentially affected:**
  - Admin dashboard screens when wired to load clinic operational metadata.
- **API impact:** Queries Firestore `clinics` collection.
- **Data impact:** Reads documents where `isActive == true`.
- **Security impact:** Queries are subjected to `firestore.rules:76-79` (requires authenticated user).
- **Runtime impact:** Manages real-time Firestore stream subscription.
- **Frontend impact:** Powers real-time clinic listing in `PatientHomeScreen`.
- **Tests to review:** `test/widget_test.dart` (Patient home test runs with safe Firebase fallback).
- **Infrastructure impact:** Dependent on Firestore collection indexes.
- **Confidence:** Verified
- **Evidence:** `lib/features/clinics/clinic_repository.dart:1-118`, `lib/features/patient/patient_home_screen.dart:32, 90`.

---

#### Component: `lib/features/clinics/clinic_membership_model.dart` → `ClinicMembershipModel`
- **Role:** Domain model linking a user to a clinic with assigned role (`clinic_admin`, `front_desk_lead`, `triage_coordinator`) and explicit permissions (`update_tally`, `update_status`, `reset_tally`, `manage_staff`, `view_queue`). Document ID: `{userId}_{clinicId}`.
- **Directly affected:**
  - `lib/features/clinics/clinic_membership_repository.dart`
- **Potentially affected:**
  - Role-based authorization and action gates in Admin screens.
- **API impact:** Maps to Firestore `clinic_members` collection.
- **Data impact:** Governs membership records.
- **Security impact:** Critical. Governs who is allowed to increment or reset queue numbers.
- **Runtime impact:** In-memory permission checks (`hasPermission()`).
- **Frontend impact:** Enables or disables admin action buttons based on user permissions.
- **Tests to review:** Membership repository unit tests.
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/features/clinics/clinic_membership_model.dart:1-93`.

---

#### Component: `lib/features/clinics/clinic_membership_repository.dart` → `ClinicMembershipRepository`
- **Role:** Repository managing clinic membership records in Firestore (`clinic_members` collection).
- **Directly affected:**
  - `lib/features/clinics/clinic_membership_model.dart`
  - `lib/core/errors/app_failure.dart` (`ServerFailure`)
- **Potentially affected:**
  - Admin login role elevation check and admin dashboard permission verification.
- **API impact:** Firestore queries on `clinic_members`.
- **Data impact:** Reads/writes membership records.
- **Security impact:** High.
  - *Identified Conflict:* Repository uses composite document ID `{userId}_{clinicId}`, whereas `firestore.rules` expects document ID `{clinicId}` with a `members` map. Attempting to write with this repository against the current rules will be rejected.
- **Runtime impact:** Asynchronous queries for user memberships and permission checks.
- **Frontend impact:** Authorizes or blocks admin dashboard actions.
- **Tests to review:** Membership repository unit tests.
- **Infrastructure impact:** Cloud Firestore database availability.
- **Confidence:** Verified
- **Evidence:** `lib/features/clinics/clinic_membership_repository.dart:1-104`, `firestore.rules:97-124`.

---

#### Component: `lib/features/clinics/queue_session_model.dart` → `QueueSessionModel` & `QueueHistoryEntry`
- **Role:** Data models for queue tracking. `QueueSessionModel` represents a daily session (`{clinicId}_{date}`) with `currentParchaNumber` and `status` (`active`, `paused`, `closed`). `QueueHistoryEntry` provides an immutable audit trail of increments and resets.
- **Directly affected:**
  - `lib/features/clinics/queue_repository.dart`
  - `lib/features/patient/patient_home_screen.dart`
  - `lib/features/clinic/clinic_details_screen.dart`
- **Potentially affected:**
  - Admin dashboard and reset studio screens.
- **API impact:** Maps to `queue_sessions` and `queue_history` Firestore collections.
- **Data impact:** Daily session documents and chronological audit logs.
- **Security impact:** Subject to `firestore.rules` for queue updates and history auditing.
- **Runtime impact:** Real-time updates emitted whenever `currentParchaNumber` changes.
- **Frontend impact:** Drives the live counter display on `PatientHomeScreen` and `ClinicDetailsScreen`.
- **Tests to review:** Queue session model tests.
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/features/clinics/queue_session_model.dart:1-128`.

---

#### Component: `lib/features/clinics/queue_repository.dart` → `QueueRepository`
- **Role:** Real-time Firestore repository for outpatient queue management. Handles `getSession`, `getOrCreateTodaySession`, `incrementParcha` (Firestore transaction), `resetParcha` (Firestore transaction + audit record), `sessionStream`, `sessionsForDateStream`, `historyStream`, and `updateSessionStatus`.
- **Directly affected:**
  - `lib/features/clinics/queue_session_model.dart`
  - `lib/features/patient/patient_home_screen.dart` (calls `sessionsForDateStream`)
  - `lib/features/clinic/clinic_details_screen.dart` (calls `sessionStream`)
  - `lib/core/errors/app_failure.dart` (`ServerFailure`)
- **Potentially affected:**
  - `lib/features/admin/admin_dashboard_screen.dart` (when wired to increment/decrement live parchi counts)
  - `lib/features/admin/admin_reset_studio_screen.dart` (when wired to reset daily tally)
- **API impact:** Firestore transactional writes, stream listeners, and queries.
- **Data impact:** Reads/writes `queue_sessions/{clinicId}_{date}` and appends to `queue_history/{historyId}`.
- **Security impact:** High.
  - Transactions must comply with Firestore rules.
  - *Identified Conflict:* `firestore.rules:142` allows only `+1` increment. `resetParcha()` resets to `0`, which requires rule alignment.
- **Runtime impact:** Real-time stream emissions to all connected patient and admin devices when a token is issued.
- **Frontend impact:** Powers the live "Today's Parchi Count" counter on patient screens.
- **Tests to review:** `test/widget_test.dart`.
- **Infrastructure impact:** Firestore database throughput and transaction concurrency limits.
- **Confidence:** Verified
- **Evidence:** `lib/features/clinics/queue_repository.dart:1-249`, `lib/features/patient/patient_home_screen.dart:106`, `lib/features/clinic/clinic_details_screen.dart:39-42`.

---

### Feature Screens & Presentation

#### Component: `lib/features/patient/patient_home_screen.dart` → `PatientHomeScreen`
- **Role:** Patient discovery home screen under "Clinical Clarity". Shell: `mobile_tab`. Subscribes simultaneously to `ClinicRepository.activeClinicsStream()` and `QueueRepository.sessionsForDateStream(_todayKey)`. Implements clinic search filtering, location header, registered clinic cards, status pills, live parchi counters, and navigation to clinic details.
- **Directly affected:**
  - `lib/app/app.dart` (registered as `/patient/home`)
  - `lib/app/routes/app_routes.dart` (`AppRoutes.patientHome`, navigates to `AppRoutes.patientClinicDetails`)
  - `lib/features/clinics/clinic_repository.dart`
  - `lib/features/clinics/queue_repository.dart`
  - `lib/features/clinics/clinic_model.dart`
  - `lib/core/widgets/status_pill.dart`
  - `lib/core/constants/asset_constants.dart`
- **Potentially affected:**
  - Bottom navigation bar tab switching (Home, My Clinics, Settings).
- **API impact:** Listens to Firestore `clinics` and `queue_sessions` in real time.
- **Data impact:** Reads active clinics and today's session tallies.
- **Security impact:** Requires valid patient session; unauthenticated access handled safely.
- **Runtime impact:** Two active stream subscriptions that must be canceled in `dispose()`.
- **Frontend impact:** Primary user interface for all outpatient discovery.
- **Tests to review:** `test/widget_test.dart` (Test: `PatientHomeScreen renders discovery header and registered clinics`).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/features/patient/patient_home_screen.dart:1-1283`, `lib/app/app.dart:55`.

---

#### Component: `lib/features/clinic/clinic_details_screen.dart` → `ClinicDetailsScreen`
- **Role:** Detailed clinic and live queue inspection screen under "Clinical Clarity". Shell: `mobile_stack` (fixed top app bar with back navigation). Subscribes to `QueueRepository.sessionStream(widget.clinic.id, today)` for real-time counter updates. Features doctor credentials card, live parchi counter, planning guidance, and leave notice cards.
- **Directly affected:**
  - `lib/app/app.dart` (navigated via `AppRoutes.patientClinicDetails`)
  - `lib/shared/models/clinic_model.dart` (`ClinicModel`)
  - `lib/features/clinics/queue_repository.dart`
  - `lib/core/constants/asset_constants.dart`
  - `lib/shared/widgets/shared_widgets.dart` (`LivePulseDot`)
- **Potentially affected:**
  - Visit planning and off-hours notices.
- **API impact:** Listens to Firestore `queue_sessions/{clinicId}_{today}`.
- **Data impact:** Reads current parcha count for a single clinic.
- **Security impact:** Open to authenticated patients.
- **Runtime impact:** Real-time stream subscription disposed on widget unmount.
- **Frontend impact:** High. Main point of contact for patients tracking their live queue position before traveling to the clinic.
- **Tests to review:** `test/widget_test.dart` (Test: `ClinicDetailsScreen renders Today Parchi Count card`).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/features/clinic/clinic_details_screen.dart:1-942`, `lib/app/app.dart:56-67`.

---

#### Component: `lib/features/admin/admin_dashboard_screen.dart` → `AdminDashboardScreen`
- **Role:** Primary administrative dashboard screen under "Clinical Precision". Features counter display, increment/decrement controls, and bottom navigation.
- **Directly affected:**
  - `lib/app/app.dart` (registered as `/admin/dashboard` wrapped in `_AdminThemed`)
  - `lib/app/routes/app_routes.dart` (`AppRoutes.adminDashboard`)
  - `lib/app/theme/app_colors.dart` (`AdminColors`)
- **Potentially affected:**
  - Real-time queue increment operations when wired to `QueueRepository.incrementParcha()`.
- **API impact:** Currently in-memory; will target `queue_sessions` and `queue_history`.
- **Data impact:** Will mutate `currentParchaNumber` in production.
- **Security impact:** High. Must be accessible only to authenticated clinic staff with `update_tally` permission.
- **Runtime impact:** State management for parchi increments.
- **Frontend impact:** The frontline interface used by clinic receptionists to increment patient queue tokens.
- **Tests to review:** `test/widget_test.dart` (Test: `AdminDashboardScreen renders counter and increment/decrement buttons`).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/features/admin/admin_dashboard_screen.dart:1-112`, `lib/app/app.dart:70-71`.

---

#### Component: `lib/features/admin/admin_reset_studio_screen.dart` → `AdminResetStudioScreen`
- **Role:** Administrative studio for end-of-day tally resets and staff audit actions under "Clinical Precision". Shell: `mobile_tab`. Features interactive scenario toolbar (`Reset Dialog`, `Feedback Toast`, `Staff Drawer`), parchi counter, confirmation dialog, and mock audit toasts.
- **Directly affected:**
  - `lib/app/app.dart` (registered as `/admin/reset-studio` wrapped in `_AdminThemed`)
  - `lib/app/routes/app_routes.dart` (`AppRoutes.adminResetStudio`)
  - `lib/app/theme/app_colors.dart` (`AdminColors`)
  - `lib/app/theme/app_spacing.dart` (`AppSpacing`)
  - `lib/core/constants/asset_constants.dart`
- **Potentially affected:**
  - Daily reset workflow when wired to `QueueRepository.resetParcha()`.
- **API impact:** Currently simulates audit toasts; will trigger Firestore reset transactions.
- **Data impact:** Zeroing `currentParchaNumber` and writing `reset` entries to `queue_history`.
- **Security impact:** Critical. Resetting the queue tally is a high-privilege action requiring `reset_tally` permission.
- **Runtime impact:** Timer delays for toast dismissals.
- **Frontend impact:** Reset confirmation modal, feedback toasts, and staff audit drawer.
- **Tests to review:** `test/widget_test.dart` (Test: `AdminResetStudioScreen renders scenario toolbar and reset modal`).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/features/admin/admin_reset_studio_screen.dart:1-1391`, `lib/app/app.dart:72-73`.

---

#### Component: `lib/features/admin/admin_unauthorized_screen.dart` → `AdminUnauthorizedScreen`
- **Role:** Security fallback screen under "Clinical Precision" rendered when a user attempts to access administrative features without required permissions. Shell: `mobile_stack`. Provides "Switch Google Account" and "Request Admin Elevation" actions.
- **Directly affected:**
  - `lib/app/app.dart` (registered as `/admin/unauthorized` wrapped in `_AdminThemed`)
  - `lib/app/routes/app_routes.dart` (`AppRoutes.adminUnauthorized`)
  - `lib/app/theme/app_colors.dart` (`AdminColors`)
  - `lib/app/theme/app_spacing.dart` (`AppSpacing`)
  - `lib/core/constants/asset_constants.dart`
- **Potentially affected:**
  - Access elevation and role reassignment workflows.
- **API impact:** Currently simulates toast messages; will dispatch access request documents to Firestore.
- **Data impact:** None currently.
- **Security impact:** Serves as the security landing page for unprivileged users attempting admin navigation.
- **Runtime impact:** Toast timer callbacks.
- **Frontend impact:** Displays access denied error cards and account switching options.
- **Tests to review:** `test/widget_test.dart` (Test: `AdminUnauthorizedScreen renders access not authorized state`).
- **Infrastructure impact:** None.
- **Confidence:** Verified
- **Evidence:** `lib/features/admin/admin_unauthorized_screen.dart:1-411`, `lib/app/app.dart:74-75`.

---

### Test Infrastructure & Native Build

#### Component: `test/widget_test.dart` → Test Suite
- **Role:** Comprehensive UI regression test suite verifying widget bootstrapping and initial rendering for all 7 application screens (`EasyCheckApp`, `PatientHomeScreen`, `ClinicDetailsScreen`, `AdminLoginScreen`, `AdminDashboardScreen`, `AdminResetStudioScreen`, `AdminUnauthorizedScreen`).
- **Directly affected:**
  - All 7 screens
  - `lib/app/app.dart`
  - `lib/app/theme/app_theme.dart`
  - `lib/shared/models/clinic_model.dart`
  - `lib/firebase_options.dart`
- **Potentially affected:**
  - CI/CD build pipelines and test verification runs (`flutter test`).
- **API impact:** None (runs in test environment with safe Firebase fallback).
- **Data impact:** Injects mocked in-memory models.
- **Security impact:** None.
- **Runtime impact:** Executes widget pump cycles and string assertion matchers.
- **Frontend impact:** Enforces that critical text labels, headers, and icons exist in the widget tree.
- **Tests to review:** `test/widget_test.dart` itself.
- **Infrastructure impact:** Executes on local and CI Flutter runners.
- **Confidence:** Verified
- **Evidence:** `test/widget_test.dart:1-128`.

---

#### Component: `android/app/build.gradle.kts` & `android/app/src/main/AndroidManifest.xml`
- **Role:** Native Android build configuration, package namespace (`com.easycheck.online.easycheck_online`), launch activity configuration, orientation settings, and plugin registrant metadata.
- **Directly affected:**
  - Android APK/Bundle builds (`flutter build apk`)
  - Native plugin registrations (`firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`)
- **Potentially affected:**
  - Native keyboard adjustments (`windowSoftInputMode="adjustResize"`)
  - Multi-window and orientation rendering.
- **API impact:** None.
- **Data impact:** None.
- **Security impact:** Android exported activity permissions and intent filters.
- **Runtime impact:** JVM/Kotlin compilation and Android OS lifecycle.
- **Frontend impact:** Native launch screen (`launch_background.xml`) transitioning into Flutter engine.
- **Tests to review:** Android build verification (`flutter build apk --debug`).
- **Infrastructure impact:** Android SDK versions, Gradle build cache, and Google Services Gradle plugin.
- **Confidence:** Verified
- **Evidence:** `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml:1-45`.

---

## 3. Critical Change Paths

High-risk shared components where a minor modification can ripple across multiple layers of the system:

1. **`lib/app/app.dart` (Routing Table & Argument Passing)**
   - **Affected areas:** `AppRoutes`, `PatientHomeScreen`, `ClinicDetailsScreen`, `_AdminThemed`, and `test/widget_test.dart`.
   - **Reason:** Root route declaration maps route strings to screens and performs the model adaptation from `firestore_clinic.ClinicModel` to `display_clinic.ClinicModel`.
   - **Risk:** **CRITICAL**. Modifying the route map or removing the `arguments is firestore_clinic.ClinicModel` block causes navigation from `PatientHomeScreen` to crash or silently redirect back to home.

2. **`lib/features/clinics/clinic_model.dart` (`toDisplayModel()` Adapter)**
   - **Affected areas:** `PatientHomeScreen`, `ClinicDetailsScreen`, `EasyCheckApp`, and `ClinicRepository`.
   - **Reason:** Bridges the backend Firestore model to the UI presentation model used by `ClinicDetailsScreen`.
   - **Risk:** **HIGH**. Renaming or modifying properties in `ClinicModel` without updating `toDisplayModel()` breaks the transformation between the backend and patient details screen.

3. **`lib/features/clinics/queue_repository.dart` (`date` Format String Contract)**
   - **Affected areas:** `PatientHomeScreen` (`_todayKey`), `ClinicDetailsScreen` (`today`), `QueueSessionModel` composite document ID (`{clinicId}_{date}`), and `QueueHistoryEntry`.
   - **Reason:** All real-time queue queries match on `YYYY-MM-DD`.
   - **Risk:** **HIGH**. Any discrepancy in date formatting (e.g. timezone mismatch, single-digit padding, or differing separators) causes zero live tallies to be found, rendering all live counters as 0 or empty.

4. **`firestore.rules` vs. Repositories Contract**
   - **Affected areas:** `QueueRepository.resetParcha()`, `QueueRepository.incrementParcha()`, `ClinicMembershipRepository`, and `UserProfileRepository`.
   - **Reason:** Security rules enforce strict document ID naming conventions and restrict updates to `+1` increments.
   - **Risk:** **CRITICAL**. Calling `resetParcha()` or using `ClinicMembershipRepository` in production against current `firestore.rules` triggers `PERMISSION_DENIED` errors.

5. **`lib/app/theme/app_theme.dart` & Design Tokens**
   - **Affected areas:** `EasyCheckApp`, `_AdminThemed`, `StatusPill`, `LiveStatusPill`, all 7 screens, and `test/widget_test.dart`.
   - **Reason:** Both themes (`patientTheme` and `adminTheme`) define color schemes, text themes, and component styling.
   - **Risk:** **HIGH**. Renaming theme getters or breaking typography constants prevents compilation across screens and causes `flutter analyze` and `flutter test` failures.

6. **`lib/core/config/env_config.dart` & `firebase_options.dart`**
   - **Affected areas:** `lib/main.dart`, `FirebaseAuth`, `FirebaseFirestore`, Google Sign-In SDK.
   - **Reason:** Controls backend endpoint connections and authentication client IDs.
   - **Risk:** **HIGH**. Modifying OAuth client IDs or project IDs breaks user authentication and cloud synchronization across the entire platform.

---

## 4. Change-Impact Checklist

Before changing any mapped component, verify each of the following items:

- [ ] **Direct consumers checked:** Identified and inspected all files that directly import, instantiate, or call the component.
- [ ] **Indirect consumers checked:** Identified secondary components depending on this behavior through adapters (e.g. `toDisplayModel()`), state streams, or wrapper widgets (e.g. `_AdminThemed`).
- [ ] **API contracts checked:** Verified that serialization (`toMap()`, `fromDocument()`) and request parameters have not changed.
- [ ] **Database/data dependencies checked:** Verified that Firestore collection names (`clinics`, `users`, `clinic_members`, `queue_sessions`, `queue_history`), document ID schemas, and composite indexes match.
- [ ] **Authentication/authorization checked:** Verified that changes do not bypass role checks (`patient` vs `clinic_admin`) or trigger `firestore.rules` permission rejections.
- [ ] **Background jobs/events checked:** Verified that stream listeners (`StreamSubscription`) are properly managed and canceled in `dispose()`.
- [ ] **Frontend consumers checked:** Checked visual rendering, layout bounds, responsive sizing, and design system compliance ("Clinical Clarity" vs "Clinical Precision").
- [ ] **Tests checked:** Reviewed and updated corresponding tests in `test/widget_test.dart`, confirming `flutter test` passes.
- [ ] **Configuration/infrastructure checked:** Verified that `.env`, `.env.example`, `pubspec.yaml`, `firebase.json`, and native Android configurations remain synchronized.
- [ ] **Critical user/admin workflows checked:** Verified end-to-end flows: Patient Google Login → Discovery Home → Clinic Details → Live Parchi Counter, and Admin Login → Access Verification → Dashboard Increment → Reset Studio.

---

## 5. Unknown Dependencies & Architecture Discrepancies

The following items cannot be fully verified from the current static codebase and represent architectural gaps or pending integrations:

1. **`ClinicMembershipRepository` Document ID vs. `firestore.rules` Mismatch:**
   - *Status:* **Unknown / Unverified**
   - *Detail:* In `clinic_membership_repository.dart:11`, document ID is formatted as `${userId}_${clinicId}` with flat attributes (`userId`, `clinicId`, `role`, `permissions`). In `firestore.rules:102`, the document ID is matched as `${clinicId}` with nested map `members[userId]`. Until one of these is aligned, production writes to `clinic_members` will fail.

2. **`QueueRepository.resetParcha()` vs. `firestore.rules` Increment Rule:**
   - *Status:* **Unknown / Unverified**
   - *Detail:* `firestore.rules:142` contains `request.resource.data.currentParchaNumber == resource.data.currentParchaNumber + 1`. This explicitly forbids resetting the count to 0 from client SDKs. Client-side reset will fail unless performed via a trusted Cloud Function, Firebase Admin SDK, or updated security rule.

3. **`users/{uid}.clinicIds` Array Existence:**
   - *Status:* **Unknown / Unverified**
   - *Detail:* `firestore.rules:32` references `clinicId in get(/databases/$(database)/documents/users/$(uid)).data.clinicIds`. However, `UserProfile` (`user_profile_model.dart`) does not contain a `clinicIds` field. It is unknown whether user profile creation documents in production include this array.

4. **Admin Dashboard Live Firebase Connection:**
   - *Status:* **Pending Integration**
   - *Detail:* `admin_dashboard_screen.dart` currently operates with an in-memory counter (`int _parchiCount = 0;`) and does not instantiate `QueueRepository` or `ClinicRepository`. The full live integration described in `project_docs/phase_22_full_integration/ADMIN_BACKEND_INTEGRATION.md` remains pending.

5. **`AppRoutes.patientClinicDetails` Direct Named Route Execution:**
   - *Status:* **Verified Handled via ModalRoute Settings**
   - *Detail:* `app.dart:56-67` extracts arguments from `ModalRoute.of(context)?.settings.arguments`. If navigated to without arguments (e.g. browser URL refresh on web), it falls back to `PatientHomeScreen`.

---

## 6. Maintenance Rule

Whenever project architecture, data contracts, security rules, route tables, or shared models materially change, update `IMPACT-MAP.md` accordingly. Never add speculative guesses; every mapped relationship must cite exact file, class, function, or rule evidence.

