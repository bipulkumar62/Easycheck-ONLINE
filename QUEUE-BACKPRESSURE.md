# QUEUE-BACKPRESSURE.md — Queue Backpressure & Overload Protection Audit

> **Project:** EasyCheck Online — Real-time Outpatient Clinic Queue Tracking  
> **Stack:** Flutter 3.x · Cloud Firestore · Firebase Auth · Supabase Edge Functions · Node.js Admin CLI  
> **Audit Date:** 2026-11-14  
> **Auditor Role:** Senior Backend Engineer, Distributed Systems Architect & Production Reliability Auditor  
> **Scope:** Read-only. Zero code modifications.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Project Architecture Overview](#2-project-architecture-overview)
3. [Queue and Workload Discovery](#3-queue-and-workload-discovery)
4. [Producer-Consumer Flow](#4-producer-consumer-flow)
5. [Backpressure Implementation Analysis](#5-backpressure-implementation-analysis)
6. [Queue Capacity and Concurrency](#6-queue-capacity-and-concurrency)
7. [Retry and Failure Handling](#7-retry-and-failure-handling)
8. [Resource Protection](#8-resource-protection)
9. [Observability and Monitoring](#9-observability-and-monitoring)
10. [Real-World Failure Scenarios](#10-real-world-failure-scenarios)
11. [Confirmed Findings and Evidence](#11-confirmed-findings-and-evidence)
12. [Risk Severity Matrix](#12-risk-severity-matrix)
13. [Recommended Mitigations](#13-recommended-mitigations)
14. [Missing Information and Unknowns](#14-missing-information-and-unknowns)
15. [Production Readiness Assessment](#15-production-readiness-assessment)
16. [Final Audit Checklist](#16-final-audit-checklist)

---

## 1. Executive Summary

EasyCheck Online is a **client-side Flutter application** backed by **Firebase Cloud Firestore** (managed BaaS) and a single **Supabase Edge Function** for photo uploads. The project has **no dedicated message broker**, no background job queue, no worker processes, and no server-side application code beyond Firestore security rules and one Edge Function.

The system's "queue" is a **domain concept** (clinic patient parchi/token queue), not an infrastructure message queue. All work is initiated by user interaction on the Flutter client and processed via direct Firestore reads/writes or a single HTTP call to Supabase.

### Key Findings

| Severity | Count |
|----------|:-----:|
| Critical | 1 |
| High | 3 |
| Medium | 4 |
| Low | 2 |
| Informational | 2 |
| **Total** | **12** |

**The most significant risks are:**

1. **Unbounded in-memory notification accumulation** — each patient client stores up to 30 notifications per screen lifetime, but Firestore stream emissions can fire rapidly during bulk admin operations, causing a CPU/memory burst.
2. **No client-side rate limiting on counter taps** — the optimistic counter drain loop can generate unlimited Firestore transactions per second.
3. **Non-transactional session creation race** — two clients can overwrite each other's queue session on first-day-of-use.
4. **Firestore has no application-level rate limiting** — all backpressure is delegated to Firebase's built-in platform limits with no client-side throttling.

---

## 2. Project Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER (Flutter)                    │
│                                                             │
│   ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│   │ Patient Home │  │ Admin Dash   │  │ Auth Screens     │  │
│   │ Screen       │  │ Screen       │  │ (Login/Request)  │  │
│   └──────┬───┬──┘  └──┬───┬───┬──┘  └──────┬───────────┘  │
│          │   │        │   │   │             │              │
│   Firestore  │   Firestore│   │        Firebase Auth       │
│   Streams    │   Txns     │   │                            │
│              │            │   │                            │
└──────────────┼────────────┼───┼────────────────────────────┘
               │            │   │
               ▼            ▼   ▼
┌──────────────────────┐   ┌─────────────────────┐
│   Cloud Firestore    │   │ Supabase Edge Fn     │
│   (Managed BaaS)     │   │ clinic-photo         │
│                      │   │                      │
│ Collections:         │   │ • Verifies Firebase  │
│ • clinics            │   │   ID token           │
│ • clinic_members     │   │ • Validates image    │
│ • queue_sessions     │   │ • Writes to bucket   │
│ • queue_history      │   │ • Returns public URL │
│ • users              │   └─────────────────────┘
│ • admin_access_reqs  │
│ • super_admin_logs   │
└──────────────────────┘
         ▲
         │
┌────────┴─────────────┐
│ Admin CLI (Node.js)  │
│ tools/admin_cli/     │
│ • Runs locally       │
│ • Service account    │
│ • Admin SDK access   │
└──────────────────────┘
```

### Key Architectural Facts

| Aspect | Implementation |
|--------|---------------|
| **Server-side application** | None — Firestore Security Rules + 1 Supabase Edge Function |
| **Message broker** | None |
| **Background job queue** | None |
| **Worker processes** | None |
| **Scheduled tasks** | None |
| **Event consumers** | None (Firestore streams are client-side) |
| **Admin operations** | CLI tool using Admin SDK, run manually |
| **Database** | Cloud Firestore (managed, auto-scaling) |
| **File storage** | Supabase Storage via Edge Function |

---

## 3. Queue and Workload Discovery

### 3.1 Identified Workloads

| # | Workload | Source | Processing | Can Accumulate? | Has Buffer? |
|---|----------|--------|-----------|:---:|:---:|
| W-01 | Parchi counter increment/decrement | Admin UI tap | Synchronous Firestore transaction | Yes — optimistic delta queue | In-memory `_pendingCounterDelta` |
| W-02 | Clinic data streams (patient) | Firestore snapshot listener | Synchronous `setState()` | No — latest snapshot replaces previous | No |
| W-03 | Queue session streams (patient) | Firestore snapshot listener | Synchronous `setState()` | No — latest snapshot replaces previous | No |
| W-04 | Photo upload (doctor/clinic) | Admin UI button | HTTP POST to Supabase Edge Function | No — single request at a time per type | No |
| W-05 | Admin access request submission | Form submit | Single Firestore `set()` | No — blocked by `_submitting` flag | No |
| W-06 | Doctor status/profile updates | Admin UI | Single Firestore `update()` | No — blocked by `_busy` flag | No |
| W-07 | Admin CLI operations | Operator terminal | Firestore transactions via Admin SDK | No — sequential CLI commands | No |
| W-08 | In-app notification generation | Firestore stream callbacks | Synchronous list insertion | Yes — notifications added per stream event | In-memory `_notifications` list (capped at 30) |
| W-09 | Queue session creation | Admin dashboard load | Non-transactional `getOrCreateTodaySession()` | No | No |
| W-10 | Patient account deletion | Settings UI | Sequential multi-step (re-auth → delete profile → delete auth) | No — blocked by `_isDeletingAccount` flag | No |
| W-11 | Authentication (Google Sign-In) | Login screens | Google OAuth flow → Firebase credential | No — blocked by `_isSigningIn` flag | No |
| W-12 | Clinic stream (admin dashboard) | Firestore snapshot listener | Synchronous `setState()` | No — latest snapshot replaces previous | No |

### 3.2 What Processing Capacity Means for This Architecture

Since there is no server-side application layer, "processing capacity" is defined by:

1. **Firestore quotas** — reads/writes per second per document, per collection, and per project.
2. **Supabase Edge Function** — cold start latency, execution timeout, concurrent invocation limits.
3. **Client-side CPU/memory** — Flutter's single-threaded event loop on the mobile device.
4. **Firebase Auth** — token generation and verification rate limits.

The application has **no control** over Firestore's or Supabase's internal backpressure. All protection must come from the client or from Firestore Security Rules.

---

## 4. Producer-Consumer Flow

### 4.1 Parchi Counter (Primary Workload)

This is the application's most latency-sensitive and frequently exercised path.

```
Admin Tap (+1)                           Cloud Firestore
     │                                        │
     ▼                                        │
setState(_count++)                             │
_pendingCounterDelta++                         │
     │                                        │
     ▼                                        │
_drainCounterQueue()                           │
     │                                        │
     ├── if _counterSyncing: return (drop)     │
     │                                        │
     ▼                                        │
_counterSyncing = true                         │
     │                                        │
     ▼                                        │
while (_pendingCounterDelta != 0) ─────────▶ runTransaction()
     │                                   ├── read session doc
     │                                   ├── check status == 'active'
     │                                   ├── write counter + 1
     │                                   └── write history entry
     │                                        │
     ◀─────────────── result ─────────────────┘
     │
setState(_count = result + remaining delta)
_pendingCounterDelta adjusted
     │
     ▼
loop continues until _pendingCounterDelta == 0
     │
_counterSyncing = false
```

**Source:** [admin_dashboard_screen.dart L257-325](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L257-L325)

**Producer:** Admin user tapping the counter button  
**Buffer:** `_pendingCounterDelta` (integer, unbounded in-memory)  
**Consumer:** `_drainCounterQueue()` while-loop  
**Admission control:** None — every tap immediately increments `_pendingCounterDelta`  
**Rate limiting:** None — the while-loop fires Firestore transactions as fast as they complete

### 4.2 Patient Discovery Streams

```
Cloud Firestore                           Patient Home Screen
     │                                         │
     ├── snapshot: clinics collection ────────▶ _processClinicSnapshot()
     │                                    ├── compare with _lastClinicState
     │                                    ├── generate notifications
     │                                    └── setState()
     │                                         │
     ├── snapshot: queue_sessions ────────────▶ _processCountSnapshot()
     │                                    ├── compare with _lastCounts
     │                                    ├── generate notifications
     │                                    └── setState()
     │                                         │
```

**Source:** [patient_home_screen.dart L105-154](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart#L105-L154)

**Producer:** Firestore change events (server-pushed)  
**Consumer:** `listen()` callback on the Flutter main isolate  
**Backpressure:** None — Firestore SDK delivers snapshots at its own pace. Client must process each synchronously.

### 4.3 Photo Upload

```
Admin Picks Image ──▶ Crop ──▶ HTTP POST to Supabase Edge Function
                                     │
                               60-second timeout
                                     │
                          ┌──────────┴──────────┐
                          ▼                     ▼
                     200 OK                  Error
                  (public URL)          (ConnectionFailure
                       │                 / ServerFailure)
                       ▼
              Update clinic doc
              in Firestore
```

**Source:** [clinic_photo_service.dart L59-131](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_photo_service.dart#L59-L131)

**Producer:** Admin user (manual action, one at a time per photo type)  
**Consumer:** Supabase Edge Function  
**Admission control:** `_isUploadingPhoto` / `_isUploadingClinicPhoto` boolean guards  
**Throttling:** Client-side — 5 MB payload limit, 60-second timeout  
**Retry:** None — user must manually retry

---

## 5. Backpressure Implementation Analysis

### 5.1 Client-Side Backpressure

| Mechanism | Status | Evidence |
|-----------|:------:|----------|
| Rate limiting on API calls | ❌ Missing | No throttle/debounce on counter taps or any Firestore write |
| Request admission control | ⚠️ Partial | `_busy` flag blocks concurrent *different* operations; counter taps bypass `_busy` |
| Bounded buffers | ⚠️ Partial | Notifications capped at 30 items; `_pendingCounterDelta` is unbounded |
| Debounce on user input | ❌ Missing | Counter taps fire immediately; search filter runs on every keystroke |
| Exponential backoff | ❌ Missing | No retry logic exists anywhere in the client |
| Circuit breaker | ❌ Missing | No circuit breaker pattern |
| Load shedding | ❌ Missing | No mechanism to reject or defer work |

### 5.2 Server-Side Backpressure

| Mechanism | Status | Evidence |
|-----------|:------:|----------|
| Firestore built-in rate limits | ✅ Platform-managed | 1 write/sec per document (sustained), burst capacity varies |
| Firestore Security Rules validation | ✅ Implemented | 280-line ruleset at [firestore.rules](file:///d:/Easycheck%20ONLINE/firestore.rules) |
| Firebase App Check | ✅ Implemented | Blocks requests from outside the real app ([main.dart L42-54](file:///d:/Easycheck%20ONLINE/lib/main.dart#L42-L54)) |
| Supabase Edge Function timeout | ✅ Platform-managed | Supabase functions have configurable max execution time |
| Photo payload size limit | ✅ Client + server | 5 MB client-side validation + 413 server response ([clinic_photo_service.dart L32, L118](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_photo_service.dart#L32)) |
| Firestore transaction retry | ✅ SDK-managed | Firestore SDK auto-retries contended transactions (up to ~25 times) |

### 5.3 Admin CLI Backpressure

| Mechanism | Status | Evidence |
|-----------|:------:|----------|
| Transaction isolation | ✅ Implemented | All mutations use `db.runTransaction()` ([tools/admin_cli/index.js](file:///d:/Easycheck%20ONLINE/tools/admin_cli/index.js)) |
| Batch size limits | ❌ Missing | `list-clinics`, `list-users` iterate all docs without pagination |
| Sequential execution | ✅ By design | CLI processes one command at a time |
| Rate limiting | ❌ Missing | No rate limiting on Admin SDK calls |

---

## 6. Queue Capacity and Concurrency

### 6.1 In-Memory Queues

| Queue | Location | Max Size | Overflow Behavior | Persistence |
|-------|----------|:--------:|-------------------|:-----------:|
| `_pendingCounterDelta` | Admin dashboard | ∞ (integer) | Never overflows — always increments | None — lost on screen pop |
| `_notifications` | Patient home | 30 | Oldest trimmed via `removeRange(30, ...)` | None — lost on screen pop |
| Firestore SDK write buffer | SDK internal | Platform-managed | SDK throws when offline buffer exceeds limits | SDK offline persistence |

### 6.2 Concurrency Controls

| Resource | Concurrency Limit | Mechanism | Location |
|----------|:-----------------:|-----------|----------|
| Counter sync | 1 | `_counterSyncing` bool | [admin_dashboard_screen.dart L286](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L286) |
| Dashboard mutations | 1 | `_busy` bool | [admin_dashboard_screen.dart L54](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L54) |
| Doctor photo upload | 1 | `_isUploadingPhoto` bool | [admin_dashboard_screen.dart L55](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L55) |
| Clinic photo upload | 1 | `_isUploadingClinicPhoto` bool | [admin_dashboard_screen.dart L56](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L56) |
| Form submission | 1 | `_submitting` bool | [admin_access_request_screen.dart L46](file:///d:/Easycheck%20ONLINE/lib/features/authentication/admin_access_request_screen.dart#L46) |
| Account deletion | 1 | `_isDeletingAccount` bool | [patient_home_screen.dart L60](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart#L60) |
| Google Sign-In | 1 | `_isSigningIn` bool | Login screens |
| Firestore transactions | 25 retries | SDK-managed | Firestore SDK internal |

### 6.3 Firestore Platform Limits (Inherited)

| Limit | Value | Source |
|-------|-------|--------|
| Max sustained writes per document | 1/sec | Firebase documentation |
| Max batch/transaction ops | 500 ops | Firebase documentation |
| Max document size | 1 MiB | Firebase documentation |
| Max offline pending writes | ~10 MB (varies by SDK) | Firebase documentation |
| Max concurrent listeners per client | ~100 (soft) | Firebase documentation |

---

## 7. Retry and Failure Handling

### 7.1 Retry Inventory

| Component | Has Retry? | Mechanism | Max Attempts | Backoff | Jitter |
|-----------|:----------:|-----------|:------------:|:-------:|:------:|
| Firestore transactions | ✅ | SDK-internal | ~25 | Exponential | Yes (SDK) |
| Counter drain loop | ⚠️ Implicit | while-loop retries on next delta | ∞ (until delta=0) | None | None |
| Photo upload | ❌ | Manual user retry | 1 | N/A | N/A |
| Admin access request | ❌ | Manual user retry | 1 | N/A | N/A |
| Google Sign-In init | ✅ | `_initialization = null` on fail allows re-call | ∞ | None | None |
| Doctor/clinic updates | ❌ | Manual user retry | 1 | N/A | N/A |
| Admin CLI commands | ❌ | Manual operator retry | 1 | N/A | N/A |

### 7.2 Failure Amplification Assessment

| Risk | Status | Explanation |
|------|:------:|-------------|
| Infinite retry loops | ⚠️ Potential | The counter drain `while` loop continues until `_pendingCounterDelta == 0`. If Firestore transaction succeeds but the delta is being incremented by taps faster than transactions complete, the loop runs indefinitely. |
| Retry storms | ❌ Not present | No automatic retry after failure — all errors halt and require user re-initiation. |
| Dead-letter queue | ❌ Not applicable | No message queue exists. Failed operations are reported to the user and discarded. |
| Poison messages | ❌ Not applicable | No message deserialization pipeline exists. |
| Duplicate job processing | ⚠️ Potential | The non-transactional `getOrCreateTodaySession()` can create duplicate writes. |
| Idempotency | ⚠️ Partial | Counter increment/decrement are NOT idempotent — each transaction reads current value and adds 1. Access request submission IS idempotent (deterministic doc ID). |

### 7.3 Counter Drain Loop Analysis

The counter drain loop at [admin_dashboard_screen.dart L285-325](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L285-L325) deserves special attention:

```dart
while (_pendingCounterDelta != 0) {
  final delta = _pendingCounterDelta;
  final value = delta > 0
      ? await _queueRepository.incrementParcha(...)
      : await _queueRepository.decrementParcha(...);
  _lastServerCount = value;
  _pendingCounterDelta += delta > 0 ? -1 : 1;
  // ...
}
```

**Observation:** The loop processes one increment/decrement per Firestore transaction. If the admin taps 50 times while `_counterSyncing` is already `true`, the delta accumulates to 50. When the current loop finishes, a *new* call to `_drainCounterQueue()` from the next tap's `unawaited()` will check `_counterSyncing` and return immediately (since the first loop is running). The delta accumulates but is processed sequentially.

**However:** The loop runs one transaction per delta unit, not batching. 50 taps = 50 sequential Firestore transactions, which on a ~200ms RTT network takes ~10 seconds. During those 10 seconds, more taps can accumulate.

---

## 8. Resource Protection

### 8.1 Resource Usage Matrix

| Resource | Protection | Evidence |
|----------|:----------:|----------|
| Client memory | ⚠️ Partial | Notifications capped at 30. Firestore snapshot data is unbounded per emission. |
| Client CPU (main isolate) | ❌ No protection | All stream callbacks, `setState()`, and JSON parsing run on the main thread. |
| Firestore read quota | ❌ No client-side limit | `clinicsStream()` reads ALL clinics without pagination ([clinic_repository.dart L85-98](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_repository.dart#L85-L98)). |
| Firestore write quota | ⚠️ Partial | Counter uses transactions (SDK-managed retry limit). Other writes are single-shot. |
| Network connections | ✅ Managed | Firestore SDK manages a single persistent connection. HTTP client for photos is shared. |
| Photo upload bandwidth | ✅ Protected | 5 MB client-side limit, 60-second timeout ([clinic_photo_service.dart L32-33](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_photo_service.dart#L32-L33)). |
| Firebase Auth tokens | ✅ SDK-managed | Token refresh is handled by Firebase SDK with built-in rate limiting. |
| Supabase Edge Function | ✅ Platform-managed | Supabase enforces concurrent invocation limits and execution timeouts. |

### 8.2 Cross-Workload Resource Sharing

| Shared Resource | Competing Workloads | Isolation? |
|-----------------|---------------------|:----------:|
| `_busy` flag | Counter reset, doctor status, profile edit, timing edit, clinic photo, member management | ❌ No isolation — one blocks all others |
| Firestore connection | Clinic stream, session stream, counter writes, profile reads/writes | ❌ Single shared connection with SDK multiplexing |
| Main UI thread | All `setState()` calls, stream callbacks, JSON parsing, widget rebuilds | ❌ No isolation |
| `http.Client` instance | Photo uploads (doctor + clinic) | ⚠️ Separate `_isUploading*` flags but shared HTTP client |

---

## 9. Observability and Monitoring

### 9.1 Existing Observability

| Metric | Status | Implementation |
|--------|:------:|----------------|
| Queue counter value | ✅ | Live Firestore stream on `queue_sessions` document |
| Queue history / audit trail | ✅ | `queue_history` collection with action, performer, timestamp ([queue_repository.dart L114-124](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L114-L124)) |
| Super admin audit logs | ✅ | `super_admin_audit_logs` collection (append-only) |
| Client crashes | ✅ | Firebase Crashlytics with `runZonedGuarded` ([main.dart L57-91](file:///d:/Easycheck%20ONLINE/lib/main.dart#L57-L91)) |
| App Check attestation | ✅ | Play Integrity (release) / Debug provider ([main.dart L42-54](file:///d:/Easycheck%20ONLINE/lib/main.dart#L42-L54)) |

### 9.2 Missing Observability

| Metric | Status | Impact |
|--------|:------:|--------|
| Queue depth / pending delta | ❌ | Cannot detect when optimistic counter is falling behind |
| Counter sync latency | ❌ | Cannot detect slow Firestore transactions |
| Stream listener count | ❌ | Cannot detect listener leaks |
| Firestore read/write rates | ❌ (client) | Firebase Console provides this, but no client-side awareness |
| Photo upload latency | ❌ | Cannot detect slow Supabase responses |
| Failed operation count | ❌ | Errors shown to user via SnackBar but not logged to analytics |
| Notification generation rate | ❌ | Cannot detect notification storms |
| API error rates by type | ❌ | No structured error telemetry |
| User-facing latency (p50/p95) | ❌ | No performance tracing |
| Offline queue depth | ❌ | Cannot detect when Firestore offline buffer is growing |

---

## 10. Real-World Failure Scenarios

### Scenario A: Sudden Traffic Spike (10x Patients)

| Aspect | Assessment |
|--------|-----------|
| **Status** | **Partially Protected** |
| **Analysis** | Patient traffic means more concurrent `clinicsStream()` and `sessionsForDateStream()` listeners. Each patient client opens 2 Firestore snapshot listeners. At 10x traffic, the Firestore backend handles more read connections. Since this is a managed BaaS, Firestore auto-scales reads. However, every clinic status change triggers a snapshot to *all* connected patients simultaneously. With 1,000 patients, a single doctor status change generates 1,000 snapshot deliveries + 1,000 `_processClinicSnapshot()` calls + up to 1,000 `_addNotification()` calls. |
| **Bottleneck** | Firestore's fan-out delivery capacity and per-project read quotas. |
| **Client impact** | None — each client processes its own snapshot independently. |

### Scenario B: Worker Slows Down (Counter Drain Falls Behind Taps)

| Aspect | Assessment |
|--------|-----------|
| **Status** | **Vulnerable** |
| **Analysis** | If Firestore transaction latency increases (e.g., from 200ms to 2s due to contention or network degradation), the drain loop takes 2s per delta unit. An admin tapping twice per second accumulates unbounded `_pendingCounterDelta`. The optimistic UI shows the buffered count, but the server-confirmed value falls further behind. If the error occurs mid-drain, all pending deltas are discarded and the counter snaps back to `_lastServerCount`. |
| **Impact** | Counter rollback surprise — UI shows 45, then snaps back to 32 after error. Patient confusion if they observed the optimistic value. |
| **Evidence** | [admin_dashboard_screen.dart L316-322](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L316-L322) — on error, `_pendingCounterDelta = 0; _count = _lastServerCount;` |

### Scenario C: All Workers Become Unavailable

| Aspect | Assessment |
|--------|-----------|
| **Status** | **Partially Protected** |
| **Analysis** | There are no "workers" in this architecture. The closest equivalent is "Firestore becomes unavailable." In this case, the Firestore SDK's offline persistence continues to accept writes locally. The client can accumulate offline writes up to the SDK's buffer limit (~10 MB). Once the buffer is full, subsequent writes throw. The client shows error messages via `catch` blocks. |
| **Firestore offline behavior** | Transactions DO NOT work offline — `runTransaction()` will fail. Counter increments will fail immediately. Non-transactional writes queue locally. |
| **Evidence** | No explicit offline handling exists. All repository methods catch `FirebaseException` and throw `ServerFailure` or `ConnectionFailure`. |

### Scenario D: External API Becomes Slow (Supabase Edge Function)

| Aspect | Assessment |
|--------|-----------|
| **Status** | **Protected** |
| **Analysis** | The photo upload has a 60-second timeout ([clinic_photo_service.dart L33](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_photo_service.dart#L33)). If Supabase is slow, the client waits up to 60 seconds, then throws `ConnectionFailure`. The `_isUploadingPhoto` flag prevents concurrent uploads. |
| **Impact** | Admin sees a spinner for up to 60 seconds, then an error. No cascade to other operations (photo upload uses its own `_isUploading*` flags separate from `_busy`). |
| **However** | The `_busy` flag is NOT set during photo upload — so the admin can still tap counter buttons and change doctor status while a photo is uploading. This is correct behavior. |

### Scenario E: Database Connection Exhaustion

| Aspect | Assessment |
|--------|-----------|
| **Status** | **Not Applicable** |
| **Analysis** | Firestore SDK uses a single multiplexed gRPC connection per client, not a connection pool. Connection exhaustion is not possible in the traditional sense. |
| **Note** | However, per-project Firestore quotas (50,000 concurrent connections for Blaze plan) could be reached if the user base grows very large. This is a scaling limit, not a connection pool exhaustion. |

### Scenario F: Retry Storm

| Aspect | Assessment |
|--------|-----------|
| **Status** | **Partially Protected** |
| **Analysis** | No automatic retry exists for application-level operations. The Firestore SDK retries contended transactions internally (up to ~25 times with backoff). If a transaction fails after all retries, the error propagates to the client, which shows a SnackBar and stops. No retry storm can originate from the application layer. |
| **However** | The `GoogleSignIn._ensureInitialized()` method sets `_initialization = null` on failure, allowing unlimited re-initialization attempts. A user rapidly tapping "Sign In" with a broken Google Play Services configuration could trigger repeated initialization attempts. |
| **Evidence** | [google_auth_service.dart L16-33](file:///d:/Easycheck%20ONLINE/lib/features/authentication/google_auth_service.dart#L16-L33) |

### Scenario G: Large Job Payloads

| Aspect | Assessment |
|--------|-----------|
| **Status** | **Protected** |
| **Analysis** | Photo uploads are capped at 5 MB client-side ([clinic_photo_service.dart L67-70](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_photo_service.dart#L67-L70)) and validated server-side (413 response). Firestore documents are limited to 1 MiB by the platform. No other large payloads are sent. |
| **Note** | The `ImagePicker` is configured with `maxWidth: 2400, maxHeight: 2400, imageQuality: 92` which pre-compresses images before the 5 MB check. |

### Scenario H: Recovery After Outage

| Aspect | Assessment |
|--------|-----------|
| **Status** | **Vulnerable** |
| **Analysis** | When Firestore comes back online, the SDK synchronizes all locally-buffered writes simultaneously. If multiple admin devices buffered writes during the outage, all pending writes hit Firestore concurrently. The counter writes use transactions, which will contend heavily and trigger retry cascades. However, `getOrCreateTodaySession()` is non-transactional and could create duplicate or overwritten sessions if multiple devices recover simultaneously. |
| **Additionally** | Patient clients with active `clinicsStream()` listeners will all receive a burst of snapshot events as Firestore delivers the backlog. Each patient processes all snapshots and generates notifications for every change that occurred during the outage. |

### Summary Table

| Scenario | Status |
|----------|--------|
| A: Traffic Spike | ⚠️ Partially Protected |
| B: Worker Slowdown | ❌ Vulnerable |
| C: Workers Unavailable | ⚠️ Partially Protected |
| D: External API Slow | ✅ Protected |
| E: DB Connection Exhaustion | N/A |
| F: Retry Storm | ⚠️ Partially Protected |
| G: Large Payloads | ✅ Protected |
| H: Recovery After Outage | ❌ Vulnerable |

---

## 11. Confirmed Findings and Evidence

### QBP-01: No Rate Limiting on Counter Taps

| Field | Detail |
|-------|--------|
| **Severity** | 🟠 HIGH |
| **Component** | Admin Dashboard — Counter |
| **File** | [admin_dashboard_screen.dart L257-271](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L257-L271) |
| **Evidence** | `_increment()` immediately adds to `_pendingCounterDelta` and calls `unawaited(_drainCounterQueue())` on every tap. No debounce, no throttle, no maximum delta. |
| **Explanation** | A user (or an automated tap tool) can fire hundreds of increments per second. Each tap increments the in-memory delta. When `_counterSyncing` is false, the drain loop begins issuing sequential Firestore transactions at network speed. 100 taps = 100 Firestore transactions, generating 200 document writes (session + history per transaction). |
| **Impact** | Excessive Firestore write costs. On the free Spark plan, this could exhaust the daily write quota. On Blaze, it generates unexpected billing. The single-document write limit (1/sec sustained) means transactions will contend and trigger SDK-internal retries, further amplifying write load. |
| **Trigger** | Fast repeated tapping, especially on a high-latency network where the drain loop runs slowly. |
| **Existing protection** | `_counterSyncing` prevents concurrent loops, but not concurrent delta accumulation. |
| **Recommendation** | Add a debounce (300-500ms) between tap acceptance and drain loop invocation. Batch multiple deltas into a single transaction using `FieldValue.increment(n)` instead of one-at-a-time. |

---

### QBP-02: Non-Transactional Queue Session Creation

| Field | Detail |
|-------|--------|
| **Severity** | 🔴 CRITICAL |
| **Component** | Queue Repository |
| **File** | [queue_repository.dart L46-70](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L46-L70) |
| **Evidence** | `getOrCreateTodaySession()` reads with `getSession()` then writes with `col.doc(...).set()` — not wrapped in a transaction. Compare with `incrementParcha()` at line 80 which correctly uses `fs.runTransaction()`. |
| **Explanation** | Two admin devices opening the dashboard at 9:00 AM on the same day both call `getOrCreateTodaySession()`. Both read `null`. Both create a new session with `currentParchaNumber: 0`. The second write overwrites the first. If the first device already incremented to count=5, the second write resets it to 0. |
| **Impact** | Silent counter reset. Patients who already received parchi numbers see the count restart. |
| **Trigger** | Multiple admin devices or tabs loading the dashboard simultaneously at the start of a day. |
| **Existing protection** | None. |
| **Recommendation** | Wrap in `runTransaction()`: read the session document inside the transaction, only create if it doesn't exist. |

---

### QBP-03: Unbounded Optimistic Counter Delta

| Field | Detail |
|-------|--------|
| **Severity** | 🟡 MEDIUM |
| **Component** | Admin Dashboard — Counter |
| **File** | [admin_dashboard_screen.dart L267-271](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L267-L271) |
| **Evidence** | `_pendingCounterDelta` is an `int` that can grow without bound. No maximum pending delta is enforced. |
| **Explanation** | If a user taps 200 times while the drain loop is running on a slow network, `_pendingCounterDelta` reaches 200. The drain loop must execute 200 sequential Firestore transactions. At 500ms per transaction, this takes 100 seconds. The UI shows the optimistic count (200 ahead of the server). On error, all 200 deltas are discarded, and the count snaps back. |
| **Impact** | Dramatic UI rollback surprise. 100+ seconds of transaction drain time during which the admin sees a stale "syncing" state (though no visual indicator of sync status is shown). |
| **Trigger** | Rapid repeated tapping during network degradation. |
| **Existing protection** | None — `_increment()` always accepts the tap. |
| **Recommendation** | Cap `_pendingCounterDelta` at a reasonable maximum (e.g., 10). Reject taps beyond the cap with a "please wait" message. Show a sync indicator when `_pendingCounterDelta > 0`. |

---

### QBP-04: `clinicsStream()` Reads Entire Collection Without Pagination

| Field | Detail |
|-------|--------|
| **Severity** | 🟡 MEDIUM |
| **Component** | Clinic Repository |
| **File** | [clinic_repository.dart L85-98](file:///d:/Easycheck%20ONLINE/lib/features/clinics/clinic_repository.dart#L85-L98) |
| **Evidence** | `col.snapshots()` with no `.limit()` or `.where()` filter. Every clinic document is returned in every snapshot. |
| **Explanation** | If the platform scales to 500 clinics, every patient client receives all 500 clinic documents on every snapshot. Each snapshot includes the full document data. The client sorts all 500 in-memory on every emission. |
| **Impact** | At scale, excessive Firestore read costs and client-side memory/CPU usage. Currently low risk with a small number of clinics. |
| **Trigger** | Organic growth to hundreds of clinics. |
| **Existing protection** | None. |
| **Recommendation** | Add geographic or city-based filtering, or pagination with `.limit()`. Consider using `activeClinicsStream()` (which filters on `isActive`) as the default patient query. |

---

### QBP-05: Counter Drain Loop Processes One Delta Per Transaction

| Field | Detail |
|-------|--------|
| **Severity** | 🟠 HIGH |
| **Component** | Admin Dashboard — Counter |
| **File** | [admin_dashboard_screen.dart L295-314](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L295-L314) |
| **Evidence** | The while-loop calls `incrementParcha()` or `decrementParcha()` once per iteration, reducing `_pendingCounterDelta` by 1 each time. |
| **Explanation** | 10 rapid taps generate 10 Firestore transactions instead of 1 transaction with `FieldValue.increment(10)`. Each transaction reads the session document, checks status, writes the updated counter, and writes a history entry — 2 document writes per transaction, 20 total writes for 10 taps. |
| **Impact** | 10x write amplification. Each Firestore transaction also triggers a security rule evaluation with `canManageClinic()` which executes 2 additional document reads (membership + clinic). So 10 taps = 10 transactions × (1 session read + 2 rule reads + 1 session write + 1 history write) = 50 document operations instead of 5. |
| **Trigger** | Any use of the counter button. The amplification is proportional to tap frequency. |
| **Existing protection** | Serialization via `_counterSyncing` prevents concurrent loops but not sequential amplification. |
| **Recommendation** | Batch accumulated deltas: use `FieldValue.increment(_pendingCounterDelta)` in a single transaction. Write a single history entry summarizing the batch. |

---

### QBP-06: `_busy` Flag Blocks Counter Reset During Photo Upload

| Field | Detail |
|-------|--------|
| **Severity** | 🟡 MEDIUM |
| **Component** | Admin Dashboard |
| **File** | [admin_dashboard_screen.dart L354-355](file:///d:/Easycheck%20ONLINE/lib/features/admin/admin_dashboard_screen.dart#L354-L355) |
| **Evidence** | `_confirmReset()` checks `if (_pendingCounterDelta != 0 || _counterSyncing)` AND at line 354 checks `if (clinic == null || _busy) return`. The `_busy` flag is set by profile edits, timing changes, and yesterday-count updates. |
| **Explanation** | While the admin is editing their doctor profile (`_busy = true` for ~1-3 seconds), the reset button is disabled. More importantly, while *any* `_busy` operation is in-flight, the reset button, doctor status buttons, and all profile edit buttons are disabled. This is a shared mutex across unrelated operations. |
| **Impact** | UX annoyance — counter reset blocked by unrelated operations. In extreme cases (slow network), the dashboard appears frozen because one slow operation locks everything. |
| **Trigger** | Performing any dashboard mutation during another mutation. |
| **Existing protection** | By design — `_busy` prevents concurrent mutations. But the scope is too broad. |
| **Recommendation** | Use separate concurrency guards per operation category: `_counterBusy`, `_profileBusy`, `_statusBusy`. |

---

### QBP-07: Notification Burst on Firestore Reconnection

| Field | Detail |
|-------|--------|
| **Severity** | 🟠 HIGH |
| **Component** | Patient Home Screen — Notifications |
| **File** | [patient_home_screen.dart L157-283](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart#L157-L283) |
| **Evidence** | `_processClinicSnapshot()` and `_processCountSnapshot()` compare current snapshot with `_lastClinicState` / `_lastCounts` and generate notifications for every difference. |
| **Explanation** | After a network interruption, Firestore delivers a burst of accumulated changes as a single snapshot. If 5 clinics changed doctor status + 8 clinics updated their counter during the offline period, the patient receives up to 13 notifications simultaneously. The `_addNotification()` caps at 30, but the processing loop still runs for all changes, calling `setState()` within the outer `setState()` from the stream listener. |
| **Impact** | Notification flood after network recovery. Patient's notification bell shows 13 unread items all at once, many of which may be stale (e.g., doctor was delayed but is now available again). |
| **Trigger** | Network interruption lasting >1 minute followed by reconnection. |
| **Existing protection** | 30-notification cap prevents unbounded list growth. Baseline priming prevents initial-load flood. But no staleness filter exists — all changes since last snapshot generate notifications regardless of age. |
| **Recommendation** | Add a time-based staleness filter: ignore changes older than N minutes. Or check if the reconnection snapshot contains the *latest* state (it does) and only notify on the *net* difference (e.g., if doctor went delayed→available during the gap, notify only about `available`). |

---

### QBP-08: No Offline Queue Depth Awareness

| Field | Detail |
|-------|--------|
| **Severity** | 🟡 MEDIUM |
| **Component** | All Firestore writes |
| **File** | All repository files |
| **Evidence** | No code checks the Firestore SDK's offline buffer state before issuing writes. |
| **Explanation** | When offline, Firestore SDK buffers writes locally. Counter taps, status changes, and profile updates all accumulate in this buffer. The client has no visibility into how many pending writes exist. If the buffer approaches its limit, the next write throws without warning. |
| **Impact** | Admin operates in offline mode, makes several changes, then receives an unexpected error when the buffer is full. No indication that they are offline or that changes are being buffered. |
| **Trigger** | Extended offline usage (airplane mode, dead zone, server outage). |
| **Existing protection** | Firestore SDK manages the buffer internally. Counter operations use transactions which fail immediately offline (correct behavior — prevents false optimistic state). |
| **Recommendation** | Show an offline indicator when Firestore's connectivity state changes. Warn the admin that counter operations require connectivity. |

---

### QBP-09: Admin CLI Iterates All Documents Without Pagination

| Field | Detail |
|-------|--------|
| **Severity** | 🟢 LOW |
| **Component** | Admin CLI |
| **File** | [tools/admin_cli/index.js L415, L541, L556, L568](file:///d:/Easycheck%20ONLINE/tools/admin_cli/index.js) |
| **Evidence** | `for (const doc of snapshot.docs)` loops iterate entire collections. No `.limit()` or cursor-based pagination. |
| **Explanation** | The `list-clinics`, `list-users`, and similar commands fetch all documents from a collection. With Admin SDK (service account), there are no security-rule read limits, but Firestore still has per-request size limits (10 MiB response). |
| **Impact** | At scale (thousands of users/clinics), the CLI may time out or consume excessive memory. Currently low risk with a small dataset. |
| **Trigger** | Dataset growth to thousands of documents. |
| **Existing protection** | None — designed for small-scale admin operations. |
| **Recommendation** | Add pagination with `limit()` and `startAfter()` for listing commands. |

---

### QBP-10: `decrementParcha()` Missing Session Status Guard

| Field | Detail |
|-------|--------|
| **Severity** | 🟢 LOW |
| **Component** | Queue Repository |
| **File** | [queue_repository.dart L131-171](file:///d:/Easycheck%20ONLINE/lib/features/clinics/queue_repository.dart#L131-L171) |
| **Evidence** | `decrementParcha()` checks `session.currentParchaNumber <= 0` but does NOT check `session.status != 'active'`. Compare with `incrementParcha()` at line 103 which does check. |
| **Explanation** | An admin can decrement the counter on a paused or closed session. The UI checks `_isActive` for the increment button but the decrement button only checks `_count > 0`. The repository accepts the decrement regardless of session status. |
| **Impact** | Queue integrity violation — counter changes during paused/closed state contradict the session lifecycle. |
| **Trigger** | Admin tapping minus on a paused queue. |
| **Existing protection** | UI partially guards with `enabled: _count > 0 && !_busy` but does not check `_isActive` for decrement. |
| **Recommendation** | Add `if (session.status != 'active') throw` guard to `decrementParcha()`. |

---

### QBP-11: Search Filter Runs on Every Keystroke Without Debounce

| Field | Detail |
|-------|--------|
| **Severity** | ℹ️ INFORMATIONAL |
| **Component** | Patient Home Screen — Search |
| **File** | [patient_home_screen.dart L89-91](file:///d:/Easycheck%20ONLINE/lib/features/patient/patient_home_screen.dart#L89-L91) |
| **Evidence** | `_searchController.addListener(() { setState(() => _searchQuery = _searchController.text.trim()); });` — triggers `setState()` on every character. |
| **Explanation** | Each keystroke triggers a full widget rebuild. The `_filtered` getter runs `.where()` on all clinics on every rebuild. With a small number of clinics, this is negligible. |
| **Impact** | Minimal at current scale. Could cause jank with hundreds of clinics. |
| **Trigger** | Typing quickly in the search box. |
| **Existing protection** | `.toList(growable: false)` prevents unnecessary list mutations. |
| **Recommendation** | Add a 200ms debounce on the search input. Use `Timer` to delay `setState()`. |

---

### QBP-12: No Health Check or Heartbeat Mechanism

| Field | Detail |
|-------|--------|
| **Severity** | ℹ️ INFORMATIONAL |
| **Component** | Entire application |
| **File** | N/A |
| **Evidence** | No connectivity monitoring, no periodic health check, no Firestore connection status listener. |
| **Explanation** | The app has no way to detect degraded connectivity proactively. Errors are discovered only when an operation fails. The admin has no visual indicator of connection health. |
| **Impact** | The admin may make decisions based on stale data without knowing the real-time feed has stalled. |
| **Trigger** | Intermittent network issues where the Firestore stream silently disconnects. |
| **Existing protection** | Firestore SDK auto-reconnects. But the time between disconnect and reconnect is invisible to the user. |
| **Recommendation** | Monitor Firestore's `SnapshotsInSync` stream or check `lastActivityTimestamp` to detect stale connections. Show a subtle "reconnecting..." indicator. |

---

## 12. Risk Severity Matrix

| ID | Severity | Component | Finding | Scenario |
|----|:--------:|-----------|---------|----------|
| QBP-02 | 🔴 CRITICAL | Queue Repository | Non-transactional session creation race | H: Recovery |
| QBP-01 | 🟠 HIGH | Admin Counter | No rate limiting on counter taps | B: Slowdown |
| QBP-05 | 🟠 HIGH | Admin Counter | One-at-a-time delta drain (write amplification) | B: Slowdown |
| QBP-07 | 🟠 HIGH | Patient Notifications | Notification burst on reconnection | H: Recovery |
| QBP-03 | 🟡 MEDIUM | Admin Counter | Unbounded optimistic counter delta | B: Slowdown |
| QBP-04 | 🟡 MEDIUM | Clinic Repository | Unfiltered full-collection stream | A: Traffic Spike |
| QBP-06 | 🟡 MEDIUM | Admin Dashboard | `_busy` blocks unrelated operations | General |
| QBP-08 | 🟡 MEDIUM | All Writes | No offline queue depth awareness | C: Workers Down |
| QBP-10 | 🟢 LOW | Queue Repository | Decrement missing status guard | General |
| QBP-09 | 🟢 LOW | Admin CLI | Full-collection iteration without pagination | A: Traffic Spike |
| QBP-11 | ℹ️ INFO | Patient Search | Per-keystroke filter without debounce | A: Traffic Spike |
| QBP-12 | ℹ️ INFO | App-wide | No health check or connection indicator | C: Workers Down |

---

## 13. Recommended Mitigations

### Priority 1 — Critical

| Finding | Mitigation | Trade-offs |
|---------|-----------|------------|
| QBP-02 | Wrap `getOrCreateTodaySession()` in `runTransaction()`. Read session doc transactionally. Only create if `!sessionDoc.exists`. | Adds one extra read per day per clinic. Minimal overhead. Must handle transaction retry correctly. |

### Priority 2 — High

| Finding | Mitigation | Trade-offs |
|---------|-----------|------------|
| QBP-01 + QBP-05 | **Batch counter drain**: Replace the while-loop with a single transaction using `FieldValue.increment(_pendingCounterDelta)`. Add a 300ms debounce between the last tap and drain invocation. Write one history entry per batch with `previousNumber` and `newNumber`. | Changes audit trail granularity — individual taps won't have separate history entries. Acceptable for this use case. |
| QBP-07 | Add a **staleness filter** to notification processing: if the snapshot is a reconnection snapshot (detect via absence of `hasPendingWrites`), suppress notifications for changes where the *current* state matches normal operation. Or simply flag the first post-reconnect snapshot and suppress notifications for it. | Patients may miss legitimate changes that happened during the offline gap. Acceptable if the *current* state is accurate. |

### Priority 3 — Medium

| Finding | Mitigation | Trade-offs |
|---------|-----------|------------|
| QBP-03 | Cap `_pendingCounterDelta` at 10-20. Show "syncing — please wait" when cap is reached. | Admin must wait during high-volume counter updates. This is the correct behavior — it communicates system state honestly. |
| QBP-04 | Add `.where('isActive', isEqualTo: true)` to `clinicsStream()` for patient discovery. Keep the current all-clinics query only for admin/super-admin use. | Patients won't see deactivated clinics in the list. The design comment says deactivated clinics should remain visible — consider keeping inactive clinics but adding `.limit(100)`. |
| QBP-06 | Split `_busy` into per-category flags: `_counterBusy`, `_profileBusy`, `_statusBusy`. Only guard operations against their own category. | More boolean state to manage. Consider using an `enum` or `Set<String>` of active operations instead. |
| QBP-08 | Listen to Firestore connectivity state. Show an "offline" banner when disconnected. Disable counter operations (which require transactions) when offline. | Requires Firestore's `enableNetwork()`/`disableNetwork()` awareness. The SDK doesn't expose offline queue depth directly. |

### Priority 4 — Low / Informational

| Finding | Mitigation | Trade-offs |
|---------|-----------|------------|
| QBP-10 | Add `if (session.status != 'active') throw` to `decrementParcha()`. | Same pattern as `incrementParcha()` — minimal risk. |
| QBP-09 | Add `.limit(100)` and cursor-based pagination to CLI listing commands. | Additional code complexity for currently small datasets. |
| QBP-11 | Add `Timer`-based 200ms debounce to search input. | Slight perceived lag in search results. |
| QBP-12 | Add a `SnapshotsInSync` listener or periodic stream health check. Show a "reconnecting" indicator when no snapshot received for >30 seconds. | Additional complexity. False positives possible if clinics simply haven't changed. |

---

## 14. Missing Information and Unknowns

| Item | Why Unknown | Impact on Audit |
|------|-------------|-----------------|
| Supabase Edge Function source code | Not present in this repository. Only the client-side HTTP call is visible. | Cannot verify server-side rate limiting, timeout, memory limits, or concurrent invocation handling. |
| Firestore project-level quotas (Spark vs. Blaze) | Determined by Firebase Console settings, not in source. | Cannot determine if write quotas are sufficient for observed traffic patterns. |
| Firebase App Check enforcement status | Configuration is in Firebase Console, not in source code. | App Check is activated in code but enforcement may not be turned on. If not enforced, bots could spam Firestore writes. |
| Supabase function cold start latency | Platform-dependent, not in source. | Cannot determine if cold starts add significant latency to photo uploads. |
| Firestore offline persistence configuration | Default SDK settings used — no explicit configuration found. | Cannot determine exact offline buffer size or eviction policy. |
| Number of expected concurrent users | No capacity planning documentation found. | Cannot determine if current architecture handles 10, 100, or 1000 concurrent users. |
| Cloud Functions / Cloud Run presence | No `functions/` directory found. No Cloud Functions deployment. | Confirmed: no server-side background processing exists. |

---

## 15. Production Readiness Assessment

### Scoring

| Category | Score | Max | Rationale |
|----------|:-----:|:---:|-----------|
| Backpressure mechanisms | 2 | 15 | No rate limiting, no debounce, no bounded buffers (except notifications). |
| Resource protection | 8 | 15 | Photo upload has timeout + size limit. `_busy` guards prevent some concurrent mutations. Firestore SDK manages connections. |
| Failure handling | 7 | 15 | All operations catch errors and show user messages. No silent swallowing. But no retry, no backoff, no circuit breaker. |
| Observability | 5 | 15 | Crashlytics + queue audit history exist. No latency metrics, no error analytics, no offline awareness. |
| Capacity management | 4 | 15 | Firestore auto-scales reads. No client-side write batching. Full-collection reads without pagination. |
| Retry safety | 10 | 15 | No application-level retry storms possible. Firestore SDK handles transaction retries safely. |
| Data integrity | 6 | 10 | Transactions protect counter operations. But `getOrCreateTodaySession()` race condition undermines this. |

**Total: 42 / 100**

```
╔═══════════════════════════════════════════════════════════╗
║   QUEUE BACKPRESSURE READINESS:  42 / 100                 ║
║                                                           ║
║   CRITICAL:  1  │  HIGH:    3  │  MEDIUM:  4              ║
║   LOW:       2  │  INFO:    2  │  TOTAL:   12             ║
║                                                           ║
║   Rating: ⚠️  NEEDS IMPROVEMENT                           ║
║                                                           ║
║   The architecture delegates most backpressure to         ║
║   Firebase's managed platform, which is appropriate       ║
║   for a BaaS-backed mobile app. However, client-side      ║
║   protections are insufficient for the counter workload.  ║
╚═══════════════════════════════════════════════════════════╝
```

---

## 16. Final Audit Checklist

| # | Check | Status |
|---|-------|:------:|
| 1 | All documented file paths verified | ✅ |
| 2 | Function and component names match source | ✅ |
| 3 | No unsupported assumptions | ✅ |
| 4 | Confirmed facts separated from recommendations | ✅ |
| 5 | No source code modified | ✅ |
| 6 | No tests claimed as performed | ✅ |
| 7 | Findings specific to actual project | ✅ |
| 8 | Existing documentation preserved | ✅ |
| 9 | No dependencies installed or changed | ✅ |
| 10 | No database records or schemas modified | ✅ |

---

**AUDIT COMPLETE — AWAITING EXPLICIT USER APPROVAL BEFORE ANY MODIFICATIONS.**
