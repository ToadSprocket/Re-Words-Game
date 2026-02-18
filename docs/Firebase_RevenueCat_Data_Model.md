# Firebase + RevenueCat Data Model (Spike Planning)

## 1) Purpose

Define canonical identity and entitlement structures before implementation.

This is a contract document, not code.

---

## 2) Core Identity Principles

1. `firebaseUid` is the canonical external identity key.
2. `internalUserId` remains canonical for game-domain records.
3. Mapping between those IDs must be one-to-one and idempotent.
4. RevenueCat identity should use a stable key aligned to `firebaseUid`.

---

## 3) Proposed Canonical Collections

## 3.1 `identity_links`

Purpose: map Firebase identities to internal game user IDs.

Suggested shape:

```json
{
  "_id": "<objectId>",
  "firebaseUid": "abc123",
  "internalUserId": "uuid-v4",
  "revenueCatAppUserId": "abc123",
  "status": "active",
  "createdAtUtc": "2026-02-17T00:00:00Z",
  "updatedAtUtc": "2026-02-17T00:00:00Z",
  "lastAuthAtUtc": "2026-02-17T00:00:00Z"
}
```

Indexes:

- unique(`firebaseUid`)
- unique(`internalUserId`)
- index(`status`)

---

## 3.2 `entitlement_snapshots`

Purpose: persist last-known entitlement state for API decisions and audit trail.

Suggested shape:

```json
{
  "_id": "<objectId>",
  "internalUserId": "uuid-v4",
  "firebaseUid": "abc123",
  "revenueCatAppUserId": "abc123",
  "entitlements": {
    "pro": {
      "isActive": true,
      "productIdentifier": "reword.pro.monthly",
      "expiresAtUtc": "2026-03-17T00:00:00Z"
    }
  },
  "source": "revenuecat",
  "observedAtUtc": "2026-02-17T00:00:00Z"
}
```

Indexes:

- index(`internalUserId`, `observedAtUtc` desc)

---

## 3.3 Existing game collections

No immediate schema rewrite required for spike.

Requirement:

- Existing records keyed by `internalUserId` remain valid.
- Mapping layer translates `firebaseUid -> internalUserId` before game operations.

---

## 4) State Model

## 4.1 Identity state

- `unlinked`: Firebase auth succeeds, no mapping exists yet.
- `linked`: mapping exists and active.
- `suspended`: mapping exists, access restricted by policy.

## 4.2 Entitlement state

- `unknown`: no verified snapshot yet.
- `active`: entitlement valid.
- `inactive`: entitlement absent/expired.

---

## 5) Invariants

1. One `firebaseUid` maps to exactly one `internalUserId`.
2. Mapping write operation is idempotent for repeated auth calls.
3. API authorization decisions must never depend on mutable client-only flags.
4. Raw tokens are never persisted in primary app collections.

---

## 6) Idempotent Mapping Rules

When `firebaseUid` arrives at spike endpoint:

1. If mapping exists: return existing mapping.
2. If not exists: create one new `internalUserId` and persist mapping atomically.
3. If race conflict on unique index: re-read and return winner record.

---

## 7) Data Retention Guidance

- Identity mapping records: long-lived.
- Entitlement snapshots: time-series retention policy (e.g., 90 days hot + archive option).
- Migration logs/audit artifacts: retained per compliance policy.

---

## 8) Open Decisions

1. Should `revenueCatAppUserId` always equal `firebaseUid`? (recommended yes)
2. Should entitlement snapshots be updated sync-on-auth only, or also async via webhooks?
3. Do we store per-platform purchase metadata now or defer to later phase?
