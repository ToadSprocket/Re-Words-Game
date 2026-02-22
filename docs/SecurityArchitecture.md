# Re-Word Game Security Architecture
# Version 2.0

## Overview

The Re-Word Game implements a **multi-layered defense-in-depth security model** to protect the game API, user data, and prevent unauthorized access. Each security layer provides independent protection, ensuring that if one layer is bypassed, others remain effective.

**Security Philosophy:**
- Defense in depth (multiple independent layers)
- Client-side + Server-side validation
- Zero-trust architecture (verify everything)
- Fail securely (deny by default)

---

## Security Layers

### Layer 1: Certificate Pinning (Transport Security)

**Purpose:** Ensure only the official app can establish secure connections to the API

**Implementation:** Client-side validation of server SSL certificate fingerprint

**Location:** 
- Flutter app: `lib/utils/secure_http_client.dart`
- Configuration: `lib/config/config.dart`

**How It Works:**
1. Flutter app contains expected SHA-256 fingerprint(s) of server certificate
2. When connecting via HTTPS, app validates server's certificate fingerprint
3. If fingerprint matches expected value → Connection allowed ✅
4. If fingerprint doesn't match → Connection rejected ❌

**Multi-Certificate Support:**
```dart
// Support multiple certificates for rotation
static const List<String> acceptedCertificateFingerprints = [
  'DD:E9:59:7B:3C:5D:3F:11:...',  // Current cert
  'AB:12:34:CD:56:78:90:EF:...',  // Backup/future cert
];
```

**Protects Against:**
- Man-in-the-middle (MITM) attacks
- Rogue proxy servers (Charles, Fiddler, Burp Suite)
- Compromised Certificate Authorities
- DNS hijacking + fake certificates
- Network sniffing and interception

**Attack Scenario Prevented:**
```
Attacker → Installs proxy tool (Charles Proxy)
         → Installs CA certificate on device
         → Intercepts HTTPS traffic
         → Re-Word app validates cert fingerprint
         → Fingerprint doesn't match expected
         → Connection REJECTED ✅
```

**Limitations:**
- Only protects official app (doesn't stop other clients if they reverse-engineer other layers)
- Requires app updates for certificate rotation
- Can be bypassed if device is jailbroken/rooted and app is decompiled

**Configuration:**
- Enable/disable: `Config.enableCertificatePinning`
- Fingerprints: `Config.acceptedCertificateFingerprints`
- Rotation process: See [Certificate Rotation Playbook](/docs/certificate_rotation_playbook.md)

---

### Layer 2: X-API-Key (Bot Protection)

**Purpose:** Prevent random bots, scrapers, and unauthorized clients from accessing the API

**Implementation:** SHA-512 hash of (SALT + API_KEY) sent in HTTP header

**Location:**
- Flutter app: `lib/logic/security.dart` (generates hash)
- FastAPI: `app_v2/middleware/api_key.py` (validates hash)
- Secrets: `.env_v2` (stores SALT and KEY on server)

**How It Works:**

**Client Side (Flutter):**
```dart
// Generate API key hash
String salt = Config.getApiSalt();  // Obfuscated in app
String key = Config.getApiKey();    // Obfuscated in app
String hash = sha512(salt + key);

// Add to request headers
headers['X-API-Key'] = hash;
```

**Server Side (FastAPI):**
```python
# Middleware validates every request
expected_hash = sha512(env.API_SALT + env.API_KEY)
received_hash = request.headers.get('X-API-Key')

if received_hash != expected_hash:
    raise HTTPException(403, "Invalid API Key")
```

**Key Characteristics:**
- **Obfuscation:** API_KEY and API_SALT stored as integer arrays in Flutter app (not plain text)
- **One-way:** Server never sends key/salt, only validates hash
- **Separate for V1/V2:** V2 uses different key/salt than V1

**Protects Against:**
- Random script kiddies scanning for APIs
- Automated bots discovering endpoints
- Accidental discovery via search engines
- Simple curl/Postman attacks (without reverse engineering)

**Does NOT Protect Against:**
- Determined attackers who decompile the app
- Users who extract the key/salt from app binary
- Replay attacks (hash is static)

**Why It's Still Valuable:**
- **First barrier:** Stops 95% of casual attackers
- **Defense in depth:** Combined with other layers = strong protection
- **Bot detection:** Logs attempts with invalid keys
- **Low overhead:** Fast to validate, minimal latency

**V2 Secrets Location:**
```bash
# On server
/home/gameadmin/reword-api/.env_v2
API_KEY_V2=<secret>
API_SALT_V2=<secret>

# In Flutter app
lib/config/config_v2.dart
_obfuscatedApiKeyV2 = [112, 50, 76, ...]  # Obfuscated
_obfuscatedApiSaltV2 = [55, 52, 85, ...]  # Obfuscated
```

---

### Layer 3: Firebase Authentication (User Identity)

**Purpose:** Identify and authenticate individual users, verify their identity

**Implementation:** JWT (JSON Web Token) based authentication via Firebase

**Location:**
- Flutter app: Firebase SDK handles authentication
- FastAPI: `app_v2/dependencies/auth.py` (validates tokens)
- Firebase: Cloud-based auth service

**How It Works:**

**1. User Registration/Login (Flutter):**
```dart
// User enters email + password
UserCredential cred = await FirebaseAuth.instance
    .signInWithEmailAndPassword(
        email: email,
        password: password
    );

// Firebase returns tokens
String accessToken = await cred.user.getIdToken();  // JWT, expires in 1 hour
String refreshToken = cred.user.refreshToken;       // Long-lived token
```

**2. API Request (Flutter):**
```dart
// Add JWT to request
headers['Authorization'] = 'Bearer $accessToken';
headers['X-API-Key'] = '<hash>';  // Layer 2
```

**3. Token Validation (FastAPI):**
```python
# Dependency validates token on every protected endpoint
@app.get("/api/v2/boards/today")
async def get_board(user: dict = Depends(verify_firebase_token)):
    # user = {"uid": "abc123", "email": "user@example.com"}
    # Token is valid, user is authenticated!
    # Serve personalized content based on user.uid
```

**Token Types:**

**Access Token (ID Token):**
- Type: JWT (JSON Web Token)
- Lifetime: 1 hour
- Contains: User ID, email, email_verified, issued_at, expiry
- Use: Sent with every API request
- Renewal: Automatic via refresh token

**Refresh Token:**
- Type: Opaque token
- Lifetime: Long-lived (until revoked)
- Use: Get new access token when it expires
- Storage: Secure storage on device

**Token Refresh Flow:**
```
1. Access token expires (1 hour)
2. API returns 401 Unauthorized
3. App detects 401, uses refresh token
4. Firebase issues new access token
5. App retries original request with new token
```

**Protects Against:**
- Unauthorized API access (no valid user)
- Account impersonation (tokens cryptographically signed)
- Session hijacking (tokens expire)
- Stolen tokens (can be revoked)

**Security Features:**
- **Cryptographic signatures:** Tokens signed by Firebase, can't be forged
- **Automatic expiry:** Access tokens expire in 1 hour
- **Revocation:** Can revoke user's refresh token server-side
- **Email verification:** Can require verified emails
- **Rate limiting:** Firebase rate-limits auth attempts

**Token Validation Process:**
```python
# FastAPI calls Firebase Admin SDK
decoded = firebase_admin.auth.verify_id_token(token)

# Firebase verifies:
# 1. Signature is valid (signed by Firebase)
# 2. Token hasn't expired
# 3. Token issued for this Firebase project
# 4. Token hasn't been revoked

# Returns user info if valid
return {
    "uid": decoded["uid"],
    "email": decoded.get("email"),
    "email_verified": decoded.get("email_verified")
}
```

---

### Layer 4: Rate Limiting (Abuse Prevention)

**Purpose:** Prevent API abuse, brute force attacks, and resource exhaustion

**Implementation:** NGINX rate limiting by IP address

**Location:** NGINX configuration on server (`/etc/nginx/nginx.conf` and site configs)

**How It Works:**

**Configuration:**
```nginx
# Define rate limit zones
http {
    # General API requests: 100 per minute per IP
    limit_req_zone $binary_remote_addr zone=api_v2_limit:10m rate=100r/m;
    
    # Auth endpoints: 10 per minute per IP (stricter)
    limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=10r/m;
}

server {
    # Apply to V2 API
    location /api/v2/ {
        limit_req zone=api_v2_limit burst=20 nodelay;
        proxy_pass http://127.0.0.1:8001;
    }
    
    # Stricter limits for auth endpoints
    location ~ ^/api/v2/(login|register|reset-password) {
        limit_req zone=auth_limit burst=5 nodelay;
        proxy_pass http://127.0.0.1:8001;
    }
}
```

**Parameters Explained:**
- `rate=100r/m`: 100 requests per minute average
- `burst=20`: Allow 20 requests over limit in short burst
- `nodelay`: Process burst requests immediately (don't queue)

**Example:**
- User makes 120 requests in 10 seconds
- First 120 requests: Allowed ✅ (within burst)
- Requests 121+: Rejected with HTTP 503 ❌
- After 1 minute: Rate resets, user can make 100 more

**Protects Against:**
- **Brute force attacks:** Limit login attempts
- **API scraping:** Prevent automated data harvesting
- **DDoS attacks:** Rate limit by IP prevents overwhelming server
- **Resource exhaustion:** Protects server CPU/memory/bandwidth

**Rate Limit Tiers:**

| Endpoint Type | Rate | Burst | Reasoning |
|---------------|------|-------|-----------|
| General API | 100/min | 20 | Normal gameplay generates ~5-10 req/min |
| Auth endpoints | 10/min | 5 | Login attempts should be slow |
| Health checks | Unlimited | N/A | Monitoring needs unrestricted access |

**Response When Rate Limited:**
```
HTTP/1.1 503 Service Temporarily Unavailable
Retry-After: 42

Too Many Requests
```

**Infrastructure Level Protection:**
- Blocks malicious traffic BEFORE it reaches application
- Zero CPU overhead on FastAPI application
- Configurable per-endpoint
- Logs rate limit violations

---

### Layer 5: Input Validation (Data Integrity)

**Purpose:** Ensure all input data is valid, safe, and properly formatted

**Implementation:** Pydantic models validate request structure and data types

**Location:** `app_v2/models/` - All request/response models

**How It Works:**

**Request Model (FastAPI):**
```python
from pydantic import BaseModel, validator, EmailStr
from typing import List

class SubmitScoreRequest(BaseModel):
    user_id: str
    board_id: str
    score: int
    words_found: List[str]
    
    @validator('score')
    def score_must_be_positive(cls, v):
        if v < 0:
            raise ValueError('Score must be non-negative')
        if v > 100000:
            raise ValueError('Score unrealistically high')
        return v
    
    @validator('words_found')
    def validate_words(cls, v):
        if len(v) > 1000:
            raise ValueError('Too many words')
        for word in v:
            if not word.isalpha():
                raise ValueError('Words must contain only letters')
        return v
```

**Automatic Validation:**
```python
@app.post("/api/v2/scores/submit")
async def submit_score(
    request: SubmitScoreRequest,  # ← Pydantic validates automatically
    user: dict = Depends(verify_firebase_token)
):
    # If execution reaches here, request is VALID
    # Pydantic already validated:
    # - All required fields present
    # - Correct data types
    # - Custom validation rules passed
    
    # Safe to use request.score, request.words_found, etc.
```

**If Validation Fails:**
```json
HTTP/1.1 422 Unprocessable Entity
{
  "detail": [
    {
      "loc": ["body", "score"],
      "msg": "Score must be non-negative",
      "type": "value_error"
    }
  ]
}
```

**Protects Against:**
- **SQL Injection:** Validates input before database queries
- **XSS (Cross-Site Scripting):** Validates/sanitizes string inputs
- **Type confusion:** Ensures fields are correct data types
- **Malformed requests:** Rejects invalid JSON, missing fields
- **Logic errors:** Custom validators enforce business rules

**Validation Types:**

**1. Type Validation:**
```python
user_id: str        # Must be string
score: int          # Must be integer
timestamp: datetime # Must be valid datetime
```

**2. Format Validation:**
```python
email: EmailStr           # Must be valid email format
uuid: UUID4               # Must be valid UUID
url: HttpUrl              # Must be valid URL
```

**3. Range Validation:**
```python
score: conint(ge=0, le=100000)  # 0 <= score <= 100000
username: constr(min_length=3, max_length=20)  # 3-20 chars
```

**4. Custom Business Logic:**
```python
@validator('board_id')
def board_must_exist(cls, v):
    if not is_valid_board_id(v):
        raise ValueError('Board ID not found')
    return v
```

**Benefits:**
- **Automatic:** No manual validation code needed
- **Self-documenting:** Models show expected structure
- **Type-safe:** Catches errors before they reach business logic
- **Performance:** Fast validation (compiled Rust/Cython)

---

## Authentication Flow Diagrams

### User Registration Flow

```
┌─────────────┐
│ Flutter App │
└──────┬──────┘
       │
       │ 1. User enters email + password
       │
       ▼
┌─────────────────┐
│ Firebase Auth   │ ← Google's servers
└──────┬──────────┘
       │
       │ 2. Create account
       │ 3. Send verification email
       │ 4. Return tokens
       │
       ▼
┌─────────────┐
│ Flutter App │
└──────┬──────┘
       │
       │ 5. Store tokens securely
       │ 6. Call Re-Word API
       │
       ▼
┌──────────────────┐       ┌──────────────┐
│ FastAPI V2       │──────→│ Firebase SDK │
│ /api/v2/register │       │ Verify Token │
└──────┬───────────┘       └──────────────┘
       │
       │ 7. Token valid ✅
       │ 8. Create user in MongoDB
       │ 9. Return user data
       │
       ▼
┌─────────────┐
│ Flutter App │ User registered! ✅
└─────────────┘
```

### User Login Flow

```
┌─────────────┐
│ Flutter App │
└──────┬──────┘
       │ 1. User enters credentials
       ▼
┌─────────────────┐
│ Firebase Auth   │
└──────┬──────────┘
       │ 2. Validate credentials
       │ 3. Return JWT tokens
       ▼
┌─────────────┐
│ Secure      │
│ Storage     │ 4. Store tokens
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Flutter App │ User logged in! ✅
└─────────────┘
```

### Authenticated API Request Flow

```
┌─────────────┐
│ Flutter App │
└──────┬──────┘
       │ 1. Generate X-API-Key hash
       │ 2. Get Firebase access token
       │ 3. Add both to headers
       │
       ▼
┌──────────────────────────────┐
│ NGINX (Rate Limiting)        │
│ Check: IP within rate limit? │
└──────┬───────────────────────┘
       │ Yes ✅
       ▼
┌──────────────────────────────┐
│ FastAPI Middleware           │
│ Check: X-API-Key valid?      │
└──────┬───────────────────────┘
       │ Yes ✅
       ▼
┌──────────────────────────────┐
│ Auth Dependency              │
│ Verify Firebase token        │
└──────┬───────────────────────┘
       │ Valid ✅
       ▼
┌──────────────────────────────┐
│ Endpoint Handler             │
│ Process request              │
│ Query MongoDB                │
│ Return response              │
└──────┬───────────────────────┘
       │
       ▼
┌─────────────┐
│ Flutter App │ Response received! ✅
└─────────────┘
```

### Token Refresh Flow

```
┌─────────────┐
│ Flutter App │ Access token expired (1 hour)
└──────┬──────┘
       │ 1. API returns 401
       │ 2. App detects expired token
       │
       ▼
┌─────────────┐
│ Secure      │
│ Storage     │ 3. Get refresh token
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ Firebase Auth   │ 4. Exchange refresh for new access
└──────┬──────────┘
       │ 5. Return new access token
       ▼
┌─────────────┐
│ Secure      │
│ Storage     │ 6. Update stored token
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Flutter App │ 7. Retry original request
└─────────────┘    with new token ✅
```

---

## Certificate Rotation Strategy

The Re-Word Game uses **multi-certificate pinning** to enable seamless certificate rotation without user downtime.

**Strategy:** Pin multiple certificate fingerprints in the app, allowing both current and future certificates.

**Timeline:**
- Day -90: Purchase/generate new cert
- Day -85: Add new cert to app (alongside current)
- Day -60: Release app to users
- Day -30: 80%+ users updated
- Day -15: Rotate server to new cert
- Day 0: Old cert expires (no impact, new cert active)

**Detailed Process:** See [Certificate Rotation Playbook](/docs/certificate_rotation_playbook.md)

**Key Points:**
- Server serves ONE certificate at a time
- Client accepts MULTIPLE fingerprints
- Provides transition window for app updates
- Zero downtime for users on updated app
- Monitoring alerts 30/15/7 days before expiry

---

## Testing Security Layers

### Test Layer 1: Certificate Pinning

**Test 1: Valid Certificate**
```bash
# Flutter app should connect successfully
flutter run
# App connects to https://rewordgame.net ✅
```

**Test 2: Invalid Certificate (Proxy)**
```bash
# Install Charles Proxy or mitmproxy
# Configure device to use proxy
# Install proxy's CA certificate

flutter run
# App should REJECT connection ❌
# Log: "Certificate pinning failed"
```

**Test 3: Multiple Certificates**
```dart
// In config.dart - add test cert
acceptedCertificateFingerprints = [
  'DD:E9:59:7B:...',  // Production cert
  'TEST:FINGERPRINT',  // Test cert
];

// App should accept either cert
```

### Test Layer 2: X-API-Key

**Test 1: Valid Key**
```bash
# Generate hash
HASH=$(echo -n "SALT+KEY" | sha512sum)

# Test with curl
curl -H "X-API-Key: $HASH" https://rewordgame.net/api/v2/health
# Should return: {"status": "healthy"} ✅
```

**Test 2: Invalid Key**
```bash
curl -H "X-API-Key: invalid_hash" https://rewordgame.net/api/v2/health
# Should return: 403 Forbidden ❌
```

**Test 3: Missing Key**
```bash
curl https://rewordgame.net/api/v2/health
# Should return: 403 Forbidden ❌
```

### Test Layer 3: Firebase Auth

**Test 1: Valid Token**
```bash
# Get token from Firebase
TOKEN="<firebase_jwt_token>"

curl -H "Authorization: Bearer $TOKEN" \
     -H "X-API-Key: $HASH" \
     https://rewordgame.net/api/v2/boards/today
# Should return board data ✅
```

**Test 2: Invalid Token**
```bash
curl -H "Authorization: Bearer invalid_token" \
     -H "X-API-Key: $HASH" \
     https://rewordgame.net/api/v2/boards/today
# Should return: 401 Unauthorized ❌
```

**Test 3: Expired Token**
```bash
# Use token older than 1 hour
curl -H "Authorization: Bearer $EXPIRED_TOKEN" \
     -H "X-API-Key: $HASH" \
     https://rewordgame.net/api/v2/boards/today
# Should return: 401 Unauthorized (token expired) ❌
```

### Test Layer 4: Rate Limiting

**Test 1: Normal Usage**
```bash
# Make 50 requests (within limit)
for i in {1..50}; do
    curl https://rewordgame.net/api/v2/health
done
# All should succeed ✅
```

**Test 2: Rate Limit Hit**
```bash
# Make 150 requests rapidly (exceeds limit)
for i in {1..150}; do
    curl https://rewordgame.net/api/v2/health
done
# First ~120: 200 OK ✅
# After: 503 Service Unavailable ❌
```

**Test 3: Auth Endpoint Limits**
```bash
# Make 15 login attempts
for i in {1..15}; do
    curl -X POST https://rewordgame.net/api/v2/login
done
# First ~10: Processed
# After: 503 Rate Limited ❌
```

### Test Layer 5: Input Validation

**Test 1: Valid Input**
```bash
curl -X POST https://rewordgame.net/api/v2/scores/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-API-Key: $HASH" \
  -d '{"user_id": "abc", "score": 1000, "words": ["cat","dog"]}'
# Should return: 200 OK ✅
```

**Test 2: Invalid Type**
```bash
curl -X POST https://rewordgame.net/api/v2/scores/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-API-Key: $HASH" \
  -d '{"user_id": "abc", "score": "not_a_number"}'
# Should return: 422 Validation Error ❌
```

**Test 3: Missing Required Field**
```bash
curl -X POST https://rewordgame.net/api/v2/scores/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-API-Key: $HASH" \
  -d '{"user_id": "abc"}'  # Missing score
# Should return: 422 Validation Error ❌
```

---

## Monitoring & Alerts

### Security Monitoring

**1. Certificate Expiry Monitoring**
- **Script:** `/home/gameadmin/reword-utilities/cert-maintenance/manage-cert-rotation.sh`
- **Frequency:** Daily (via cron)
- **Alerts:** Email at 30/15/7 days before expiry
- **Logs:** `/home/gameadmin/logs/nightly_tasks.log`

**2. Rate Limit Violations**
- **Location:** NGINX access/error logs
- **Log Format:** `503 Service Unavailable` entries
- **Monitoring:** Check daily maintenance report
- **Action:** Investigate if spike in violations (potential attack)

**3. Authentication Failures**
- **Location:** FastAPI application logs
- **Monitor For:**
  - Spike in 401 Unauthorized responses
  - Invalid Firebase tokens
  - Suspicious patterns (same IP, rapid attempts)
- **Alert Threshold:** >100 auth failures in 1 hour

**4. Invalid API Key Attempts**
- **Location:** FastAPI middleware logs
- **Monitor For:**
  - 403 Forbidden from X-API-Key validation
  - Pattern indicates bot/scraper activity
- **Action:** Log IP, consider IP blocking if persistent

**5. Input Validation Failures**
- **Location:** FastAPI application logs
- **Monitor For:**
  - Spike in 422 Validation Errors
  - Unusual input patterns
  - Potential injection attempts
- **Action:** Review failed validation messages

### Logging Strategy

**What to Log:**
```python
# Security events to log
- Authentication attempts (success/failure)
- Certificate pinning failures
- Rate limit violations
- Invalid API keys
- Validation failures
- Unusual request patterns
```

**What NOT to Log:**
```python
# Never log sensitive data
- Passwords
- API keys/salts
- Firebase tokens (full tokens)
- User personal data
```

**Log Rotation:**
- Daily rotation via `logrotate`
- Keep 30 days of logs
- Compress old logs
- Monitor log size

### Security Metrics Dashboard

**Key Metrics to Track:**
- API requests per minute (total)
- Authentication success rate
- Rate limit hit rate
- Certificate expiry countdown
- Error rate by type (401, 403, 422, 500)
- Response time by endpoint

**Tools:**
- Grafana dashboard (optional)
- Firebase Analytics
- Custom scripts for log analysis

### Incident Response

**If Security Breach Detected:**

1. **Immediate Actions:**
   - Rotate compromised secrets (API keys, Firebase credentials)
   - Force token revocation for affected users
   - Enable stricter rate limits
   - Block malicious IPs at firewall level

2. **Investigation:**
   - Review logs for attack pattern
   - Identify entry point
   - Assess data exposure

3. **Remediation:**
   - Patch vulnerability
   - Update security measures
   - Force app update if needed
   - Notify users if data compromised

4. **Post-Mortem:**
   - Document incident
   - Update security procedures
   - Improve monitoring

---

## Security Best Practices

### Development

1. **Never commit secrets to git**
   - Use `.env` files (gitignored)
   - Use environment variables
   - Use secret management tools

2. **Obfuscate sensitive data in app**
   - API keys as integer arrays
   - Certificate fingerprints as constants
   - No hardcoded passwords

3. **Use HTTPS everywhere**
   - All API communication over TLS
   - Certificate pinning for extra security
   - No HTTP fallback

4. **Validate all inputs**
   - Use Pydantic models
   - Never trust client data
   - Sanitize before database queries

5. **Implement proper error handling**
   - Don't expose stack traces to users
   - Log errors server-side
   - Return generic error messages

### Production

1. **Keep dependencies updated**
   - Regular security updates
   - Monitor CVEs
   - Test updates in staging first

2. **Monitor security metrics**
   - Daily review of logs
   - Alert on anomalies
   - Respond to incidents quickly

3. **Regular security audits**
   - Quarterly review of access controls
   - Penetration testing (optional)
   - Code security reviews

4. **Backup and recovery**
   - Daily MongoDB backups
   - Secure backup storage
   - Test restore procedures

5. **Document everything**
   - Security architecture
   - Incident response procedures
   - Update documentation when changes made

---

## Threat Model

### Threat: Casual Attacker (Script Kiddie)

**Profile:** Uses automated tools, no reverse engineering skills

**Blocked By:**
- Layer 1: Certificate Pinning ✅
- Layer 2: X-API-Key ✅
- Layer 4: Rate Limiting ✅

**Result:** Cannot access API at all

### Threat: Intermediate Attacker (Motivated Individual)

**Profile:** Can decompile app, extract keys, basic programming

**Attempts:**
1. Decompile Flutter app
2. Extract API_KEY and API_SALT from obfuscated arrays
3. Generate X-API-Key hash
4. Create custom client

**Blocked By:**
- Layer 1: Certificate Pinning (can't bypass without MITM) ✅
- Layer 3: Firebase Auth (needs valid user account) ✅
- Layer 4: Rate Limiting (slows down attacks) ✅

**Result:** Can access API but must have valid Firebase account, limited by rate limits

### Threat: Advanced Attacker (Professional)

**Profile:** Expert reverse engineer, can bypass all client-side protections

**Attempts:**
1. Root/jailbreak device
2. Bypass certificate pinning
3. Extract all secrets
4. Create sophisticated bot

**Blocked By:**
- Layer 3: Firebase Auth (still needs valid accounts) ⚠️
- Layer 4: Rate Limiting (can't scale attack) ✅
- Layer 5: Input Validation (prevents exploits) ✅
- Server-side business logic validation ✅

**Result:** Can access API with valid account, but limited in scope and rate

**Mitigation:**
- Monitor for unusual patterns
- Ban accounts violating terms of service
- IP blocking for persistent attacks
- Implement additional server-side checks

### Threat: DDoS Attack

**Profile:** Overwhelm server with traffic

**Blocked By:**
- Layer 4: NGINX rate limiting ✅
- Infrastructure: CloudFlare (if added) ✅
- Firewall rules ✅

**Result:** Attack mitigated at infrastructure level

---

## Security Levels Comparison

| Security Feature | V1 (Current) | V2 (New) | Improvement |
|------------------|--------------|----------|-------------|
| Certificate Pinning | Single cert, fallback | Multi-cert, strict | Better rotation |
| API Key | SHA-512 hash | SHA-512 hash (separate) | Isolated from V1 |
| Authentication | JWT tokens | Firebase tokens | Industry standard |
| Rate Limiting | NGINX | NGINX (separate zones) | Isolated limits |
| Input Validation | Manual | Pydantic models | Automatic, type-safe |

---

## Related Documents

- **Certificate Rotation:** [/docs/certificate_rotation_playbook.md](/docs/certificate_rotation_playbook.md)
- **Schema Design:** [/docs/Schema_V2_Blueprint.md](/docs/Schema_V2_Blueprint.md)
- **API Endpoints:** [/docs/API_V2_Endpoint_Plan.md](/docs/API_V2_Endpoint_Plan.md)

---

## Document History

- **2026-02-22:** Initial V2 security architecture documented
- **[Next Update]:** After first security audit or incident

---

## Contact

**Security Issues:** gamemaster@rewordgame.net
**Emergency:** [Emergency contact procedure TBD]
