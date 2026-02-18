# Firebase + RevenueCat Migration & Cleanup Playbook

## 1) Purpose

Define safe migration and cleanup steps before any production-impacting backend changes.

This playbook is designed to prevent accidental data loss and support staged rollback.

---

## 2) Migration Strategy Overview

### Principle

- **Additive first, destructive last.**

### Stages

1. Introduce new mapping/snapshot structures in `dev`
2. Validate spike path end-to-end in `dev`
3. Rehearse migration in `staging` with sanitized copy
4. Review metrics/logs and approve go/no-go
5. Execute production in controlled window with rollback checkpoints

---

## 3) Data Domains and Actions

## 3.1 Identity records

- Action: create `identity_links` records from verified Firebase users
- Keep existing internal user data intact
- No deletion in early phases

## 3.2 Entitlement records

- Action: create `entitlement_snapshots` from verified RevenueCat state
- Treat as append/update domain; no destructive cleanup in spike

## 3.3 Legacy auth artifacts

- Action: mark legacy paths as deprecated first
- Deletion only after stable cutover window and explicit sign-off

---

## 4) Pre-Migration Checklist

- [ ] Firebase environments reset and documented (`dev/staging/prod`)
- [ ] RevenueCat environments configured and mapped
- [ ] API secrets/service-account paths validated per environment
- [ ] Full backup snapshot of relevant Mongo collections captured
- [ ] Dry-run scripts tested in `dev`
- [ ] Staging rehearsal completed with runbook timing captured
- [ ] Rollback owner and communication channel confirmed

---

## 5) Dry-Run Procedure

1. Export sample/sanitized user set
2. Execute mapping creation script in non-prod
3. Validate invariants:
   - unique `firebaseUid`
   - unique `internalUserId`
   - deterministic re-run output
4. Record failures by reason category
5. Re-run after corrections until deterministic success

---

## 6) Rollback Plan

## 6.1 Rollback triggers

- identity mismatch rate above threshold
- unexpected auth failure spike
- entitlement mismatch impacting access decisions
- migration runtime exceeding change window

## 6.2 Rollback actions

1. Disable new auth endpoint path via config/feature flag
2. Restore known-good API auth behavior
3. Restore affected collections from backup snapshot if needed
4. Publish incident summary and blocked-resume criteria

---

## 7) Cleanup Policy for Legacy Data

Legacy token/session structures should be removed only when all conditions are true:

1. Spike passed and rollout approved
2. Staged rollout complete with no critical regressions
3. Observability window elapsed (recommended minimum 2 release cycles)
4. Written approval recorded for destructive operations

---

## 8) Go / No-Go Decision Gates

## Go if:

- Token verification success rate is stable in target env
- Identity mapping is deterministic and conflict-free
- RevenueCat linkage is stable across re-auth/reinstall tests
- No sensitive token leakage in logs

## No-Go if:

- unresolved identity conflicts
- unexplained auth failures
- incomplete rollback readiness
- missing backups or failed rehearsal artifacts

---

## 9) Operational Ownership (to assign)

- Migration lead:
- Backend verifier:
- Data verifier:
- Rollback authority:
- QA sign-off owner:

(Fill before production run.)
