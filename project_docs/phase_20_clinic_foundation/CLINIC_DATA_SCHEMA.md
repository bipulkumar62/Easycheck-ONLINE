# Clinic Data Schema

**Phase:** Task 20 — Clinic Data Model & Membership  
**Project:** EasyCheck Online

## Collection: clinics

**Document ID:** Unique clinic ID (e.g., CLN-84920)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| clinicId | string | Yes | Unique clinic identifier |
| name | string | Yes | Clinic display name |
| address | string | Yes | Clinic address |
| city | string | Yes | City |
| region | string | Yes | Region/state |
| phone | string | Yes | Contact phone |
| email | string | Yes | Contact email |
| description | string | No | Clinic description |
| adminUid | string | Yes | Primary admin UID |
| isActive | boolean | Yes | Clinic active status |
| isOnline | boolean | Yes | Online/offline status |
| createdAt | timestamp | Yes | Creation time |
| updatedAt | timestamp | Yes | Last update |
