# Re-Word Game Technical Specification (Planning Baseline)

## 1) Purpose

This document is the architecture baseline for the next auth/subscription phase.

It is intended to let any developer joining the project understand:

- What exists today
- What is changing
- Which systems own which responsibilities
- How we will validate changes safely before production rollout

---

## 2) System Context

### Product

- **Application:** Re-Word Game (Flutter client)
- **Backend:** `reword-api` (FastAPI / Python)
- **Data:** MongoDB
- **Subscription/Billing:** RevenueCat
- **Identity provider (target):** Firebase Authentication

### Supported clients

- Mobile: iOS, Android
- Desktop: Windows, macOS, Linux
- Web (where supported by current app paths)

---

## 3) Current-State Architecture (as of this spec)

### Client auth behavior (current)

- Client registers anonymous user through API (`/users/register`)
- API issues custom JWT access token + refresh token
- Client sends `Authorization: Bearer <api_access_token>` and `X-API-Key`
- Client refreshes tokens via `/users/refresh`

### Backend auth behavior (current)

- Backend validates API-issued JWT via `pyjwt`
- Refresh token is persisted in Mongo (`gameUsers`)
- Session/token logic is API-owned

### Billing behavior (current)

- No RevenueCat integration in active client code yet

### Firebase behavior (current)

- No Firebase client/backend integration in active code yet

---

## 4) Target-State Architecture (proposed)

### Trust boundaries

1. **Firebase Auth** owns identity proof (ID token issuance)
2. **RevenueCat** owns entitlement evaluation and subscription state
3. **API** owns game domain identity mapping, authorization checks, and game data

### Target auth flow

1. Flutter authenticates with Firebase
2. Flutter obtains Firebase ID token
3. Flutter identifies user in RevenueCat (same stable user key)
4. Flutter calls API with Firebase token + spike payload
5. API verifies Firebase token with Firebase Admin SDK
6. API maps `firebaseUid` to internal game user record
7. API returns normalized user/session response for game requests

### Data ownership model

- Firebase: identity credential lifecycle
- RevenueCat: entitlement lifecycle
- API/Mongo: game profile, board progress, scores, internal identifiers

---

## 5) Non-Functional Requirements

### Security

- Never log raw auth tokens
- Keep API key validation in place during migration
- Validate issuer/audience/project for Firebase tokens
- Maintain strict server-side entitlement trust (no client-only entitlement decisions)

### Reliability

- Idempotent identity mapping for repeated auth calls
- Retry only where safe (network/transient faults)
- Avoid multi-source identity drift (single canonical user mapping)

### Observability

- Structured logs for auth phase transitions
- Correlation IDs across client -> API calls
- Explicit failure reasons for invalid token / mapping / entitlement mismatch

---

## 6) Environment Strategy

- Separate Firebase projects for `dev`, `staging`, `prod`
- Separate RevenueCat projects/offering configuration per environment
- Separate API secrets/config per environment
- No production data migration without explicit approval gate

---

## 7) Proposed Implementation Stages

1. **Planning + contracts (this phase)**
2. **Spike endpoint + verification path (non-breaking)**
3. **Client spike integration (debug/dev gated)**
4. **Data migration prep + staged rollout plan**
5. **Cutover decision (go/no-go)**

---

## 8) Risks and Mitigations

### Risk: identity duplication across providers

- Mitigation: strict mapping table keyed by `firebaseUid` with unique index

### Risk: entitlement mismatch between API and client

- Mitigation: API uses server-trusted entitlement source/claims, not UI state alone

### Risk: migration causes user data orphaning

- Mitigation: dry-run migration scripts, staging rehearsals, rollback checklist

### Risk: accidental token leakage in logs

- Mitigation: mandatory redaction policy + log review in spike exit criteria

---

## 9) Deliverables for this planning cycle

- `Firebase_RevenueCat_Data_Model.md`
- `Firebase_RevenueCat_API_Contracts.md`
- `Firebase_RevenueCat_Flows.md`
- `Firebase_RevenueCat_Migration_Playbook.md`

---

## 10) Out of Scope (for spike)

- Full user-facing auth UX redesign
- Full legacy endpoint removal
- Production migration execution

Those happen only after spike success and explicit approval.
