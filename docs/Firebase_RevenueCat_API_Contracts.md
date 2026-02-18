# Firebase + RevenueCat Spike API Contracts

## 1) Purpose

Define contract-first API behavior for the Firebase/RevenueCat spike path before implementation.

These contracts are intentionally minimal and non-breaking to existing production routes.

---

## 2) Endpoint Scope

## 2.1 Spike verification endpoint

- **Method:** `POST`
- **Path:** `/users/firebase-auth-spike`
- **Auth headers:**
  - `X-API-Key` (required, existing mechanism retained)
  - `Authorization: Bearer <firebase_id_token>` (required)

---

## 3) Request Contract

### Body

```json
{
  "revenueCatAppUserId": "abc123",
  "platform": "ios",
  "clientVersion": "2.1.0+3",
  "environment": "dev"
}
```

### Validation rules

- `Authorization` must start with `Bearer `
- Firebase token must verify against configured Firebase project
- `environment` must match server environment guardrails (`dev` only during early spike)
- `revenueCatAppUserId` optional in first pass, but if provided must be non-empty string

---

## 4) Success Response Contract

### `200 OK`

```json
{
  "status": "verified",
  "firebaseUid": "abc123",
  "internalUserId": "uuid-v4",
  "isNewLink": false,
  "mappingStatus": "linked",
  "entitlement": {
    "status": "unknown",
    "source": "not_checked"
  },
  "serverTimeUtc": "2026-02-17T00:00:00Z"
}
```

Notes:

- `isNewLink=true` when mapping is first created
- Entitlement can be deferred in initial spike and reported as `unknown`

---

## 5) Error Model

## 5.1 `400 Bad Request`

Used for malformed request/header/body.

```json
{
  "errorCode": "BAD_REQUEST",
  "message": "Missing Authorization header"
}
```

## 5.2 `401 Unauthorized`

Used for invalid/expired Firebase token or failed verification.

```json
{
  "errorCode": "FIREBASE_TOKEN_INVALID",
  "message": "Unable to verify Firebase token"
}
```

## 5.3 `409 Conflict`

Used for identity mapping conflicts if invariants are violated.

```json
{
  "errorCode": "IDENTITY_MAPPING_CONFLICT",
  "message": "firebaseUid already linked to another internal user"
}
```

## 5.4 `500 Internal Server Error`

Used for unexpected backend failures.

```json
{
  "errorCode": "INTERNAL_ERROR",
  "message": "Unexpected server error"
}
```

---

## 6) Logging Contract (Security)

Allowed to log:

- request correlation ID
- firebase UID (if verification succeeded)
- mapping decision (`existing_link` / `new_link`)
- environment/platform metadata

Must never log:

- raw Firebase token
- raw RevenueCat receipt/token material
- API secrets/keys

---

## 7) Idempotency Contract

Repeated valid calls with same `firebaseUid` must:

1. Return same `internalUserId`
2. Never create duplicate user mappings
3. Produce deterministic status (`isNewLink=false` after first success)

---

## 8) Future Contract Extensions (Post-spike)

- Add entitlement snapshot in response (`active/inactive`, product identifiers)
- Optional API-issued short-lived session token return
- Add endpoint for explicit entitlement refresh
