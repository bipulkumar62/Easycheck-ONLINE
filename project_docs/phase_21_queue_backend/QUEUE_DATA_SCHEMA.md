# Queue Data Schema

**Phase:** Task 21 — Queue Backend  
**Project:** EasyCheck Online

## Collection: queue_sessions

**Document ID:** Composite: {clinicId}_{date} where date is YYYY-MM-DD

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| clinicId | string | Yes | Associated clinic |
| date | string | Yes | Session date (YYYY-MM-DD) |
| currentParchaNumber | integer | Yes | Next token number |
| status | string | Yes | 'active', 'paused', 'closed' |
| createdAt | timestamp | Yes | Session creation |
| updatedAt | timestamp | Yes | Last update |

## Collection: queue_history

**Document ID:** Auto-generated

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| clinicId | string | Yes | Associated clinic |
| sessionDate | string | Yes | Session date |
| previousNumber | integer | Yes | Number before change |
| newNumber | integer | Yes | Number after change |
| action | string | Yes | 'increment', 'reset', 'correction' |
| performedBy | string | Yes | UID of staff member |
| timestamp | timestamp | Yes | Operation time |

## Valid Statuses

- `active` — Normal operations
- `paused` — Temporarily paused
- `closed` — Day ended

## Valid Actions

- `increment` — Parcha number increased by 1
- `reset` — Daily reset to 0
- `correction` — Manual correction
