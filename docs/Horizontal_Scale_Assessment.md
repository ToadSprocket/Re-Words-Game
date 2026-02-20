# Re-Word V2 Horizontal Scale Assessment

**Date:** 2026-02-19  
**Purpose:** Evaluate the scalability of the V2 API architecture and identify bottlenecks at 10x traffic.

---

## Executive Summary

The V1/V2 API is **mostly stateless** and horizontally scalable with careful attention to shared state in Redis and MongoDB. At 10x traffic, the primary bottlenecks will be:
1. **MongoDB write contention** (sessions, token blacklist, game submissions)
2. **Redis single-instance limits** (rate limiting + caching)
3. **Token blacklist synchronization** across API instances

**Recommendation:** Deploy V2 with a **MongoDB replica set** (3 nodes) and consider **Redis Cluster** or separate Redis instances for rate limiting vs caching if traffic exceeds 50K req/min.

---

## 1) Statelessness Analysis

### ✅ Stateless Components (Scale-Friendly)

| Component | Storage | Notes |
|---|---|---|
| **JWT Access Tokens** | None | Self-contained, validated locally |
| **API Key Validation** | None | Hash comparison against secrets |
| **Request Logging** | Middleware | Logs per-request, no shared state |
| **CORS** | Middleware | Config-driven, no state |

### ⚠️ Stateful Components (Shared Dependencies)

| Component | Storage | Scalability Impact |
|---|---|---|
| **Token Blacklist** | MongoDB (`token_blacklist`) | Must be checked on every auth request |
| **Refresh Tokens** | MongoDB (`users.refreshToken`) | Read/write on token refresh |
| **Session Activity Logs** | MongoDB (`sessions`) | Write-heavy on every API call |
| **Rate Limiting** | Redis (FastAPILimiter) | **Shared across all API instances** |
| **Board/Score Caching** | Redis (`cache.py`) | **Shared across all API instances** |

---

## 2) Redis Role & Architecture

### Current Redis Usage

**Single Redis Instance (`reword-redis:6379`)** serves two functions:

1. **Rate Limiting** (FastAPILimiter)
   - Keys: `fastapi-limiter:{route}:{client_ip}`
   - TTL: Short-lived (seconds/minutes)
   - Access pattern: **Read-heavy, frequent writes**

2. **Application Caching** (`cache.py`)
   - Keys:
     - `game:board:{timezone}:{date}` (board payloads)
     - `game:highscores:{gameId}:{limit}` (leaderboard data)
   - TTL: Until midnight (boards), variable (scores)
   - Access pattern: **Read-heavy, infrequent writes**

### Scalability Constraints

- **Single Redis instance** = single point of failure + bottleneck
- **All API instances share the same Redis keys** ✅ (correct for consistency)
- **No Redis persistence configured** (restart = cache loss, but rate limits reset — acceptable)

### Scale Recommendations

| Traffic Level | Redis Strategy |
|---|---|
| **< 10K req/min** | Single Redis 6/7 instance (current) |
| **10K - 50K req/min** | Upgrade to Redis 7, enable persistence (RDB/AOF) |
| **> 50K req/min** | **Split Redis workload:** <br>- Redis Cluster for caching <br>- Separate Redis for rate limiting |

---

## 3) MongoDB Role & Scaling Strategy

### Current MongoDB Usage (V1)

**Single Mongo 6 instance (`reword-mongo:27017`)**, database: `reword`

**Collections + Access Patterns:**

| Collection | Read/Write Ratio | Index Coverage | Bottleneck Risk |
|---|---|---|---|
| `users` | Read-heavy (auth) | `userId`, `userName` | Low (indexed) |
| `games` | Read-heavy (board fetch) | `dateStart`, `dateExpire` | Low (cached) |
| `game_stats` | **Write-heavy** (game submissions) | `userId+gameId`, `gameId+score` | **High** |
| `sessions` | **Write-heavy** (every API call) | `userId`, `requestDateTime` | **High** |
| `token_blacklist` | Read on every auth | `token` (unique) | Medium (grows unbounded) |

### V2 MongoDB Usage (Planned)

**New Mongo 7 instance (`reword-mongo-v2:27018`)**, database: `reword_v2`

**New Collections + Expected Load:**

| Collection | Write Pattern | Bottleneck Risk | Mitigation |
|---|---|---|---|
| `game_sessions` | **High** (every game submit) | **High** | Compound indexes, replica set |
| `high_scores` | **High** (every game submit) | **High** | Leaderboard-optimized indexes |
| `game_words` | **Very High** (every word × session) | **Critical** | Unique constraint + batch writes |
| `users` | Low (create/update alias) | Low | Indexed |
| `user_identity_links` | Low (auth flow only) | Low | Indexed |
| `entitlement_snapshots` | Low (RevenueCat webhooks) | Low | Append-only |

### MongoDB Scaling Path

#### **Phase 1: Single Instance (Current)**
- ✅ Works for < 10K req/min
- ⚠️ Single point of failure
- ⚠️ No read scaling

#### **Phase 2: Replica Set (Recommended for V2 Launch)**
- **3-node replica set:** 1 primary + 2 secondaries
- **Read scaling:** Route read-heavy queries (`games`, `users`) to secondaries
- **High availability:** Automatic failover if primary dies
- **Backup-friendly:** Take backups from secondaries without impacting primary
- **Cost:** ~3x storage, minimal compute overhead
- **Traffic capacity:** Up to 50K req/min

#### **Phase 3: Sharding (Future, if > 100K req/min)**
- **Shard key candidates:**
  - `game_sessions`: shard by `boardId` (distribute by day)
  - `game_words`: shard by `boardId` (keeps words for a board together)
  - `high_scores`: shard by `leaderboardTypeId + leaderboardCategoryTypeId`
- **When needed:** If write throughput exceeds single replica set capacity (~10K writes/sec)
- **Complexity:** High (requires planning, migration, testing)

---

## 4) What Breaks at 10x Traffic?

### Current Estimated Load (based on V1)

| Metric | Current (est.) | 10x |
|---|---|---|
| Requests/min | ~1K | ~10K |
| MongoDB writes/min | ~500 | ~5K |
| Redis ops/min | ~2K | ~20K |
| Concurrent API instances | 1 | 3-5 |

### Bottleneck Analysis

#### **1. MongoDB Write Contention (CRITICAL)**

**Problem:** `game_sessions`, `game_words`, `high_scores` all write on every game submit.

**Breaking point:** Single Mongo instance maxes out at ~10K writes/sec. At 10x traffic, if each game submit = 50 word writes, that's **5K games/min × 50 words = 250K writes/min = 4.2K writes/sec** — still within capacity, but approaching limits.

**Mitigation:**
- ✅ Use compound indexes to minimize write lock contention
- ✅ Deploy Mongo replica set (offload reads to secondaries)
- ⚠️ If growth continues → shard by `boardId`

#### **2. Redis Single-Instance Limit (HIGH)**

**Problem:** Single Redis instance maxes out at ~100K ops/sec. At 10x traffic (20K ops/min = 333 ops/sec), still safe.

**Breaking point:** If traffic spikes to 100K req/min (1.6K req/sec), Redis becomes bottleneck.

**Mitigation:**
- ✅ Upgrade to Redis 7 (better performance)
- ✅ Enable persistence (RDB snapshots for recovery)
- ⚠️ If > 50K req/min → split into separate Redis instances (rate limit vs cache)

#### **3. Token Blacklist Synchronization (MEDIUM)**

**Problem:** Every authenticated request checks `token_blacklist` in MongoDB. At 10x traffic, that's **10K reads/min** to Mongo.

**Breaking point:** MongoDB can handle this (indexed reads are fast), but adds load.

**Mitigation:**
- ✅ TTL index on `expiresAt` (auto-cleanup expired tokens)
- ✅ Move token blacklist to Redis (faster, but requires persistence)
- ⚠️ Alternative: Short-lived JWTs (reduce blacklist size)

#### **4. Session Logging Write Storm (MEDIUM)**

**Problem:** `sessions.log_session()` writes to MongoDB on **every API call** (not just game submits). At 10x traffic, that's **10K writes/min**.

**Breaking point:** Unnecessary write load. V2 should rethink this pattern.

**Mitigation:**
- ✅ **Remove session logging** from hot path (only log significant events)
- ✅ OR batch session writes (buffer in Redis, flush to Mongo every 10 sec)
- ✅ OR move to a separate time-series collection optimized for high-throughput logging

#### **5. API Instance Count (LOW)**

**Problem:** With 1 API container, a single restart = downtime.

**Mitigation:**
- ✅ Deploy **3-5 API instances** behind a load balancer
- ✅ Use rolling restarts (zero downtime deployments)
- ✅ Ensure all instances share the same Redis + MongoDB (already true)

---

## 5) Shared Session Assumptions

### ✅ No Sticky Sessions Required

The API is **stateless** — any API instance can handle any request:
- JWT tokens are self-contained
- Redis keys are shared
- MongoDB is shared
- No in-memory session storage

**Load balancer config:** Round-robin or least-connections (no client affinity needed)

### ⚠️ Token Blacklist Timing Edge Case

If a user logs out (blacklist token) while multiple API instances are running:
1. Instance A blacklists token in MongoDB
2. Instance B might serve 1-2 requests before it checks the blacklist again

**Impact:** Minimal (1-2 second window)

**Mitigation:** If zero-tolerance, cache blacklist in Redis with pub/sub to notify all instances.

---

## 6) Deployment Topology Recommendations

### **Minimal Production Setup (< 10K req/min)**

```
┌──────────────┐
│ Load Balancer│
└──────┬───────┘
       │
   ┌───┴───┬───────┬────────┐
   │       │       │        │
   v       v       v        v
 API-1   API-2   API-3    (standby)
   │       │       │
   └───┬───┴───┬───┘
       │       │
       v       v
    Redis    MongoDB
   (single)  (single)
```

### **Recommended Production Setup (10K - 50K req/min)**

```
┌──────────────┐
│ Load Balancer│
└──────┬───────┘
       │
   ┌───┴───┬───────┬────────┬────────┐
   │       │       │        │        │
   v       v       v        v        v
 API-1   API-2   API-3    API-4    API-5
   │       │       │        │        │
   └───┬───┴───┬───┴────┬───┴────────┘
       │       │        │
       v       v        v
    Redis    MongoDB   MongoDB
   (single)  (Primary) (Secondary × 2)
             └─── Replica Set ───┘
```

### **High-Scale Setup (> 100K req/min)**

```
┌──────────────┐
│ Load Balancer│
└──────┬───────┘
       │
   ┌───┴─── (10+ API instances) ────┐
   │                                 │
   v                                 v
Redis Cluster                MongoDB Sharded Cluster
(3-6 nodes)                  (3+ shards, each a replica set)
```

---

## 7) Monitoring & Alerts

### Key Metrics to Track

| Metric | Warning Threshold | Critical Threshold |
|---|---|---|
| API response time (p95) | > 500ms | > 1000ms |
| MongoDB write latency | > 50ms | > 200ms |
| MongoDB connection pool | > 80% | > 95% |
| Redis memory usage | > 70% | > 90% |
| Redis ops/sec | > 50K | > 80K |
| Token blacklist size | > 10K entries | > 50K entries |
| API instance count | < 2 | < 1 |

---

## 8) Summary Checklist

### ✅ V2 Launch Readiness (10x Traffic)

- [ ] Deploy V2 API with **3 instances minimum**
- [ ] Upgrade Redis to **Redis 7** with persistence enabled
- [ ] Deploy MongoDB as **3-node replica set**
- [ ] Add TTL index to `token_blacklist.expiresAt`
- [ ] Remove or batch `sessions` logging (reduce write storm)
- [ ] Configure load balancer with health checks
- [ ] Set up monitoring for all key metrics above
- [ ] Test failover scenarios (kill primary Mongo, kill Redis, kill 1 API instance)

### ⚠️ Future Scaling (100x Traffic)

- [ ] Migrate to Redis Cluster (if > 50K req/min)
- [ ] Shard MongoDB by `boardId` (if > 100K req/min)
- [ ] Consider moving token blacklist to Redis with persistence
- [ ] Implement connection pooling tuning for Mongo
- [ ] Add CDN for static assets (if applicable)

---

## 9) Cost Estimate

### Current Single-Server Setup
- 1 API instance
- 1 MongoDB instance
- 1 Redis instance
- **Cost:** ~$50-100/month (mid-tier VPS)

### Recommended V2 Setup (10x traffic)
- 3 API instances
- 3 MongoDB instances (replica set)
- 1 Redis instance (upgraded)
- **Cost:** ~$300-500/month (3× larger VPS or separate containers)

### High-Scale Setup (100x traffic)
- 10+ API instances
- MongoDB sharded cluster (9+ nodes)
- Redis Cluster (6 nodes)
- **Cost:** ~$2K-5K/month (managed services or dedicated infra)

---

## 10) Next Steps

1. ✅ Complete this assessment
2. Draft updated `docker-compose.yml` with V2 services
3. Write V2 index creation script
4. Test V2 locally
5. Deploy V2 to server (V1 stays live)
6. Run load tests against V2
7. Monitor for 7 days
8. Cutover traffic from V1 → V2
