# Re-Word V2 Dashboard API Endpoints
**Version:** 1.0  
**Date:** 2026-02-26  
**Purpose:** Analytics and monitoring endpoints for admin dashboard

---

## Overview

These endpoints provide real-time game statistics for a dashboard display. Designed to be consumed by:
- Raspberry Pi 5 display in office
- Web dashboard on game server
- Admin monitoring tools

**Key Design Decisions:**
- **Lightweight responses** (Pi-friendly)
- **Pre-aggregated data** (fast queries)
- **Secured endpoints** (admin-only access)
- **Optional caching** (reduce load)

---

## Authentication

All dashboard endpoints require:
1. **X-API-Key** (Layer 1 - Bot protection)
2. **Admin Token** (Layer 2 - Admin verification)

**Admin Token Options:**

### Option A: Simple API Key (Quick)
```bash
# Set in .env_v2
DASHBOARD_API_KEY="random-secure-string-here"

# Request header
X-Dashboard-Key: random-secure-string-here
```

### Option B: Firebase Admin Auth (More Secure)
```bash
# Use Firebase token with admin claim
Authorization: Bearer <firebase-admin-token>

# API checks for custom claim: admin=true
```

**Recommendation:** Start with Option A (simple), upgrade to Option B later if needed.

---

## Core Dashboard Endpoints

### 1. GET `/api/v2/dashboard/overview`

**Purpose:** High-level stats for main dashboard view

**Authentication:** X-API-Key + Admin Token

**Response:**
```json
{
  "timestamp": "2026-02-26T09:00:00Z",
  "today": {
    "boardId": "board-20260226",
    "dateUtc": "2026-02-26",
    "status": "active",
    "hoursRemaining": 15.2
  },
  "users": {
    "total": 15234,
    "guest": 12890,
    "linked": 1127,
    "paid": 1217,
    "newToday": 127,
    "activeToday": 3428
  },
  "gameplay": {
    "sessionsToday": 4892,
    "totalSessions": 156743,
    "averageScore": 98450,
    "averageTimeMinutes": 12.3,
    "averageCompletionRate": 67.5,
    "averageWordsFound": 42
  },
  "leaderboard": {
    "entriesT today": 387,
    "topScore": 142500,
    "topScoreUser": "WordWizard",
    "averageTopTen": 135200
  },
  "revenue": {
    "lifetimePurchases": 1217,
    "purchasesToday": 8,
    "conversionRate": 8.0
  }
}
```

**Query Parameters:**
- `date` (optional): Get stats for specific date (default: today)
- `refresh` (optional): Force refresh cached data (default: false)

**Example:**
```
GET /api/v2/dashboard/overview?date=2026-02-25
```

---

### 2. GET `/api/v2/dashboard/board/today`

**Purpose:** Current board details with solution words

**Authentication:** X-API-Key + Admin Token

**Response:**
```json
{
  "boardId": "board-20260226",
  "startDateUtc": "2026-02-26T00:00:00Z",
  "endDateUtc": "2026-02-27T00:00:00Z",
  "status": "active",
  "hoursRemaining": 15.2,
  "grid": {
    "letters": "TMAVAINIEYOTKGSXSIEUEHEGNNEMWNHNWITATURNSTUTEWLXN",
    "wildcards": "EHWSX",
    "gridSize": "7x7"
  },
  "solution": {
    "totalWords": 364,
    "words": [
      { "word": "SEIZE", "length": 5, "points": 450 },
      { "word": "RING", "length": 4, "points": 280 },
      // ... all possible words
    ],
    "distribution": {
      "length3": 42,
      "length4": 98,
      "length5": 127,
      "length6": 72,
      "length7Plus": 25
    },
    "estimatedHighScore": 2127
  },
  "gameplay": {
    "sessionsCompleted": 1247,
    "averageWordsFound": 42,
    "averageScore": 98450,
    "averageCompletionRate": 67.5,
    "mostFoundWord": "RING",
    "leastFoundWord": "SEIZING"
  }
}
```

**Use Case:** Display today's puzzle and see how players are doing

---

### 3. GET `/api/v2/dashboard/users/stats`

**Purpose:** User growth and engagement metrics

**Authentication:** X-API-Key + Admin Token

**Response:**
```json
{
  "timestamp": "2026-02-26T09:00:00Z",
  "totals": {
    "allUsers": 15234,
    "guest": 12890,
    "linked": 1127,
    "paid": 1217
  },
  "growth": {
    "today": 127,
    "yesterday": 142,
    "last7Days": 856,
    "last30Days": 3421
  },
  "engagement": {
    "dailyActiveUsers": 3428,
    "weeklyActiveUsers": 8934,
    "monthlyActiveUsers": 12456,
    "averageSessionsPerUser": 10.3,
    "averagePlaytimeMinutes": 126
  },
  "conversion": {
    "guestToLinked": 8.7,
    "linkedToPaid": 108.0,
    "overallConversionRate": 8.0
  },
  "retention": {
    "day1": 42.3,
    "day7": 28.7,
    "day30": 18.2
  },
  "platforms": {
    "ios": 8234,
    "android": 4892,
    "web": 1234,
    "macos": 456,
    "windows": 345,
    "linux": 73
  },
  "authProviders": {
    "apple": 5234,
    "google": 3892,
    "email": 1108,
    "anonymous": 12890
  },
  "topLocales": [
    { "locale": "en-us", "count": 8934 },
    { "locale": "en-gb", "count": 2341 },
    { "locale": "en-ca", "count": 1456 }
  ]
}
```

**Query Parameters:**
- `period` (optional): `today`, `week`, `month`, `all` (default: today)

---

### 4. GET `/api/v2/dashboard/gameplay/trends`

**Purpose:** Gameplay statistics over time

**Authentication:** X-API-Key + Admin Token

**Response:**
```json
{
  "period": "last30Days",
  "startDate": "2026-01-27",
  "endDate": "2026-02-26",
  "daily": [
    {
      "date": "2026-02-26",
      "sessions": 4892,
      "uniquePlayers": 3428,
      "averageScore": 98450,
      "averageCompletionRate": 67.5,
      "averagePlaytimeMinutes": 12.3,
      "leaderboardSubmissions": 387
    },
    // ... one entry per day
  ],
  "aggregates": {
    "totalSessions": 143267,
    "averageSessionsPerDay": 4775,
    "peakDay": {
      "date": "2026-02-20",
      "sessions": 6234
    },
    "averageScore": 97823,
    "averageCompletionRate": 66.8,
    "totalWordsFound": 5892341
  }
}
```

**Query Parameters:**
- `period`: `7days`, `30days`, `90days` (default: 30days)
- `granularity`: `daily`, `weekly` (default: daily)

---

### 5. GET `/api/v2/dashboard/leaderboard/summary`

**Purpose:** Leaderboard activity and highlights

**Authentication:** X-API-Key + Admin Token

**Response:**
```json
{
  "timestamp": "2026-02-26T09:00:00Z",
  "today": {
    "boardId": "board-20260226",
    "totalSubmissions": 387,
    "uniqueUsers": 387,
    "topScore": {
      "rank": 1,
      "userAlias": "WordWizard",
      "score": 142500,
      "wordCount": 58,
      "completionRate": 96.2,
      "submittedAtUtc": "2026-02-26T14:22:00Z"
    },
    "topTen": [
      {
        "rank": 1,
        "userAlias": "WordWizard",
        "score": 142500
      },
      // ... top 10 entries
    ],
    "distribution": {
      "above100k": 42,
      "80kTo100k": 87,
      "60kTo80k": 134,
      "below60k": 124
    },
    "averageScore": 98450,
    "medianScore": 92100
  },
  "allTime": {
    "totalSubmissions": 45672,
    "recordScore": 156300,
    "recordHolder": "LegendaryWordsmith",
    "recordDate": "2026-02-15",
    "mostSubmissions": {
      "userAlias": "DailyPlayer",
      "submissions": 87
    }
  }
}
```

---

### 6. GET `/api/v2/dashboard/revenue/summary`

**Purpose:** Purchase and revenue metrics

**Authentication:** X-API-Key + Admin Token

**Response:**
```json
{
  "timestamp": "2026-02-26T09:00:00Z",
  "purchases": {
    "total": 1217,
    "today": 8,
    "yesterday": 12,
    "last7Days": 67,
    "last30Days": 284
  },
  "revenue": {
    "totalUsd": 3640.83,
    "todayUsd": 23.92,
    "last7DaysUsd": 200.33,
    "last30DaysUsd": 849.16,
    "averageRevenuePerUser": 2.99
  },
  "conversion": {
    "overallRate": 8.0,
    "guestToPaidRate": 0.7,
    "linkedToPaidRate": 108.0
  },
  "platforms": {
    "ios": {
      "purchases": 734,
      "revenueUsd": 2194.66
    },
    "android": {
      "purchases": 483,
      "revenueUsd": 1444.17
    }
  },
  "timeline": [
    {
      "date": "2026-02-26",
      "purchases": 8,
      "revenueUsd": 23.92
    },
    // ... last 30 days
  ]
}
```

**Note:** This requires RevenueCat webhook integration for real-time data.

---

### 7. GET `/api/v2/dashboard/realtime`

**Purpose:** Real-time activity feed for live monitoring

**Authentication:** X-API-Key + Admin Token

**Response:**
```json
{
  "timestamp": "2026-02-26T09:00:00Z",
  "currentlyActive": 234,
  "recentActivity": [
    {
      "timestamp": "2026-02-26T08:59:42Z",
      "type": "session_completed",
      "userId": "user-abc123",
      "userType": "paid",
      "score": 125000,
      "wordCount": 52,
      "locale": "en-us",
      "platform": "ios"
    },
    {
      "timestamp": "2026-02-26T08:59:38Z",
      "type": "high_score_submitted",
      "userAlias": "Sprockett",
      "score": 125000,
      "rank": 42
    },
    {
      "timestamp": "2026-02-26T08:59:15Z",
      "type": "user_purchased",
      "userId": "user-xyz789",
      "platform": "android",
      "product": "reword.pro.lifetime"
    },
    {
      "timestamp": "2026-02-26T08:58:52Z",
      "type": "new_user",
      "userId": "user-new123",
      "platform": "ios",
      "locale": "en-gb"
    }
  ],
  "last5Minutes": {
    "sessions": 42,
    "newUsers": 7,
    "purchases": 2,
    "leaderboardSubmissions": 18
  }
}
```

**Query Parameters:**
- `limit`: Number of recent events (default: 20, max: 100)
- `types`: Filter by event types (comma-separated)

**Example:**
```
GET /api/v2/dashboard/realtime?limit=50&types=purchase,high_score
```

---

### 8. GET `/api/v2/dashboard/health`

**Purpose:** System health and monitoring

**Authentication:** X-API-Key + Admin Token

**Response:**
```json
{
  "timestamp": "2026-02-26T09:00:00Z",
  "status": "healthy",
  "services": {
    "api": {
      "status": "up",
      "responseTimeMs": 42,
      "uptime": "15d 7h 23m"
    },
    "database": {
      "status": "up",
      "connections": 12,
      "queryTimeMs": 8
    },
    "firebase": {
      "status": "up",
      "lastChecked": "2026-02-26T08:55:00Z"
    },
    "revenueCat": {
      "status": "up",
      "lastWebhook": "2026-02-26T08:45:12Z"
    }
  },
  "performance": {
    "requestsPerMinute": 87,
    "averageResponseTimeMs": 45,
    "errorRate": 0.02
  },
  "storage": {
    "databaseSizeMb": 2847,
    "documentsCount": 156743,
    "avgDocumentSizeKb": 18.2
  }
}
```

---

## Raspberry Pi Dashboard Considerations

### Display Options

**Option 1: Simple HTML Dashboard (Recommended)**
- Server hosts lightweight HTML page
- Fetches data via JavaScript
- Auto-refresh every 30 seconds
- No React overhead
- Pi just loads URL in kiosk mode

**Option 2: Flask/FastAPI Dashboard on Pi**
- Python app on Pi
- Calls API endpoints
- Renders with Jinja2 templates
- More control, but more maintenance

**Option 3: Electron App**
- Lightweight compared to React
- Can run offline with cached data
- Cross-platform

### Sample HTML Dashboard Structure

```html
<!DOCTYPE html>
<html>
<head>
    <title>Re-Word Dashboard</title>
    <style>
        body {
            background: #1a1a1a;
            color: #fff;
            font-family: 'Segoe UI', Arial, sans-serif;
            margin: 0;
            padding: 20px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
        }
        .card {
            background: #2a2a2a;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        .metric-value {
            font-size: 48px;
            font-weight: bold;
            color: #4CAF50;
        }
        .metric-label {
            font-size: 14px;
            color: #999;
            text-transform: uppercase;
        }
    </style>
</head>
<body>
    <h1>Re-Word Live Dashboard</h1>
    <div class="grid">
        <div class="card">
            <div class="metric-value" id="activeUsers">---</div>
            <div class="metric-label">Active Users Today</div>
        </div>
        <!-- More cards... -->
    </div>
    
    <script>
        const API_KEY = 'your-api-key';
        const DASHBOARD_KEY = 'your-dashboard-key';
        
        async function fetchDashboard() {
            const response = await fetch('/api/v2/dashboard/overview', {
                headers: {
                    'X-API-Key': API_KEY,
                    'X-Dashboard-Key': DASHBOARD_KEY
                }
            });
            const data = await response.json();
            
            document.getElementById('activeUsers').textContent = 
                data.users.activeToday.toLocaleString();
            // Update other metrics...
        }
        
        // Refresh every 30 seconds
        setInterval(fetchDashboard, 30000);
        fetchDashboard(); // Initial load
    </script>
</body>
</html>
```

---

## Implementation Notes

### Data Aggregation Strategy

**Option A: Real-time Queries (Simple)**
- Query MongoDB on each request
- Use indexes for performance
- Good for starting out
- May be slow as data grows

**Option B: Pre-aggregated Stats (Scalable)**
- Daily cron job aggregates stats
- Store in `dashboard_stats` collection
- Fast queries, stale data (5-60 min)
- Recommended for production

**Option C: Redis Cache Layer**
- Cache expensive queries
- TTL: 5-15 minutes
- Best of both worlds
- Requires Redis setup

### Sample Aggregation Collection

```javascript
// dashboard_stats collection
{
  "_id": ObjectId,
  "statsDate": "2026-02-26",
  "statsType": "daily_overview",
  "data": {
    "users": { /* user stats */ },
    "gameplay": { /* gameplay stats */ },
    // ... aggregated data
  },
  "generatedAtUtc": "2026-02-26T00:05:00Z",
  "expiresAtUtc": "2026-02-27T00:00:00Z"
}

// Index for quick lookups
{ statsDate: 1, statsType: 1 }
```

### Cron Job for Aggregation

```bash
# /etc/cron.d/reword-dashboard
# Run stats aggregation every 15 minutes
*/15 * * * * gameadmin cd /var/www/reword-api && python scripts/aggregate_dashboard_stats.py
```

---

## Security Considerations

1. **Rate Limiting:** Dashboard endpoints should have generous rate limits (1000/hour)
2. **IP Whitelist:** Consider restricting to known IPs (your office, server)
3. **No PII:** Dashboard responses should never include user emails or identifiable info
4. **Read-Only:** These endpoints never modify data
5. **Audit Logging:** Log dashboard access for security monitoring

---

## Firebase Integration

### Combining Firebase Analytics

You can enhance dashboard data with Firebase:

```python
# In dashboard endpoint
firebase_analytics = get_firebase_analytics()
game_stats = get_game_stats_from_mongo()

combined_stats = {
    "users": game_stats["users"],
    "firebase": {
        "screenViews": firebase_analytics["screen_views"],
        "crashFreeRate": firebase_analytics["crash_free_rate"],
        "averageSessionDuration": firebase_analytics["avg_session"]
    }
}
```

### Firebase Admin SDK Setup

```python
import firebase_admin
from firebase_admin import analytics

# Already initialized for auth, can reuse for analytics
def get_firebase_analytics():
    # Query Firebase Analytics Data API
    # Requires service account with Analytics Read permission
    pass
```

---

## Testing the Dashboard

### Local Testing

```bash
# Get overview stats
curl -H "X-API-Key: your-key" \
     -H "X-Dashboard-Key: your-dashboard-key" \
     http://localhost:8001/api/v2/dashboard/overview

# Get today's board
curl -H "X-API-Key: your-key" \
     -H "X-Dashboard-Key: your-dashboard-key" \
     http://localhost:8001/api/v2/dashboard/board/today
```

### Raspberry Pi Setup

```bash
# 1. Install Chromium in kiosk mode
sudo apt-get install chromium-browser unclutter

# 2. Create startup script
cat > ~/start-dashboard.sh << 'EOF'
#!/bin/bash
chromium-browser \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  https://rewordgame.net/dashboard.html
EOF

chmod +x ~/start-dashboard.sh

# 3. Auto-start on boot
echo "@/home/pi/start-dashboard.sh" >> ~/.config/lxsession/LXDE-pi/autostart
```

---

## Performance Metrics

**Target Response Times:**
- Overview: < 100ms
- Board details: < 150ms
- User stats: < 200ms
- Trends: < 500ms
- Realtime: < 50ms

**Optimization Techniques:**
1. Use MongoDB aggregation pipelines
2. Create indexes on frequently queried fields
3. Implement caching (Redis or in-memory)
4. Pre-compute expensive stats
5. Use connection pooling

---

## Future Enhancements

**Phase 1 (Now):**
- Core dashboard endpoints
- Simple HTML dashboard
- Basic aggregation

**Phase 2:**
- Redis caching layer
- Advanced charts/graphs
- Email/Slack alerts for anomalies

**Phase 3:**
- Historical trend analysis
- Predictive analytics
- A/B testing support
- Custom report generation

---

## Summary

**8 Dashboard Endpoints:**
1. `/dashboard/overview` - High-level stats
2. `/dashboard/board/today` - Current puzzle + solutions
3. `/dashboard/users/stats` - User growth metrics
4. `/dashboard/gameplay/trends` - Gameplay over time
5. `/dashboard/leaderboard/summary` - Leaderboard highlights
6. `/dashboard/revenue/summary` - Purchase metrics
7. `/dashboard/realtime` - Live activity feed
8. `/dashboard/health` - System status

**Raspberry Pi Dashboard:**
- Simple HTML + JavaScript
- Chromium kiosk mode
- Auto-refresh every 30 seconds
- No React needed!

---

**Ready to implement?** We can start with the core endpoints and build out from there!