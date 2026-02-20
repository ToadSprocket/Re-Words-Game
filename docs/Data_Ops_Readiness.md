# Re-Word V2 Data/Ops Readiness Plan

**Date:** 2026-02-19  
**Purpose:** Define backup/restore procedures, index strategy, and monitoring plan for V2 deployment.

---

## 1) Backup & Restore Runbook

### V1 Backup Procedures (Current)

#### MongoDB V1 Backup

**Database:** `reword` on `reword-mongo:27017`

**Method 1: mongodump (Recommended)**

```bash
# Create backup directory with timestamp
BACKUP_DIR="/home/rewordgame/backups/mongo/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Dump V1 database
docker exec reword-mongo mongodump \
  --username=MongoAdmin \
  --password=ALL0Y-accounts-sMob-massages \
  --authenticationDatabase=admin \
  --db=reword \
  --out=/data/backup

# Copy backup from container to host
docker cp reword-mongo:/data/backup/reword $BACKUP_DIR/

# Compress backup
tar -czf $BACKUP_DIR.tar.gz -C $BACKUP_DIR/.. $(basename $BACKUP_DIR)
rm -rf $BACKUP_DIR

# Verify backup exists
ls -lh $BACKUP_DIR.tar.gz
```

**Frequency:** Daily at 3 AM UTC (via cron)

**Retention:** Keep 7 daily, 4 weekly, 3 monthly backups

**Method 2: Docker Volume Snapshot (Cold Backup)**

```bash
# Stop containers
docker-compose -f /home/rewordgame/reword-api/docker-compose.yml down

# Copy volume data
BACKUP_DIR="/home/rewordgame/backups/volumes/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
sudo cp -r /var/lib/docker/volumes/reword-api_mongodb_data/_data $BACKUP_DIR/mongodb_data
sudo cp -r /var/lib/docker/volumes/reword-api_redis_data/_data $BACKUP_DIR/redis_data

# Restart containers
docker-compose -f /home/rewordgame/reword-api/docker-compose.yml up -d

# Compress
tar -czf $BACKUP_DIR.tar.gz -C $BACKUP_DIR/.. $(basename $BACKUP_DIR)
```

**⚠️ Downside:** Requires downtime (use mongodump for hot backups)

#### Redis V1 Backup

**Current:** No persistence enabled (acceptable — Redis is cache-only)

**For V2:** Enable RDB snapshots

```bash
# Add to Redis config or docker-compose
# - save 900 1      # Save after 900 sec if 1 key changed
# - save 300 10     # Save after 300 sec if 10 keys changed
# - save 60 10000   # Save after 60 sec if 10000 keys changed

# Backup Redis RDB file
docker cp reword-redis:/data/dump.rdb /home/rewordgame/backups/redis/dump_$(date +%Y%m%d_%H%M%S).rdb
```

---

### V2 Backup Procedures (New)

#### MongoDB V2 Backup

**Database:** `reword_v2` on `reword-mongo-v2:27018`

**Script:** `/home/rewordgame/backups/scripts/backup_mongo_v2.sh`

```bash
#!/bin/bash
# backup_mongo_v2.sh

BACKUP_BASE="/home/rewordgame/backups/mongo_v2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"
MONGO_USER="MongoAdmin"
MONGO_PASS="ALL0Y-accounts-sMob-massages"

echo "Starting MongoDB V2 backup: $TIMESTAMP"

# Create backup directory
mkdir -p $BACKUP_DIR

# Dump V2 database
docker exec reword-mongo-v2 mongodump \
  --username=$MONGO_USER \
  --password=$MONGO_PASS \
  --authenticationDatabase=admin \
  --db=reword_v2 \
  --out=/data/backup

# Copy from container
docker cp reword-mongo-v2:/data/backup/reword_v2 $BACKUP_DIR/

# Compress
tar -czf $BACKUP_DIR.tar.gz -C $BACKUP_BASE $TIMESTAMP

# Remove uncompressed backup
rm -rf $BACKUP_DIR

# Verify
if [ -f "$BACKUP_DIR.tar.gz" ]; then
    SIZE=$(du -h $BACKUP_DIR.tar.gz | cut -f1)
    echo "✅ Backup complete: $BACKUP_DIR.tar.gz ($SIZE)"
else
    echo "❌ Backup failed!"
    exit 1
fi

# Cleanup old backups (keep last 7 days)
find $BACKUP_BASE -name "*.tar.gz" -mtime +7 -delete

echo "Backup retention: $(ls -1 $BACKUP_BASE/*.tar.gz | wc -l) backups"
```

**Cron Schedule:**

```cron
# MongoDB V2 backup - daily at 3 AM UTC
0 3 * * * /home/rewordgame/backups/scripts/backup_mongo_v2.sh >> /var/log/backup_mongo_v2.log 2>&1
```

---

### Restore Procedures

#### Restore MongoDB V1

```bash
# Extract backup
BACKUP_FILE="/home/rewordgame/backups/mongo/20260219_030000.tar.gz"
tar -xzf $BACKUP_FILE -C /tmp/

# Restore to V1 database
docker exec -i reword-mongo mongorestore \
  --username=MongoAdmin \
  --password=ALL0Y-accounts-sMob-massages \
  --authenticationDatabase=admin \
  --db=reword \
  --drop \
  /tmp/20260219_030000/reword

# Verify
docker exec reword-mongo mongosh \
  -u MongoAdmin \
  -p ALL0Y-accounts-sMob-massages \
  --authenticationDatabase admin \
  --eval "db.getSiblingDB('reword').users.countDocuments()"
```

#### Restore MongoDB V2

```bash
# Extract backup
BACKUP_FILE="/home/rewordgame/backups/mongo_v2/20260219_030000.tar.gz"
tar -xzf $BACKUP_FILE -C /tmp/

# Copy backup into container
docker cp /tmp/20260219_030000/reword_v2 reword-mongo-v2:/data/restore/

# Restore to V2 database
docker exec -i reword-mongo-v2 mongorestore \
  --username=MongoAdmin \
  --password=ALL0Y-accounts-sMob-massages \
  --authenticationDatabase=admin \
  --db=reword_v2 \
  --drop \
  /data/restore/reword_v2

# Verify
docker exec reword-mongo-v2 mongosh \
  -u MongoAdmin \
  -p ALL0Y-accounts-sMob-massages \
  --authenticationDatabase admin \
  --eval "db.getSiblingDB('reword_v2').users.countDocuments()"
```

---

### Disaster Recovery Testing

**Quarterly DR Drill:**

1. Take a production backup
2. Restore to a test environment
3. Verify all collections present
4. Verify document counts match
5. Run sample queries
6. Document time-to-restore

**Success Criteria:**
- Restore completes in < 30 minutes
- All data intact
- API can connect and serve requests

---

## 2) Index Strategy Review

### V1 Indexes (Current)

From `reword-utilities/MongoTools/create_indexes.py`:

| Collection | Index | Type | Notes |
|---|---|---|---|
| `users` | `userId` | Single | ✅ Primary lookup |
| `users` | `userName` | Single, unique | ✅ Login |
| `users` | `emailAddress` | Single, sparse | ✅ Recovery |
| `games` | `dateStart, dateExpire` | Compound | ✅ Board fetch |
| `game_stats` | `userId, gameId` | Compound | ✅ User submissions |
| `game_stats` | `gameId, score desc` | Compound | ✅ Leaderboards |
| `game_stats` | `gameId, timestamp` | Compound | ⚠️ Rarely used? |
| `sessions` | `userId` | Single | ⚠️ Write-heavy collection |
| `sessions` | `requestDateTime` | Single | ⚠️ Rarely queried |
| `token_blacklist` | `token` | Single, unique | ✅ Auth check |
| `token_blacklist` | `expiresAt` | Single | ⚠️ **Missing TTL index** |
| `token_blacklist` | `userId` | Single | ⚠️ Rarely used |

**Issues:**
1. ❌ `token_blacklist.expiresAt` should be a **TTL index** (auto-delete expired tokens)
2. ⚠️ `sessions` collection has 2 indexes but is write-heavy — consider dropping or archiving
3. ⚠️ `game_stats.timestamp` index may not be used enough to justify write overhead

---

### V2 Indexes (Planned)

From `docs/Schema_V2_Blueprint.md`:

#### **Collection: `users`**
- `{ userId: 1 }` unique ✅
- `{ userAlias: 1 }` unique (if enforced) ✅
- `{ userStatusTypeId: 1 }` ✅
- `{ createdAtUtc: -1 }` ✅

#### **Collection: `game_boards`**
- `{ boardId: 1 }` unique ✅
- `{ boardHash: 1 }` unique ✅
- `{ startDateUtc: 1 }` ✅
- `{ endDateUtc: 1 }` ✅

#### **Collection: `game_sessions`**
- `{ sessionId: 1 }` unique ✅
- `{ boardId: 1, userId: 1 }` ✅
- `{ userId: 1, createdAtUtc: -1 }` ✅
- `{ boardId: 1, leaderboardGameTypeId: 1, score: -1 }` ✅

#### **Collection: `game_words`**
- `{ gameWordId: 1 }` unique ✅
- `{ boardId: 1, userId: 1, word: 1 }` unique ✅ **Critical for dedup**
- `{ sessionId: 1, createdAtUtc: 1 }` ✅
- `{ boardId: 1, score: -1 }` ✅

#### **Collection: `high_scores`**
- `{ highScoreId: 1 }` unique ✅
- `{ boardId: 1, leaderboardGameTypeId: 1, leaderboardCategoryTypeId: 1, score: -1 }` ✅ **Primary leaderboard index**
- `{ userId: 1, createdAtUtc: -1 }` ✅
- `{ leaderboardGameTypeId: 1, leaderboardCategoryTypeId: 1 }` ✅

#### **Collection: `user_identity_links`**
- `{ firebaseUid: 1 }` unique ✅
- `{ userId: 1 }` unique ✅
- `{ revenueCatAppUserId: 1 }` unique (if 1:1) ✅
- `{ userStatusTypeId: 1, userIdentityStateTypeId: 1 }` ✅

#### **Collection: `entitlement_snapshots`**
- `{ userId: 1, createdAtUtc: -1 }` ✅
- `{ firebaseUid: 1, createdAtUtc: -1 }` ✅
- `{ revenueCatAppUserId: 1, createdAtUtc: -1 }` ✅

#### **Type Tables (all need unique index on typeId)**
- `{ leaderboardGameTypeId: 1 }` unique ✅
- `{ leaderboardCategoryTypeId: 1 }` unique ✅
- `{ userStatusTypeId: 1 }` unique ✅
- `{ userIdentityStateTypeId: 1 }` unique ✅

---

### Index Creation Script for V2

**File:** `reword-utilities/MongoTools/create_indexes_v2.py`

```python
import sys
import os
import logging
from pymongo.errors import OperationFailure

# Set up path to import database module
sys.path.append(os.path.expanduser("~/game-utils"))
from database import get_mongo_client

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

def create_v2_indexes():
    """
    Create indexes for MongoDB V2 collections to improve query performance.
    """
    try:
        # Connect to V2 database
        client = get_mongo_client(port=27018)  # V2 Mongo on port 27018
        db = client["reword_v2"]
        
        logger.info("Connected to MongoDB V2 on port 27018")
        
        # ====== Collection: users ======
        logger.info("Creating indexes for 'users'...")
        db.users.create_index("userId", unique=True, background=True)
        db.users.create_index("userAlias", unique=True, sparse=True, background=True)  # Allow nulls
        db.users.create_index("userStatusTypeId", background=True)
        db.users.create_index([("createdAtUtc", -1)], background=True)
        
        # ====== Collection: game_boards ======
        logger.info("Creating indexes for 'game_boards'...")
        db.game_boards.create_index("boardId", unique=True, background=True)
        db.game_boards.create_index("boardHash", unique=True, background=True)
        db.game_boards.create_index("startDateUtc", background=True)
        db.game_boards.create_index("endDateUtc", background=True)
        
        # ====== Collection: game_sessions ======
        logger.info("Creating indexes for 'game_sessions'...")
        db.game_sessions.create_index("sessionId", unique=True, background=True)
        db.game_sessions.create_index([("boardId", 1), ("userId", 1)], background=True)
        db.game_sessions.create_index([("userId", 1), ("createdAtUtc", -1)], background=True)
        db.game_sessions.create_index([("boardId", 1), ("leaderboardGameTypeId", 1), ("score", -1)], background=True)
        
        # ====== Collection: game_words ======
        logger.info("Creating indexes for 'game_words'...")
        db.game_words.create_index("gameWordId", unique=True, background=True)
        db.game_words.create_index([("boardId", 1), ("userId", 1), ("word", 1)], unique=True, background=True)
        db.game_words.create_index([("sessionId", 1), ("createdAtUtc", 1)], background=True)
        db.game_words.create_index([("boardId", 1), ("score", -1)], background=True)
        
        # ====== Collection: high_scores ======
        logger.info("Creating indexes for 'high_scores'...")
        db.high_scores.create_index("highScoreId", unique=True, background=True)
        db.high_scores.create_index([
            ("boardId", 1),
            ("leaderboardGameTypeId", 1),
            ("leaderboardCategoryTypeId", 1),
            ("score", -1)
        ], background=True)
        db.high_scores.create_index([("userId", 1), ("createdAtUtc", -1)], background=True)
        db.high_scores.create_index([("leaderboardGameTypeId", 1), ("leaderboardCategoryTypeId", 1)], background=True)
        
        # ====== Collection: user_identity_links ======
        logger.info("Creating indexes for 'user_identity_links'...")
        db.user_identity_links.create_index("firebaseUid", unique=True, background=True)
        db.user_identity_links.create_index("userId", unique=True, background=True)
        db.user_identity_links.create_index("revenueCatAppUserId", unique=True, sparse=True, background=True)
        db.user_identity_links.create_index([("userStatusTypeId", 1), ("userIdentityStateTypeId", 1)], background=True)
        
        # ====== Collection: entitlement_snapshots ======
        logger.info("Creating indexes for 'entitlement_snapshots'...")
        db.entitlement_snapshots.create_index([("userId", 1), ("createdAtUtc", -1)], background=True)
        db.entitlement_snapshots.create_index([("firebaseUid", 1), ("createdAtUtc", -1)], background=True)
        db.entitlement_snapshots.create_index([("revenueCatAppUserId", 1), ("createdAtUtc", -1)], background=True)
        
        # ====== Type Tables ======
        logger.info("Creating indexes for type tables...")
        db.leaderboard_game_types.create_index("leaderboardGameTypeId", unique=True, background=True)
        db.leaderboard_category_types.create_index("leaderboardCategoryTypeId", unique=True, background=True)
        db.user_status_types.create_index("userStatusTypeId", unique=True, background=True)
        db.user_identity_state_types.create_index("userIdentityStateTypeId", unique=True, background=True)
        
        logger.info("✅ All V2 indexes created successfully")
        
    except OperationFailure as e:
        logger.error(f"❌ Error creating indexes: {e}")
        raise
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        raise

if __name__ == "__main__":
    logger.info("Starting V2 index creation process...")
    create_v2_indexes()
    logger.info("V2 index creation process completed")
```

---

## 3) Slow Query Logging Plan

### MongoDB Slow Query Profiling

#### Enable Profiling on V2 Database

```javascript
// Connect to V2 database
use reword_v2

// Set profiling level to capture queries > 100ms
db.setProfilingLevel(1, { slowms: 100 })

// Verify profiling is enabled
db.getProfilingStatus()
// Output: { "was" : 1, "slowms" : 100, "sampleRate" : 1.0 }
```

**Profiling Levels:**
- `0` = Off
- `1` = Log slow queries only
- `2` = Log all queries (not recommended for production)

#### Query Slow Query Log

```javascript
// View slowest queries from the last hour
db.system.profile.find({
  ts: { $gt: new Date(Date.now() - 3600000) }
}).sort({ millis: -1 }).limit(10).pretty()

// Find queries without index usage
db.system.profile.find({
  planSummary: /COLLSCAN/
}).sort({ millis: -1 }).limit(10).pretty()
```

#### Automated Slow Query Report Script

**File:** `reword-utilities/MongoTools/slow_query_report_v2.py`

```python
import sys
import os
from datetime import datetime, timedelta
from pymongo import MongoClient

sys.path.append(os.path.expanduser("~/game-utils"))
from database import get_mongo_client

def generate_slow_query_report():
    """Generate report of slow queries from the last 24 hours"""
    client = get_mongo_client(port=27018)
    db = client["reword_v2"]
    
    # Get queries from last 24 hours
    cutoff = datetime.utcnow() - timedelta(hours=24)
    
    slow_queries = db.system.profile.find({
        "ts": {"$gt": cutoff},
        "millis": {"$gt": 100}  # Queries > 100ms
    }).sort("millis", -1).limit(20)
    
    print(f"\n{'='*80}")
    print(f"Slow Query Report - Last 24 Hours")
    print(f"Generated: {datetime.utcnow().isoformat()}")
    print(f"{'='*80}\n")
    
    for idx, query in enumerate(slow_queries, 1):
        print(f"Query #{idx}")
        print(f"  Operation: {query.get('op')}")
        print(f"  Namespace: {query.get('ns')}")
        print(f"  Duration: {query.get('millis')}ms")
        print(f"  Plan: {query.get('planSummary', 'N/A')}")
        print(f"  Timestamp: {query.get('ts')}")
        print(f"  Command: {query.get('command', {})}")
        print()
    
    # Find collection scans (missing indexes)
    collscans = db.system.profile.find({
        "ts": {"$gt": cutoff},
        "planSummary": {"$regex": "COLLSCAN"}
    }).limit(10)
    
    print(f"\n{'='*80}")
    print(f"Collection Scans (Missing Indexes)")
    print(f"{'='*80}\n")
    
    for idx, query in enumerate(collscans, 1):
        print(f"CollScan #{idx}")
        print(f"  Namespace: {query.get('ns')}")
        print(f"  Duration: {query.get('millis')}ms")
        print(f"  Command: {query.get('command', {})}")
        print()

if __name__ == "__main__":
    generate_slow_query_report()
```

**Cron Schedule:**

```cron
# Slow query report - weekly on Monday at 9 AM
0 9 * * 1 /home/rewordgame/venv/bin/python /home/rewordgame/reword-utilities/MongoTools/slow_query_report_v2.py | mail -s "MongoDB V2 Slow Query Report" admin@rewordgame.net
```

---

## 4) Monitoring & Alerting

### MongoDB Metrics to Track

| Metric | Command | Alert Threshold |
|---|---|---|
| Current connections | `db.serverStatus().connections.current` | > 80% of max |
| Active operations | `db.currentOp().inprog.length` | > 50 |
| Replication lag | `rs.status().members[].optimeDate` | > 10 seconds |
| Disk usage | `df -h` | > 80% |
| Index size | `db.stats().indexSize` | > RAM |
| Lock percentage | `db.serverStatus().locks` | > 10% |

### Health Check Endpoint

V2 API should expose MongoDB health:

```python
@app.get("/health/db")
async def health_db():
    try:
        # Ping MongoDB
        client.admin.command('ping')
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
```

---

## 5) Data Retention Policy

### V1 Collections

| Collection | Retention | Cleanup Strategy |
|---|---|---|
| `users` | Permanent | Soft-delete only |
| `games` | Permanent | Historical record |
| `game_stats` | Permanent | Historical record |
| `sessions` | 90 days | Monthly cleanup job |
| `token_blacklist` | TTL (auto) | Expires with token |

### V2 Collections

| Collection | Retention | Cleanup Strategy |
|---|---|---|
| `users` | Permanent | Soft-delete (`deletedAtUtc`) |
| `game_boards` | Permanent | Historical record |
| `game_sessions` | Permanent | Scoring/analytics |
| `game_words` | Permanent | Scoring/analytics |
| `high_scores` | Permanent | Leaderboards |
| `user_identity_links` | Permanent | Soft-delete |
| `entitlement_snapshots` | 1 year | Cleanup job (keep latest per user) |

---

## 6) Rollback Plan

### If V2 Deployment Fails

1. **Stop V2 containers** (leave V1 running)
   ```bash
   docker stop reword-backend-v2 reword-mongo-v2
   ```

2. **Verify V1 still serving traffic**
   ```bash
   curl -I https://api.rewordgame.net/health
   ```

3. **Investigate V2 logs**
   ```bash
   docker logs reword-backend-v2
   docker logs reword-mongo-v2
   ```

4. **Fix issues locally, rebuild, redeploy**

### If Data Corruption Detected

1. **Immediate:** Switch traffic to V1 (if V2 is live)
2. **Stop V2 writes**
3. **Restore V2 from latest backup**
4. **Investigate root cause**
5. **Fix + redeploy**

---

## 7) Operational Checklist

### Pre-Deployment

- [ ] V1 backup verified (< 24 hours old)
- [ ] Backup scripts tested (restore drill)
- [ ] Slow query profiling enabled on V2
- [ ] Monitoring alerts configured
- [ ] Rollback plan documented + tested

### Post-Deployment

- [ ] V2 indexes created and verified
- [ ] V2 backup cron job running
- [ ] Slow query reports generated (first week)
- [ ] No collection scans detected
- [ ] Disk space monitored (< 70%)

---

## 8) Next Steps

1. ✅ Complete this ops readiness doc
2. Create backup scripts + test
3. Create V2 index creation script
4. Draft docker-compose.yml V2 additions
5. Deploy V2 stack (V1 untouched)
6. Run operational drills
