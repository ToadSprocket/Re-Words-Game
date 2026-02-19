# Phase B Documentation Closeout (Firebase + RevenueCat + API)

## Purpose

This document closes the remaining Phase B planning items and links them to existing specs.

---

## 1) Coverage Matrix for Final Phase B Items

| Item | Status | Primary Doc(s) |
|---|---|---|
| 1. Technical spike plan (Firebase Auth + RevenueCat + API verification) | Complete | `Technical_Specification.md`, `Firebase_RevenueCat_API_Contracts.md`, `Firebase_RevenueCat_Flows.md` |
| 2. Startup/auth/session states and transitions | Complete (this doc) | `Phase_B_Documentation_Closeout.md` |
| 3. iOS/Android requirements checklist (IAP/Apple Sign-In/deletion/privacy) | Complete (this doc) | `Phase_B_Documentation_Closeout.md` |
| 4. Backend contract for Firebase identity + entitlement enforcement | Complete | `Firebase_RevenueCat_API_Contracts.md`, `API_V2_Endpoint_Plan.md`, this doc |
| 5. Alias create/update constraints | Complete (this doc) | `Phase_B_Documentation_Closeout.md` |
| 6. Guest vs Premium feature/mode access mapping | Complete (this doc) | `Phase_B_Documentation_Closeout.md` |
| 7. Entitlement cache/refresh/enforcement model | Complete (this doc) | `Phase_B_Documentation_Closeout.md` |
| 8. Final auth model (Firebase Apple+Google, no email/password at launch) | Complete | `Technical_Specification.md`, this doc |

---

## 2) Startup / Auth / Session State Model

## 2.1 App startup states

1. `startup_uninitialized`
2. `startup_loading_config`
3. `startup_auth_verifying`
4. `startup_bootstrap_call`
5. `startup_ready`
6. `startup_error`

## 2.2 Auth states

1. `auth_unknown`
2. `auth_unauthenticated`
3. `auth_authenticated_firebase`
4. `auth_identity_linked`
5. `auth_blocked` (status/policy)

## 2.3 Session states

1. `session_none`
2. `session_active`
3. `session_finalized`
4. `session_abandoned`

## 2.4 Transition summary

- App launch -> `startup_loading_config`
- Config loaded -> `startup_auth_verifying`
- Firebase token valid -> `startup_bootstrap_call`
- Bootstrap success -> `startup_ready` + `session_active`
- Submit -> `session_finalized`
- Replay/restart -> new `session_active` with new `sessionId`

---

## 3) iOS / Android Compliance Checklist

## 3.1 iOS

- [ ] RevenueCat configured with App Store products/offering IDs
- [ ] Sign in with Apple enabled and tested end-to-end
- [ ] Account deletion flow present and reachable in-app
- [ ] Privacy disclosures aligned with collected data categories
- [ ] Restore purchases flow validated

## 3.2 Android

- [ ] RevenueCat configured with Play Billing products
- [ ] Google Sign-In configured and tested
- [ ] Account deletion flow present and reachable in-app
- [ ] Data safety disclosures aligned with Firebase/RevenueCat usage
- [ ] Purchase restore/sync behavior validated

## 3.3 Cross-platform

- [ ] No email/password launch path in V1 auth UX
- [ ] Guest and Premium gating behavior consistent across platforms
- [ ] Entitlement revocation reflected promptly in premium-protected endpoints

---

## 4) Backend Contract: Identity + Entitlement Enforcement

## 4.1 Identity acceptance contract

- API accepts Firebase ID token in `Authorization` header.
- API verifies token with Firebase Admin SDK.
- API resolves/creates `userId` via `user_identity_links`.

## 4.2 Entitlement acceptance contract

- API receives entitlement context from trusted server-side path (RevenueCat snapshot / verified cache).
- API never trusts client-only premium flags for protected operations.

## 4.3 Premium operation enforcement

Protected endpoints must:

1. verify Firebase identity,
2. resolve `userId`,
3. resolve entitlement state,
4. reject with 403 if entitlement inactive.

---

## 5) Alias Policy Contract

## 5.1 Create/update constraints

- Global uniqueness required (case-insensitive normalized comparison).
- Profanity/inappropriate content filter required.
- Reserved words list required (`admin`, system names, etc.).
- Length bounds: define min/max (recommended: 3–20).

## 5.2 Collision handling

- On collision, return deterministic conflict (`409 ALIAS_UNAVAILABLE`).
- Client should present retry suggestions (e.g., suffix hints).

## 5.3 Rename policy

- Allow rename with cooldown window (recommended: 30 days) **or** admin exception.
- Record alias history optionally for moderation/audit.

---

## 6) Guest vs Premium Access Matrix — ✅ APPROVED

| Feature | Guest (7-day trial) | Premium |
|---|---|---|
| Daily board play | ✅ Allowed (7-day trial window) | ✅ Allowed |
| Core word validation | ✅ Allowed | ✅ Allowed |
| See own score (local) | ✅ Allowed | ✅ Allowed |
| High score submission (leaderboard) | ❌ Blocked | ✅ Allowed |
| Ranked leaderboard participation | ❌ Blocked | ✅ Allowed |
| Board access after 7 days | ❌ Blocked (paywall prompt) | ✅ Allowed |
| Premium-only modes (future) | ❌ Blocked | ✅ Allowed |
| Premium badge/status surfaces | ❌ Blocked | ✅ Allowed |

### Trial Policy

- Guest receives 7 days of free gameplay from account creation date.
- After 7 days without active entitlement, the app prompts the user to subscribe.
- Server enforces trial window via `createdAtUtc` + entitlement state check on protected endpoints.
- Guest can see their own score locally during gameplay but cannot submit to leaderboards.

> **Decision locked:** 2026-02-18

---

## 7) Entitlement Cache / Refresh / Enforcement Model

## 7.1 Client cache

- Keep short-lived entitlement summary for UX rendering.
- Do not treat client cache as enforcement authority.

## 7.2 Server cache

- Store latest entitlement snapshot per `userId`.
- Use bounded TTL for stale detection (recommended: 5–15 minutes for runtime checks).

## 7.3 Refresh policy

- Refresh on bootstrap.
- Refresh on purchase/restore events.
- Refresh on protected endpoint if snapshot stale.

## 7.4 Enforcement rule

- API endpoints enforce premium access from server-validated entitlement state only.

---

## 8) Final Auth Model (Launch)

Launch auth model:

- Firebase Auth providers: **Apple + Google**
- No email/password at launch
- API verifies Firebase token per request (or trusted session bootstrap contract)
- API maps `firebaseUid` -> internal `userId`
- Entitlement state evaluated server-side for premium-protected operations

---

## 9) Phase C Entry Criteria

- [x] Schema V2 locked — all open decisions resolved (2026-02-18)
- [x] API V2 endpoint plan approved — sessionId server-generated, heartbeat dropped (2026-02-18)
- [x] Alias policy approved — globally unique, case-insensitive, profanity filtered (2026-02-18)
- [x] Guest/Premium matrix approved — 7-day trial, no leaderboard for Guest (2026-02-18)
- [x] Entitlement enforcement policy approved — server-validated only (2026-02-18)
- [ ] Mobile compliance checklist assigned + owners named
- [ ] Infrastructure setup complete (Mongo V2, API V2 container, Flutter upgrade)
