# Re-Word API V2 Endpoint Plan (Performance-First)

## Purpose

Define the proposed V2 API endpoint surface for the game server rewrite with a focus on:

- fewer client round-trips,
- clear identity/session lifecycle,
- explicit idempotency behavior,
- index-backed query patterns.

---

## Design Principles

1. **Single-call bootstrap** for first game render.
2. **Server-side orchestration** over client stitching multiple APIs.
3. **Idempotent writes** for retries/reconnect behavior.
4. **Read models optimized by indexes** (leaderboard/profile reads).
5. **Consistent response envelope + error taxonomy**.

---

## Common Request Requirements

- `Authorization: Bearer <firebase_id_token>`
- `X-API-Key: <hashed api key>`
- `Content-Type: application/json`

Shared metadata (body or headers as needed):

- `platform`
- `locale`
- `timezone`
- `clientVersion`

---

## Endpoint 1 — `POST /v2/game/bootstrap`

### Purpose

Primary startup endpoint. Handles identity bootstrap + session + board payload in one request. UserId is passed in
to see if user already exists.

### Responsibilities

1. Verify Firebase token.
2. Resolve/create `userId` for first-time users.
3. Resolve/create `sessionId` (new or resume).
4. Fetch active board payload.
5. Return entitlement summary + leaderboard context.

### Request (example)

```json
{
  "userId": "UUID-V4"
  "platform": "ios",
  "locale": "en-us",
  "timezone": "America/Los_Angeles",
  "clientVersion": "2.1.0+3",
  "leaderboardTypeId": 1,
  "leaderboardCategoryTypeId": 1,
  "resumeSessionId": null
}
```

### Response (example)

```json
{
  "user": {
    "userId": "uuid-v4",
    "isNewUser": true,
    "userStatusTypeId": 1
  },
  "board": {
    "boardId": "abd123",
    "gridLetters": "TMAV...",
    "wildcardLetters": "EHWSX",
    "startDateUtc": "2026-02-18T00:00:00Z",
    "endDateUtc": "2026-02-19T00:00:00Z"
  },
  "session": {
    "sessionId": "uuid-v4",
    "state": "active",
    "startedAtUtc": "2026-02-18T20:00:00Z"
  },
  "entitlement": {
    "status": "active",
    "source": "revenuecat"
  },
  "leaderboardContext": {
    "userRank": 42,
    "topScores": []
  }
}
```

### Idempotency Notes

- Multiple startup calls with same identity should return same `userId`.
- If `resumeSessionId` is valid and not finalized, return it; else create a new session.

---

## Endpoint 2 — `POST /v2/game/submit`

### Purpose

Finalize a session and persist leaderboard-relevant output.

### Request (example)

```json
{
  "sessionId": "uuid-v4",
  "boardId": "abd123",
  "leaderboardTypeId": 1,
  "leaderboardCategoryTypeId": 1,
  "score": 1250,
  "wordCount": 41,
  "timePlayedSeconds": 732,
  "wildcardUses": 3,
  "completionRate": 78,
  "longestWordLength": 9,
  "words": [
    { "word": "SEISE", "score": 42, "usedWildcards": 1 }
  ]
}
```

### Response (example)

```json
{
  "submitStatus": "accepted",
  "sessionId": "uuid-v4",
  "finalizedAtUtc": "2026-02-18T20:12:00Z",
  "leaderboard": {
    "userRank": 17,
    "topScores": []
  }
}
```

### Idempotency Notes

- Submissions are deduped by `sessionId` + finalized marker.
- Re-sending same payload for finalized session returns deterministic prior result.

---

## Endpoint 3 — `GET /v2/leaderboard`

### Purpose

Read-optimized leaderboard retrieval.

### Query params

- `boardId`
- `leaderboardTypeId`
- `leaderboardCategoryTypeId`
- `limit`
- `offset` (optional)

### Response

Leaderboard slice + optional caller rank block.

---

## Endpoint 4 — `GET /v2/user/profile`

### Purpose

Return user profile + summary stats + status.

### Response Includes

- `userId`, alias/locale/platform
- status/type IDs
- summary counters (optional materialized aggregates)

---

## Endpoint 5 — `POST /v2/user/profile`

### Purpose

Update alias/locale/platform preferences.

### Behavior

- validate alias policy + uniqueness (if enforced)
- update `updatedAtUtc`

---

## ~~Endpoint 6 — `POST /v2/session/heartbeat`~~ — DROPPED (2026-02-18)

> Removed from plan. Not needed for core gameplay. Better monitoring solutions exist.

---

## Error Taxonomy (Recommended)

- `BAD_REQUEST` (400)
- `UNAUTHORIZED` (401)
- `FORBIDDEN` (403)
- `NOT_FOUND` (404)
- `CONFLICT` (409)
- `RATE_LIMITED` (429)
- `INTERNAL_ERROR` (500)

Auth-specific:

- `FIREBASE_TOKEN_INVALID`
- `IDENTITY_MAPPING_CONFLICT`
- `SESSION_ALREADY_FINALIZED`

---

## Index Dependencies by Endpoint

### `/v2/game/bootstrap`

- `user_identity_links.firebaseUid` unique
- `users.userId` unique
- `game_boards.startDateUtc`
- `game_sessions.sessionId` unique

### `/v2/game/submit`

- `game_sessions.sessionId` unique
- `high_scores.highScoreId` unique
- `game_words.boardId + userId + word` unique

### `/v2/leaderboard`

- `high_scores(boardId, leaderboardTypeId, leaderboardCategoryTypeId, score desc, timePlayedSeconds asc)`

### `/v2/user/profile`

- `users.userId` unique
- `high_scores.userId + createdAtUtc`

---

## Session Lifecycle Contract — ✅ LOCKED (2026-02-18)

1. **`sessionId` is server-generated** in `/v2/game/bootstrap`. The client never creates session IDs.
2. Session remains active until submit/finalize.
3. Replay/restart creates a new `sessionId` (server-generated on next bootstrap call).
4. Finalized sessions are immutable for scoring.
5. Client stores `sessionId` locally and sends it on submit.

> **Follow-up task:** Update `board.dart` client-side `Uuid().v4()` calls to use server-returned `sessionId` from bootstrap response when V2 API is available.

---

## Resolved Decisions — ✅ ALL LOCKED (2026-02-18)

1. **Bootstrap includes top-N leaderboard?** → **Always include.** One extra index-backed, cached query. Saves a round-trip. No flag needed.

2. **Keep `high_scores` as dedicated write model?** → **Yes, keep separate from `game_sessions`.** Leaderboard-optimized compound indexes justify the slight duplication.

3. **Require alias uniqueness globally at API level?** → **Yes.** Case-insensitive normalized comparison. Profanity filter + reserved words enforced on create/update.

4. **`session/heartbeat` endpoint?** → **Dropped from plan.** Not needed for core gameplay. Better monitoring solutions exist. Will not ship in V1 or V1.1.
