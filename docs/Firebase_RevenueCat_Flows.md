# Firebase + RevenueCat End-to-End Flows (Spike)

## 1) Purpose

Document sequence flows and failure branches for the spike so implementation and QA share the same behavior expectations.

---

## 2) Primary Success Flow

1. Flutter starts auth spike action (debug/dev gated)
2. Flutter signs in with Firebase Auth
3. Flutter retrieves Firebase ID token
4. Flutter initializes RevenueCat and identifies the same user key
5. Flutter calls `POST /users/firebase-auth-spike`
6. API validates `X-API-Key`
7. API verifies Firebase ID token via Firebase Admin SDK
8. API maps `firebaseUid -> internalUserId` (create or reuse)
9. API returns normalized verified response
10. Flutter records telemetry/result and surfaces success

---

## 3) Trust Handoff Points

- **Client -> API:** token transport only, no trust in client claims
- **API -> Firebase Admin SDK:** source of truth for token validity
- **API -> RevenueCat data:** entitlement source of truth (later phase)

---

## 4) Failure Branches

## 4.1 Firebase sign-in fails (client-side)

- Condition: Firebase SDK fails to authenticate user
- Client behavior: show error, do not call API
- Log category: `auth/firebase_signin_failed`

## 4.2 ID token retrieval fails

- Condition: `getIdToken()` throws or returns invalid token state
- Client behavior: retry once, then fail with explicit message
- Log category: `auth/firebase_token_fetch_failed`

## 4.3 API key/header missing

- Condition: missing `X-API-Key` or malformed `Authorization`
- API result: `400 BAD_REQUEST`
- Log category: `auth/spike_bad_request`

## 4.4 Firebase token verification fails

- Condition: expired/invalid/foreign-project token
- API result: `401 FIREBASE_TOKEN_INVALID`
- Log category: `auth/firebase_verify_failed`

## 4.5 Identity mapping conflict

- Condition: uniqueness invariant violated in persistence layer
- API result: `409 IDENTITY_MAPPING_CONFLICT`
- Log category: `auth/identity_mapping_conflict`

## 4.6 RevenueCat unavailable (spike phase)

- Condition: RevenueCat SDK/network issue while auth token is valid
- Spike policy: treat entitlement as `unknown` and continue auth verification result
- Log category: `billing/revenuecat_unavailable`

---

## 5) Retry Strategy (Spike)

- Client retries: token fetch and one API call retry for transient network only
- API retries: none for auth verification; fail fast on invalid token
- Mapping writes: safe idempotent re-read on unique-index race

---

## 6) Sequence Notes for QA

- Same Firebase user should always resolve same `internalUserId`
- First request may return `isNewLink=true`; subsequent should be `false`
- No sensitive tokens should appear in client or server logs

---

## 7) Observability Events (recommended)

- `SpikeAuthStart`
- `SpikeFirebaseVerified`
- `SpikeIdentityLinked`
- `SpikeIdentityExisting`
- `SpikeAuthFailed` (with reason code)
