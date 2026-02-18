# B.13 - Backend: Active Endpoints After Auth Cleanup

This document captures the current API contract used by the Flutter app after removing legacy password/login/register flows from active usage.

## Scope

- **Client reviewed:** `reword_game/lib/services/api_service.dart`
- **Backend reviewed:** `reword-api/app/routes/*.py`
- **Goal:** document what is actively used, what is mismatched, and what is now deprecated from app usage.

---

## 1) Active client-used endpoints (current)

These endpoints are still called by the app and have matching backend route definitions.

| Method | Client Endpoint | Backend Route File | Backend Route |
|---|---|---|---|
| POST | `/users/register` | `routes/user.py` | `@router.post("/register")` |
| POST | `/users/refresh` | `routes/user.py` | `@router.post("/refresh")` |
| POST | `/game/today` | `routes/game.py` | `@router.post("/today")` |
| POST | `/scores/today?limit={n}` | `routes/scores.py` | `@router.post("/today")` |
| POST | `/scores/gamescores` | `routes/scores.py` | `@router.post("/gamescores")` |
| POST | `/scores/submit` | `routes/scores.py` | `@router.post("/submit")` |

---

## 2) Path mismatches to track (no backend change yet)

These methods are still present in client code, but their paths do not currently align with backend route prefixes.

| Method | Client Endpoint | Backend Endpoint | Status |
|---|---|---|---|
| POST | `/delete-account` | `/users/delete-account` | Mismatch |
| POST | `/validate-session` | `/users/validate-session` | Mismatch |

---

## 3) Deprecated from active app usage

These endpoints may still exist server-side, but are no longer part of active app flow after cleanup.

| Method | Endpoint |
|---|---|
| POST | `/users/login` |
| POST | `/users/updateprofile` |
| POST | `/recovery/auth/request-reset` |
| POST | `/recovery/auth/reset-password` |

---

## 4) Backend-only/admin/reference routes

These are available on the backend but not part of the current app gameplay contract.

- Health: `GET /health/heartbeat`
- Stats (dashboard/API key protected):
  - `GET /stats/requests`
  - `GET /stats/games/total`
  - `GET /stats/games/future`
  - `GET /stats/today/details`
  - `GET /stats/players/summary`
  - `GET /stats/players/distribution`
  - `GET /stats/games/summary`
  - `GET /stats/players/top`

---

## Notes for next phase

1. Decide whether client should migrate to `/users/delete-account` and `/users/validate-session`, or backend should add compatibility aliases.
2. Consider formally deprecating/removing `recovery` and legacy user auth endpoints in backend once app migration is complete.
3. When account/profile flow is rebuilt, update this document as the source of truth for the app/backend contract.
