# Re-Word MongoDB Schema V2 Blueprint

## Purpose

This document defines the proposed V2 MongoDB schema for the Re-Word backend rewrite.

Design goals:

- Use clear, descriptive domain IDs for app-level references.
- Keep Mongo `_id` for storage/index efficiency.
- Use integer-based type tables where appropriate for fast filtering/grouping.
- Define indexes up front so Compass setup is consistent.

---

## Naming + ID Conventions

- Collections: `plural_snake_case`
- Timestamp fields: `createdAtUtc`, `updatedAtUtc`, `deletedAtUtc`, `lastAuthenticatedAtUtc`
- Mongo internal ID: `_id: ObjectId`
- Domain IDs:
  - `userId`, `boardId`, `sessionId`, `gameWordId`, `highScoreId`
- Type IDs (int):
  - `leaderboardTypeId`, `leaderboardCategoryTypeId`, `userStatusTypeId`, `userIdentityStateTypeId`

> **Recommendation:** Keep both `_id` and descriptive domain IDs. Use domain IDs for cross-collection links.

---

## Collection Matrix

## 1) `users`

Purpose: canonical game user profile.

Core fields:

```json
{
  "_id": "<ObjectId>",
  "userId": "uuid-v4",
  "userLocale": "en-us",
  "userPlatform": "ios",
  "userAlias": "Sprockett",
  "userStatusTypeId": 1,
  "isActive": true,
  "isDeleted": false,
  "createdAtUtc": "Date",
  "updatedAtUtc": "Date",
  "lastSeenAtUtc": "Date",
  "deletedAtUtc": null
}
```

Indexes:

- unique: `{ userId: 1 }`
- unique (optional): `{ userAlias: 1 }` if alias uniqueness required
- index: `{ userStatusTypeId: 1 }`
- index: `{ createdAtUtc: -1 }`

---

## 2) `game_boards`

Purpose: board metadata and deterministic board payload.

```json
{
  "_id": "<ObjectId>",
  "boardId": "abd123",
  "boardHash": "3b7b3e3383dfbf9935c105ab8da5c3edb3545dd8db1f401123552a210b5c75c0",
  "gridLetters": "TMAVAINIEYOTKGSXSIEUEHEGNNEMWNHNWITATURNSTUTEWLXN",
  "wildcardLetters": "EHWSX",
  "estimatedWordCount": 364,
  "estimatedHighScore": 2127,
  "startDateUtc": "Date",
  "endDateUtc": "Date",
  "createdAtUtc": "Date"
}
```

Indexes:

- unique: `{ boardId: 1 }`
- unique: `{ boardHash: 1 }`
- index: `{ startDateUtc: 1 }`
- index: `{ endDateUtc: 1 }`

---

## 3) `game_sessions`

Purpose: one user’s play session on one board/mode.

```json
{
  "_id": "<ObjectId>",
  "sessionId": "uuid-v4",
  "boardId": "abd123",
  "userId": "uuid-v4",
  "leaderboardTypeId": 1,
  "leaderboardCategoryTypeId": 1,
  "startedAtUtc": "Date",
  "endedAtUtc": "Date",
  "timePlayedSeconds": 732,
  "score": 1250,
  "wordCount": 41,
  "wildcardUses": 3,
  "completionRate": 78,
  "longestWordLength": 9,
  "createdAtUtc": "Date",
  "updatedAtUtc": "Date"
}
```

Indexes:

- unique: `{ sessionId: 1 }`
- index: `{ boardId: 1, userId: 1 }`
- index: `{ userId: 1, createdAtUtc: -1 }`
- index: `{ boardId: 1, leaderboardTypeId: 1, score: -1 }`

---

## 4) `game_words`

Purpose: normalized per-word entries (queryable/scorable).

```json
{
  "_id": "<ObjectId>",
  "gameWordId": "uuid-v4",
  "boardId": "abd123",
  "sessionId": "uuid-v4",
  "userId": "uuid-v4",
  "word": "SEISE",
  "score": 42,
  "usedWildcards": 1,
  "createdAtUtc": "Date"
}
```

Indexes:

- unique: `{ gameWordId: 1 }`
- unique: `{ boardId: 1, userId: 1, word: 1 }` (prevent same-word duplicate per user/board)
- index: `{ sessionId: 1, createdAtUtc: 1 }`
- index: `{ boardId: 1, score: -1 }`

---

## 5) `high_scores`

Purpose: leaderboard-ready score records.

```json
{
  "_id": "<ObjectId>",
  "highScoreId": "uuid-v4",
  "boardId": "abd123",
  "sessionId": "uuid-v4",
  "userId": "uuid-v4",
  "leaderboardGameTypeId": 1,
  "leaderboardCategoryTypeId": 1,
  "score": 1250,
  "wordCount": 41,
  "createdAtUtc": "Date"
}
```

Indexes:

- unique: `{ highScoreId: 1 }`
- index: `{ boardId: 1, leaderboardTypeId: 1, leaderboardCategoryTypeId: 1, score: -1 }`
- index: `{ userId: 1, createdAtUtc: -1 }`
- index: `{ leaderboardTypeId: 1, leaderboardCategoryTypeId: 1 }`

---

## 6) `user_identity_links`

Purpose: Firebase/RevenueCat identity mapping to internal user.

```json
{
  "_id": "<ObjectId>",
  "firebaseUid": "abc123",
  "userId": "uuid-v4",
  "revenueCatAppUserId": "abc123",
  "userStatusTypeId": 1,
  "userIdentityStateTypeId": 1,
  "createdAtUtc": "Date",
  "updatedAtUtc": "Date",
  "lastAuthenticatedAtUtc": "Date"
}
```

Indexes:

- unique: `{ firebaseUid: 1 }`
- unique: `{ userId: 1 }`
- unique (if strict 1:1): `{ revenueCatAppUserId: 1 }`
- index: `{ userStatusTypeId: 1, userIdentityStateTypeId: 1 }`

---

## 7) `entitlement_snapshots`

Purpose: immutable/append-oriented entitlement history.

```json
{
  "_id": "<ObjectId>",
  "firebaseUid": "abc123",
  "userId": "uuid-v4",
  "revenueCatAppUserId": "abc123",
  "entitlements": {
    "pro": {
      "isActive": true,
      "productIdentifier": "reword.pro.monthly",
      "expiresAtUtc": "2026-03-17T00:00:00Z"
    }
  },
  "source": "revenuecat",
  "createdAtUtc": "Date"
}
```

Indexes:

- index: `{ userId: 1, createdAtUtc: -1 }`
- index: `{ firebaseUid: 1, createdAtUtc: -1 }`
- index: `{ revenueCatAppUserId: 1, createdAtUtc: -1 }`

---

## Type/Lookup Collections

## 8) `leaderboard_game_types`

```json
{
  "_id": "<ObjectId>",
  "leaderboardGameTypeId": 1,
  "leaderboardGameTypeDescription": "Classic", // Scribe, Wordsmith, Master (tied to game_mode.dart types)
  "isActive": true,
  "sortOrder": 10,
  "createdAtUtc": "Date",
  "updatedAtUtc": "Date"
}
```

Indexes:

- unique: `{ leaderboardTypeId: 1 }`

## 9) `leaderboard_category_types`

```json
{
  "_id": "<ObjectId>",
  "leaderboardCategoryTypeId": 1,
  "leaderboardCategoryTypeDescription": "Daily Leaderboard", // Weekly, Monthly, All Time?
  "isActive": true,
  "createdAtUtc": "Date",
  "updatedAtUtc": "Date"
}
```

Indexes:

- unique: `{ leaderboardCategoryTypeId: 1 }`

## 10) `user_status_types`

```json
{
  "_id": "<ObjectId>",
  "userStatusTypeId": 1,
  "userStatusTypeDescription": "guest", // guest, paid, pro?
  "isActive": true,
  "createdAtUtc": "Date",
  "updatedAtUtc": "Date"
}
```

Indexes:

- unique: `{ userStatusTypeId: 1 }`

## 11) `user_identity_state_types`

```json
{
  "_id": "<ObjectId>",
  "userIdentityStateTypeId": 1,
  "userIdentityStateTypeDescription": "unlinked", // linked
  "isActive": true,
  "createdAtUtc": "Date",
  "updatedAtUtc": "Date"
}
```

Indexes:

- unique: `{ userIdentityStateTypeId: 1 }`

---

## Optional Operations Collections

## 12) `schema_versions`

Tracks schema migration history.

## 13) `audit_events`

Tracks admin/manual mutation events for traceability.

---

## FK/PK Guidance in MongoDB

Mongo does not enforce relational foreign keys.

Use this pattern:

1. Domain IDs act as PK/FK-like references.
2. Enforce integrity through API/business logic.
3. Add unique + supporting indexes to prevent duplicates and speed lookups.
4. Add periodic orphan-check jobs if needed.

---

## Initial Migration Mapping (Current -> V2)

- `games` -> `game_boards`
- `gamewords` -> `game_words`
- `gamestats` -> split into `game_sessions` + `high_scores` (recommended)
- `users` -> `users` (normalize field names)
- new: `user_identity_links`, `entitlement_snapshots`, type tables

---

## Resolved Decisions — ✅ ALL LOCKED (2026-02-18)

1. **`revenueCatAppUserId` strictly 1:1 with `firebaseUid`?** → **Yes.** Use `firebaseUid` as the RevenueCat app user ID. Unique index enforced on both fields in `user_identity_links`.

2. **Keep `high_scores` separate from `game_sessions`?** → **Yes, keep separate.** `game_sessions` tracks all play data. `high_scores` is the leaderboard-optimized write model with its own compound indexes. Slight data duplication is worth the query performance.

3. **Require globally unique `userAlias`?** → **Yes.** Case-insensitive normalized comparison. Enforced at API level with unique index. Profanity filter + reserved words list applied on create/update.

4. **TTL policy?** → **No TTL on core collections.** Game data (boards, sessions, scores, words) and user data are permanent. If `entitlement_snapshots` volume becomes a concern, add a cleanup job later — not a TTL index.

5. **Soft-delete (`deletedAtUtc`) scope?** → **`users` and `user_identity_links` only.** On account deletion: set `deletedAtUtc` + anonymize PII fields. Game data (boards, sessions, scores, words) is historical record and is never deleted.
