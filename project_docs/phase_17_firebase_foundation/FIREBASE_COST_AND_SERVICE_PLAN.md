# Firebase Cost and Service Plan

**Phase:** Task 17 — Firebase Project Setup & Backend Architecture  
**Project:** EasyCheck Online  
**Date:** October 31, 2026

---

## 1. Firebase Pricing Plan

| Plan | Name | Cost | Suitability |
|------|------|------|-------------|
| Spark | Free tier | $0/month | ✅ MVP — sufficient for single clinic |
| Blaze | Pay-as-you-go | Usage-based | Future — multi-clinic scaling |

**Current Selection:** Spark Plan (Free Tier)

---

## 2. Service-by-Service Cost Analysis

### 2.1 Firebase Authentication

| Metric | Spark Limit | MVP Usage | Status |
|--------|-------------|-----------|--------|
| Monthly active users | 50,000 | < 100 (clinic staff) | ✅ Well within limits |
| Phone auth | 10,000/month | 0 (not used) | ✅ N/A |
| Email/password | 10,000/month | 0 (Google only) | ✅ N/A |

**Estimated monthly cost: $0**

### 2.2 Cloud Firestore

| Metric | Spark Limit | MVP Usage | Status |
|--------|-------------|-----------|--------|
| Stored data | 1 GB | < 10 MB (clinic profiles + queue data) | ✅ Well within limits |
| Reads per day | 50,000 | < 1,000 (single clinic) | ✅ Well within limits |
| Writes per day | 20,000 | < 500 (counter updates, resets) | ✅ Well within limits |
| Deletes per day | 50,000 | 0 | ✅ N/A |

**Estimated monthly cost: $0**

### 2.3 Cloud Firestore (Storage)

| Metric | Spark Limit | MVP Usage | Status |
|--------|-------------|-----------|--------|
| Total storage | 1 GB | < 1 MB (text documents only) | ✅ Well within limits |

**Estimated monthly cost: $0**

### 2.4 Cloud Functions

| Metric | Spark Limit | MVP Usage | Status |
|--------|-------------|-----------|--------|
| Invocations/month | 125,000 | 0 (not used) | ✅ N/A |
| Compute time | 5 GB-seconds/month | 0 | ✅ N/A |

**Estimated monthly cost: $0**

### 2.5 Firebase Storage

| Metric | Spark Limit | MVP Usage | Status |
|--------|-------------|-----------|--------|
| Total storage | 5 GB | 0 (no file uploads) | ✅ N/A |
| Downloads/day | 1 GB | 0 | ✅ N/A |

**Estimated monthly cost: $0**

### 2.6 Firebase App Check

| Metric | Spark Limit | MVP Usage | Status |
|--------|-------------|-----------|--------|
| App Check tokens | 100,000/month | 0 (not enforced yet) | ✅ N/A |

**Estimated monthly cost: $0**

### 2.7 Crashlytics

| Metric | Spark Limit | MVP Usage | Status |
|--------|-------------|-----------|--------|
| Crash reports | Unlimited | Low | ✅ Free |

**Estimated monthly cost: $0**

---

## 3. Total Estimated Monthly Cost

| Service | Spark Cost | Blaze Cost (est.) |
|---------|------------|-------------------|
| Authentication | $0 | $0 (under 50k users) |
| Firestore | $0 | $0 (under limits) |
| Cloud Functions | $0 | $0 (not used) |
| Firebase Storage | $0 | $0 (not used) |
| App Check | $0 | $0 (under limits) |
| Crashlytics | $0 | $0 |
| **Total** | **$0/month** | **$0–$25/month** (at scale) |

---

## 4. Services NOT Enabled (Cost Control)

| Service | Reason for Exclusion | Estimated Cost if Enabled |
|---------|---------------------|---------------------------|
| Cloud Functions | Not required — Security Rules + client atomic increments sufficient | $0–$10/month |
| Firebase Storage | No file upload requirements — images via URL | $0–$5/month |
| Realtime Database | Firestore sufficient | $0–$10/month |
| Cloud Messaging | Not in approved scope | $0 |
| Remote Config | Not in approved scope | $0 |
| Performance Monitoring | Not required for MVP | $0 |
| Test Lab | Not required | $0 |

---

## 5. Cost Monitoring

| Method | Frequency | Tool |
|--------|-----------|------|
| Firebase Console usage dashboard | Weekly | Firebase Console > Usage & billing |
| Budget alerts | Monthly | Firebase Console > Budgets & alerts |
| Quota monitoring | Daily | Firebase Console > Usage |

---

## 6. Scaling Considerations

| Scenario | Current Capacity | Action Required |
|----------|-----------------|-----------------|
| 1 clinic, <100 staff | Spark Plan (free) | None |
| 10 clinics, <1,000 staff | Spark Plan (free) | Monitor usage |
| 100+ clinics, 10,000+ staff | Blaze Plan | Enable billing, monitor costs |
| Multi-region deployment | Blaze Plan | Add Firestore locations |

---

## 7. Cost Optimization Recommendations

| Recommendation | Savings | Implementation |
|---------------|---------|---------------|
| Use `FieldValue.increment()` instead of read-modify-write | Reduces write operations | Phase 18 implementation |
| Cache clinic data locally | Reduces read operations | Phase 19 optimization |
| Enable App Check | Prevents abuse from tampered clients | Production deployment |
| Monitor Firestore index usage | Avoid unused index costs | Ongoing |

---

## 8. Billing Alerts (Recommended for Production)

| Alert Threshold | Action |
|-----------------|--------|
| 50% of any Spark limit | Review usage patterns |
| 80% of any Spark limit | Consider Blaze plan |
| 100% of any Spark limit | Enable billing immediately |
