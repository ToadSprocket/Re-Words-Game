# Re-Word V2 Game API Specification
**Version:** 2.0.0  
**Date:** 2026-02-23  
**Status:** Draft for Review

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication Model](#authentication-model)
3. [User States & Capabilities](#user-states--capabilities)
4. [Core Endpoints](#core-endpoints)
5. [Complete User Flows](#complete-user-flows)
6. [Database Operations](#database-operations)
7. [Error Handling](#error-handling)
8. [Security Layers](#security-layers)

---

## Overview

### Purpose

This API provides the backend services for Re-Word game V2, supporting:
- Guest and authenticated gameplay
- Session tracking and statistics
- User authentication via Firebase (Apple, Google, Email/Password)
- Purchase verification via RevenueCat
- Leaderboard submissions (paid users only)

### Base URL

- **Development:** `http://localhost:8001`
- **Production:** `https://rewordgame.net`

### API Version

All endpoints are prefixed with `/api/v2/`

---

## Authentication Model

### Firebase Authentication

Re-Word uses **Firebase Authentication** for user identity management. Firebase handles the complexity of multiple sign-in providers through a unified interface.

#### Supported Sign-In Methods

1. **Apple Sign In** (Recommended for iOS)
   - Native iOS integration
   - Privacy-focused (can hide email)
   - Single-tap sign-in

2. **Google Sign In**
   - Cross-platform
   - Works on Android, iOS, Web
   - Quick OAuth flow

3. **Email/Password** (Fallback)
   - Traditional account creation
   - Good for web/desktop
   - Requires email verification

#### How Firebase Auth Works

```
User chooses sign-in method
         ↓
Firebase SDK handles auth flow
         ↓
User completes authentication
         ↓
Firebase returns JWT token (firebaseUid inside)
         ↓
App sends token to API
         ↓
API validates token with Firebase Admin SDK
         ↓
API knows user's identity (firebaseUid)
```

**Key Point:** Your API doesn't care HOW they signed in (Apple/Google/Email). Firebase gives you a single `firebaseUid` that identifies the user regardless of method.

#### Flutter Implementation (Simplified)

```dart
// Apple Sign In
final appleProvider = AppleAuthProvider();
final credential = await FirebaseAuth.instance.signInWithProvider(appleProvider);

// Google Sign In
final googleProvider = GoogleAuthProvider();
final credential = await FirebaseAuth.instance.signInWithProvider(googleProvider);

// Email/Password
final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// All methods return the same structure!
String firebaseUid = credential.user!.uid;
String token = await credential.user!.getIdToken();
```

---

## User States & Capabilities

### Three User States

#### 1. **Guest (Anonymous)**

**Characteristics:**
- `userId` generated (client or server)
- NO Firebase authentication
- `userStatusTypeId = 1` (guest)
- NO entry in `user_identity_links`

**Capabilities:**
- ✅ Play game (Classic mode only)
- ✅ Sessions saved to server
- ✅ Stats tracked
- ❌ Cannot submit to leaderboards
- ❌ Cannot access paid game modes
- ❌ Cannot purchase
- ❌ Cannot use cloud sync (Phase D feature)

**Use Case:** First-time players, trying before buying

---

#### 2. **Linked Guest (Logged In, No Purchase)**

**Characteristics:**
- `userId` (existing guest ID)
- ✅ Firebase authentication (`firebaseUid`)
- `userStatusTypeId = 1` (still guest)
- ✅ Entry in `user_identity_links`

**Capabilities:**
- ✅ Play game (Classic mode only)
- ✅ Sessions saved to server
- ✅ Stats tracked
- ❌ Cannot Account persists across devices
- ❌ Cannot submit to leaderboards (requires purchase)
- ❌ Cannot access paid game modes
- ❌ Cannot use cloud sync

**Use Case:** User wants to save progress but hasn't purchased yet

---

#### 3. **Paid User (Purchased)**

**Characteristics:**
- `userId` (existing)
- ✅ Firebase authentication (`firebaseUid`)
- `userStatusTypeId = 2` (paid)
- ✅ Entry in `user_identity_links`
- ✅ RevenueCat entitlement active

**Capabilities:**
- ✅ Play game (ALL modes: Classic, Scribe, Wordsmith, Master)
- ✅ Sessions saved to server
- ✅ Stats tracked
- ✅ **Submit to leaderboards**
- ✅ Set leaderboard alias
- ✅ Account persists across devices
- ✅ Cloud sync (Phase D)

**Use Case:** Paying customers ($2.99 lifetime purchase)

---

### Capability Matrix

| Feature | Guest | Linked Guest | Paid User |
|---------|-------|--------------|-----------|
| Play Classic Mode | ✅ | ✅ | ✅ |
| Play Paid Modes | ❌ | ❌ | ✅ |
| Save Sessions | ✅ | ✅ | ✅ |
| Login/Account | ❌ | ✅ | ✅ |
| Submit Leaderboard | ❌ | ❌ | ✅ |
| Set Alias | ❌ | ❌ | ✅ |
| Purchase Game | ❌ | ✅ | N/A |
| Cloud Sync (Phase D) | ❌ | ❌ | ✅ |

---

## Core Endpoints

### 1. POST `/api/v2/game/bootstrap`

**Purpose:** Primary endpoint called on app launch. Gets today's board and optionally saves previous session.

**Authentication:** 
- Layer 1: X-API-Key (REQUIRED)
- Layer 2: Firebase Token (OPTIONAL)

**Request:**

```json
{
  "userId": "uuid-or-empty",           // Empty = new user
  "firebaseToken": "jwt-or-null",      // null = anonymous
  "platform": "ios|android|web|macos|windows|linux",
  "locale": "en-us",
  "timezone": "America/Los_Angeles",
  "clientVersion": "2.1.0+3",
  "lastSession": {                      // Optional, from previous game
    "boardId": "board-20260222",
    "timePlayedSeconds": 732,
    "score": 104423,
    "wildcardUses": 4,
    "completionRatio": 78,
    "wordCount": 48,
    "longestWord": "colorado"
  }
}
```

**Response (New User):**

```json
{
  "userId": "new-uuid-generated",
  "userStatus": "guest",
  "userStatusTypeId": 1,
  "isAuthenticated": false,
  "canSubmitLeaderboard": false,
  "entitlements": {},
  "board": {
    "boardId": "board-20260223",
    "startDateUtc": "2026-02-23T00:00:00Z",
    "endDateUtc": "2026-02-24T00:00:00Z",
    "gridLetters": "TMAVAINIEYOTKGSXSIEUEHEGNNEMWNHNWITATURNSTUTEWLXN",
    "wildcardLetters": "EHWSX",
    "estimatedWordCount": 364,
    "estimatedHighScore": 2127
  },
  "message": "Welcome! Playing as guest. Log in to unlock leaderboards.",
  "sessionSaved": false
}
```

**Response (Returning Guest with Session):**

```json
{
  "userId": "existing-uuid",
  "userStatus": "guest",
  "userStatusTypeId": 1,
  "isAuthenticated": false,
  "canSubmitLeaderboard": false,
  "entitlements": {},
  "board": { /* today's board */ },
  "message": "Session saved! Log in and purchase to compete on leaderboards.",
  "sessionSaved": true,
  "previousSession": {
    "sessionId": "session-uuid",
    "boardId": "board-20260222",
    "score": 104423,
    "rank": null  // Not on leaderboard (guest)
  }
}
```

**Response (Authenticated User):**

```json
{
  "userId": "existing-uuid",
  "userStatus": "paid",
  "userStatusTypeId": 2,
  "isAuthenticated": true,
  "canSubmitLeaderboard": true,
  "entitlements": {
    "pro": {
      "isActive": true,
      "productIdentifier": "reword.pro.lifetime",
      "purchaseDateUtc": "2026-02-20T15:30:00Z"
    }
  },
  "userAlias": "Sprockett",
  "board": { /* today's board */ },
  "message": "Welcome back, Sprockett!",
  "sessionSaved": true,
  "previousSession": {
    "sessionId": "session-uuid",
    "boardId": "board-20260222",
    "score": 104423,
    "rank": 42  // Leaderboard position
  }
}
```

**API Logic:**

```python
1. Validate X-API-Key (middleware)
2. If firebaseToken provided:
   a. Validate token with Firebase
   b. Extract firebaseUid
   c. Look up user in user_identity_links
   d. If exists: load full user profile
   e. If not exists: treat as guest for now
3. If userId empty:
   a. Generate new userId (UUID)
   b. Create user in users collection
   c. userStatusTypeId = 1 (guest)
   d. Return userId to client
4. If userId provided:
   a. Validate userId exists in users
   b. Update lastSeenAtUtc
5. If lastSession provided:
   a. Create game_sessions entry
   b. Link to userId and boardId
6. Query RevenueCat for entitlements (if authenticated)
7. Get today's board from game_boards
8. Return response with board + user state
```

**Database Operations:**

```javascript
// Create or update user
db.users.updateOne(
  { userId: userId },
  { 
    $set: {
      userPlatform: platform,
      userLocale: locale,
      lastSeenAtUtc: new Date(),
      updatedAtUtc: new Date()
    },
    $setOnInsert: {
      userId: userId,
      userStatusTypeId: 1,
      isActive: true,
      createdAtUtc: new Date()
    }
  },
  { upsert: true }
);

// Save session (if provided)
if (lastSession) {
  db.game_sessions.insertOne({
    sessionId: generateUuid(),
    boardId: lastSession.boardId,
    userId: userId,
    leaderboardGameTypeId: 1,  // Classic
    leaderboardCategoryTypeId: 1,  // Daily
    startedAtUtc: /* calculated */,
    endedAtUtc: new Date(),
    timePlayedSeconds: lastSession.timePlayedSeconds,
    score: lastSession.score,
    wordCount: lastSession.wordCount,
    wildcardUses: lastSession.wildcardUses,
    completionRate: lastSession.completionRatio,
    longestWordLength: lastSession.longestWord.length,
    longestWord: lastSession.longestWord,
    createdAtUtc: new Date()
  });
}

// Get today's board
const board = db.game_boards.findOne({
  startDateUtc: { $lte: new Date() },
  endDateUtc: { $gt: new Date() }
});
```

---

### 2. POST `/api/v2/auth/link`

**Purpose:** Link existing guest userId to Firebase identity. Called when user logs in.

**Authentication:**
- Layer 1: X-API-Key (REQUIRED)
- Layer 2: Firebase Token (REQUIRED)

**Request:**

```json
{
  "userId": "existing-guest-uuid",     // Their current guest ID
  "firebaseToken": "jwt-token",        // REQUIRED
  "authProvider": "apple|google|email" // For analytics
}
```

**Response (New Link):**

```json
{
  "success": true,
  "linked": true,
  "userId": "existing-guest-uuid",     // Same ID, now linked
  "firebaseUid": "firebase-abc123",
  "userStatus": "guest",               // Still guest until purchase
  "userStatusTypeId": 1,
  "isAuthenticated": true,
  "canSubmitLeaderboard": false,       // Requires purchase
  "message": "Account linked! Purchase the game to access leaderboards and paid modes."
}
```

**Response (Already Linked - Different Device):**

```json
{
  "success": true,
  "linked": true,
  "userId": "original-user-uuid",      // Different from request!
  "firebaseUid": "firebase-abc123",
  "userStatus": "paid",
  "userStatusTypeId": 2,
  "isAuthenticated": true,
  "canSubmitLeaderboard": true,
  "sessionsMerged": 3,                 // Guest sessions merged
  "guestAccountDeleted": true,
  "message": "Welcome back! Your guest progress has been merged."
}
```

**API Logic:**

```python
1. Validate X-API-Key (middleware)
2. Validate and decode firebaseToken
3. Extract firebaseUid from token
4. Check if firebaseUid already exists in user_identity_links:
   
   CASE A: New Link (First Time Login)
   - Create user_identity_links entry
   - Link firebaseUid to userId
   - userStatusTypeId = 1 (guest, no purchase yet)
   - userIdentityStateTypeId = 2 (linked)
   - Return success
   
   CASE B: Already Linked (Device Switching)
   - Find original userId from user_identity_links
   - Merge game_sessions: update all sessions from guest userId to original userId
   - Delete guest user entry
   - Return original userId
   
5. Query RevenueCat for entitlements using firebaseUid
6. If entitlements exist:
   - Update userStatusTypeId = 2 (paid)
   - Create entitlement_snapshots entry
7. Return response with user state
```

**Database Operations:**

```javascript
// Check for existing link
const existingLink = db.user_identity_links.findOne({
  firebaseUid: firebaseUid
});

if (existingLink) {
  // CASE B: User logging in on new device
  // Merge sessions from guest account to original account
  db.game_sessions.updateMany(
    { userId: requestedUserId },  // Guest account
    { $set: { userId: existingLink.userId } }  // Original account
  );
  
  // Delete guest user
  db.users.deleteOne({ userId: requestedUserId });
  
  // Return original userId
  return existingLink.userId;
  
} else {
  // CASE A: First time linking
  db.user_identity_links.insertOne({
    firebaseUid: firebaseUid,
    userId: requestedUserId,
    revenueCatAppUserId: firebaseUid,  // Use firebaseUid as RC ID
    userStatusTypeId: 1,  // Guest until they purchase
    userIdentityStateTypeId: 2,  // Linked
    createdAtUtc: new Date(),
    lastAuthenticatedAtUtc: new Date()
  });
  
  return requestedUserId;
}
```

---

### 3. POST `/api/v2/game/submit`

**Purpose:** Submit high score to leaderboard. REQUIRES paid status.

**Authentication:**
- Layer 1: X-API-Key (REQUIRED)
- Layer 2: Firebase Token (REQUIRED)
- Layer 3: userStatusTypeId = 2 (REQUIRED)

**Request:**

```json
{
  "userId": "user-uuid",
  "sessionData": {
    "boardId": "board-20260223",
    "leaderboardGameTypeId": 1,      // 1=Classic, 2=Scribe, 3=Wordsmith, 4=Master
    "leaderboardCategoryTypeId": 1,  // 1=Daily, 2=Weekly, 3=Monthly, 4=All-Time
    "timePlayedSeconds": 847,
    "score": 125000,
    "wildcardUses": 2,
    "completionRatio": 92,
    "wordCount": 52,
    "longestWord": "generation"
  },
  "userAlias": "Sprockett"  // Required if not set, optional if already set
}
```

**Response (Success):**

```json
{
  "success": true,
  "highScoreSubmitted": true,
  "highScoreId": "highscore-uuid",
  "sessionId": "session-uuid",
  "userAlias": "Sprockett",
  "leaderboard": {
    "rank": 42,
    "totalEntries": 1247,
    "percentile": 96.6,
    "topScore": 132500,
    "userScore": 125000
  },
  "message": "High score submitted! You're ranked #42."
}
```

**Response (Not Paid):**

```json
{
  "success": false,
  "error": "PURCHASE_REQUIRED",
  "message": "Leaderboard access requires purchasing the game ($2.99 lifetime).",
  "userStatusTypeId": 1,
  "canSubmitLeaderboard": false
}
```

**Response (Alias Required):**

```json
{
  "success": false,
  "error": "ALIAS_REQUIRED",
  "message": "Please set a leaderboard alias before submitting scores.",
  "aliasSet": false
}
```

**API Logic:**

```python
1. Validate X-API-Key (middleware)
2. Validate and decode firebaseToken
3. Look up user in user_identity_links by firebaseUid
4. Check userStatusTypeId:
   - If 1 (guest): Return PURCHASE_REQUIRED error
   - If 2 (paid): Continue
5. Check if user has alias:
   - If no alias and not provided in request: Return ALIAS_REQUIRED error
   - If provided in request: Validate and set alias
6. Validate alias (if provided):
   - Check profanity filter
   - Check uniqueness (case-insensitive)
   - Check not reserved word
7. Create game_sessions entry
8. Create high_scores entry
9. Query leaderboard for user's rank
10. Return response with rank and stats
```

**Database Operations:**

```javascript
// Check user status
const userLink = db.user_identity_links.findOne({
  firebaseUid: firebaseUid
});

if (userLink.userStatusTypeId !== 2) {
  throw new Error("PURCHASE_REQUIRED");
}

// Check/set alias
const user = db.users.findOne({ userId: userId });
if (!user.userAlias) {
  if (!requestedAlias) {
    throw new Error("ALIAS_REQUIRED");
  }
  
  // Validate alias
  if (containsProfanity(requestedAlias)) {
    throw new Error("ALIAS_PROFANITY");
  }
  
  const existingAlias = db.users.findOne({
    userAlias: { $regex: new RegExp(`^${requestedAlias}$`, 'i') }
  });
  
  if (existingAlias) {
    throw new Error("ALIAS_TAKEN");
  }
  
  // Set alias
  db.users.updateOne(
    { userId: userId },
    { $set: { userAlias: requestedAlias, updatedAtUtc: new Date() } }
  );
}

// Create session
const sessionId = generateUuid();
db.game_sessions.insertOne({
  sessionId: sessionId,
  boardId: sessionData.boardId,
  userId: userId,
  leaderboardGameTypeId: sessionData.leaderboardGameTypeId,
  leaderboardCategoryTypeId: sessionData.leaderboardCategoryTypeId,
  startedAtUtc: /* calculated from timePlayedSeconds */,
  endedAtUtc: new Date(),
  ...sessionData,
  createdAtUtc: new Date()
});

// Create high score
const highScoreId = generateUuid();
db.high_scores.insertOne({
  highScoreId: highScoreId,
  boardId: sessionData.boardId,
  sessionId: sessionId,
  userId: userId,
  leaderboardGameTypeId: sessionData.leaderboardGameTypeId,
  leaderboardCategoryTypeId: sessionData.leaderboardCategoryTypeId,
  score: sessionData.score,
  wordCount: sessionData.wordCount,
  wildcardsUsed: sessionData.wildcardUses,
  longestWord: sessionData.longestWord,
  createdAtUtc: new Date()
});

// Get rank
const rank = db.high_scores.countDocuments({
  boardId: sessionData.boardId,
  leaderboardGameTypeId: sessionData.leaderboardGameTypeId,
  leaderboardCategoryTypeId: sessionData.leaderboardCategoryTypeId,
  score: { $gt: sessionData.score }
}) + 1;
```

---

### 4. PUT `/api/v2/user/alias`

**Purpose:** Set or update user's leaderboard alias. Includes profanity filter.

**Authentication:**
- Layer 1: X-API-Key (REQUIRED)
- Layer 2: Firebase Token (REQUIRED)

**Request:**

```json
{
  "userId": "user-uuid",
  "alias": "Sprockett"
}
```

**Response (Success):**

```json
{
  "success": true,
  "alias": "Sprockett",
  "aliasSet": true,
  "message": "Alias updated successfully!"
}
```

**Response (Errors):**

```json
// Alias taken
{
  "success": false,
  "error": "ALIAS_TAKEN",
  "message": "This alias is already in use. Please choose another.",
  "suggestedAliases": ["Sprockett2", "Sprockett42", "xSprockett"]
}

// Profanity detected
{
  "success": false,
  "error": "ALIAS_PROFANITY",
  "message": "This alias contains inappropriate content. Please choose another."
}

// Invalid format
{
  "success": false,
  "error": "ALIAS_INVALID",
  "message": "Alias must be 3-20 characters, letters and numbers only.",
  "requirements": {
    "minLength": 3,
    "maxLength": 20,
    "allowedChars": "letters, numbers, underscores"
  }
}
```

**API Logic:**

```python
1. Validate X-API-Key (middleware)
2. Validate and decode firebaseToken
3. Look up user in user_identity_links by firebaseUid
4. Validate alias format:
   - 3-20 characters
   - Alphanumeric + underscore only
   - Not all numbers
5. Check profanity filter (external service or local list)
6. Check uniqueness (case-insensitive)
7. Check not reserved word (system, admin, etc.)
8. Update users.userAlias
9. Return success
```

---

### 5. GET `/api/v2/leaderboard/{boardId}`

**Purpose:** View leaderboard for a specific board. Open to all users (including guests).

**Authentication:**
- Layer 1: X-API-Key (REQUIRED)
- Layer 2: Firebase Token (OPTIONAL)

**Query Parameters:**
- `gameTypeId` (optional, default: 1 = Classic)
- `categoryTypeId` (optional, default: 1 = Daily)
- `limit` (optional, default: 100, max: 500)
- `offset` (optional, default: 0)

**Request:**

```
GET /api/v2/leaderboard/board-20260223?gameTypeId=1&categoryTypeId=1&limit=10
```

**Response:**

```json
{
  "boardId": "board-20260223",
  "leaderboardGameTypeId": 1,
  "leaderboardGameTypeName": "Classic",
  "leaderboardCategoryTypeId": 1,
  "leaderboardCategoryTypeName": "Daily",
  "totalEntries": 1247,
  "timestamp": "2026-02-23T20:45:00Z",
  "entries": [
    {
      "rank": 1,
      "userAlias": "WordWizard",
      "score": 132500,
      "wordCount": 58,
      "wildcardUses": 0,
      "longestWord": "extraordinary",
      "submittedAtUtc": "2026-02-23T14:22:00Z"
    },
    {
      "rank": 2,
      "userAlias": "LetterLegend",
      "score": 128750,
      "wordCount": 56,
      "wildcardUses": 1,
      "longestWord": "magnificent",
      "submittedAtUtc": "2026-02-23T16:10:00Z"
    },
    // ... more entries
  ],
  "userEntry": {  // Only if authenticated
    "rank": 42,
    "score": 125000,
    "isTopScore": false
  }
}
```

**API Logic:**

```python
1. Validate X-API-Key (middleware)
2. Optionally validate firebaseToken (if provided)
3. Query high_scores with filters
4. Sort by score descending
5. Apply limit and offset
6. Join with users to get userAlias
7. If authenticated, find user's entry and rank
8. Return leaderboard data
```

---

### 6. POST `/api/v2/entitlements/sync`

**Purpose:** Sync RevenueCat entitlements to verify purchase status. Called after purchase.

**Authentication:**
- Layer 1: X-API-Key (REQUIRED)
- Layer 2: Firebase Token (REQUIRED)

**Request:**

```json
{
  "userId": "user-uuid",
  "forceRefresh": true  // Force query to RevenueCat
}
```

**Response (Has Entitlements):**

```json
{
  "success": true,
  "synced": true,
  "userStatusTypeId": 2,  // Updated to paid
  "entitlements": {
    "pro": {
      "isActive": true,
      "productIdentifier": "reword.pro.lifetime",
      "purchaseDateUtc": "2026-02-23T19:45:00Z",
      "expiresAtUtc": null,  // Lifetime purchase
      "platform": "ios",
      "store": "app_store"
    }
  },
  "message": "Thank you for your purchase! Leaderboards and paid modes unlocked."
}
```

**Response (No Entitlements):**

```json
{
  "success": true,
  "synced": true,
  "userStatusTypeId": 1,  // Still guest
  "entitlements": {},
  "message": "No active entitlements found."
}
```

**API Logic:**

```python
1. Validate X-API-Key (middleware)
2. Validate and decode firebaseToken
3. Look up user in user_identity_links by firebaseUid
4. Query RevenueCat API:
   - URL: GET https://api.revenuecat.com/v1/subscribers/{firebaseUid}
   - Headers: Authorization: Bearer {rc_api_key}
5. Parse entitlements response
6. If entitlements found:
   - Update users.userStatusTypeId = 2
   - Update user_identity_links.userStatusTypeId = 2
   - Create entitlement_snapshots entry
7. Return entitlement data
```

---

## Complete User Flows

### Flow 1: New User First Launch

**Scenario:** User downloads app, opens for first time

```
1. App Launch
   └─> App checks secure storage for userId
       └─> Not found (new user)

2. App calls: POST /api/v2/game/bootstrap
   Request: {
     "userId": "",
     "firebaseToken": null,
     "platform": "ios",
     ...
   }

3. API Response:
   └─> Generates new userId
   └─> Creates user in database (userStatusTypeId = 1)
   └─> Returns today's board + new userId

4. App receives response:
   └─> Saves userId to secure storage
   └─> Loads board and starts game
   └─> Shows "Playing as Guest" indicator

5. User plays game (Classic mode only)
   └─> All stats tracked locally
   └─> No session saved yet (will save on next bootstrap)
```

**Database State After:**
```javascript
// users collection
{
  userId: "new-uuid",
  userStatusTypeId: 1,  // guest
  isActive: true,
  userPlatform: "ios",
  userLocale: "en-us",
  createdAtUtc: "2026-02-23T20:00:00Z",
  lastSeenAtUtc: "2026-02-23T20:00:00Z"
}

// user_identity_links collection
// (empty - no entry created yet)

// game_sessions collection
// (empty - no session saved yet)
```

---

### Flow 2: Guest Returns Next Day

**Scenario:** Guest user opens app the next day

```
1. App Launch
   └─> App checks secure storage for userId
       └─> Found: "existing-guest-uuid"
   └─> App has previous session data stored locally

2. App calls: POST /api/v2/game/bootstrap
   Request: {
     "userId": "existing-guest-uuid",
     "firebaseToken": null,  // Still anonymous
     "lastSession": {
       "boardId": "board-20260222",  // Yesterday
       "score": 104423,
       "wordCount": 48,
       ...
     }
   }

3. API Processing:
   └─> Validates userId exists
   └─> Creates game_sessions entry for yesterday's play
   └─> Updates user.lastSeenAtUtc
   └─> Gets today's board

4. API Response:
   └─> Returns today's board
   └─> Confirms session saved
   └─> Reminds: "Log in to access leaderboards"

5. App receives response:
   └─> Loads new board
   └─> Shows "Session saved" message
   └─> Shows "Login" button in menu
```

**Database State After:**
```javascript
// users collection (updated)
{
  userId: "existing-guest-uuid",
  userStatusTypeId: 1,
  lastSeenAtUtc: "2026-02-23T20:00:00Z",  // Updated
  ...
}

// game_sessions collection (new entry)
{
  sessionId: "session-uuid",
  boardId: "board-20260222",
  userId: "existing-guest-uuid",
  score: 104423,
  wordCount: 48,
  leaderboardGameTypeId: 1,
  ...
  createdAtUtc: "2026-02-23T20:00:00Z"
}
```

---

### Flow 3: User Logs In

**Scenario:** Guest user clicks "Login" button, chooses Apple Sign In

```
1. User clicks "Login" in menu
   └─> App shows auth options (Apple, Google, Email)

2. User selects "Apple Sign In"
   └─> iOS shows native Apple auth dialog
   └─> User authenticates with Face ID
   └─> Apple returns to app with credentials

3. App processes Apple auth:
   └─> FirebaseAuth.instance.signInWithProvider(appleProvider)
   └─> Firebase validates Apple credentials
   └─> Firebase returns firebaseUid + JWT token

4. App calls: POST /api/v2/auth/link
   Request: {
     "userId": "existing-guest-uuid",
     "firebaseToken": "<jwt-token>",
     "authProvider": "apple"
   }

5. API Processing:
   CASE A: New Link (First Time)
   └─> Decodes firebaseToken, extracts firebaseUid
   └─> Checks: firebaseUid NOT in user_identity_links
   └─> Creates user_identity_links entry:
       {
         firebaseUid: "firebase-abc123",
         userId: "existing-guest-uuid",
         revenueCatAppUserId: "firebase-abc123",
         userStatusTypeId: 1,  // Still guest
         userIdentityStateTypeId: 2  // Linked
       }
   └─> Queries RevenueCat for entitlements
   └─> No purchase found (yet)

6. API Response:
   {
     "linked": true,
     "userId": "existing-guest-uuid",  // Same ID
     "userStatus": "guest",  // Still guest
     "canSubmitLeaderboard": false,  // No purchase
     "message": "Account linked! Purchase to unlock leaderboards."
   }

7. App updates UI:
   └─> Shows "Logged In" indicator
   └─> Shows user email in menu
   └─> Enables "Purchase" button
   └─> Still shows "Leaderboards (Purchase Required)"
```

**Database State After:**
```javascript
// users collection (unchanged)
{
  userId: "existing-guest-uuid",
  userStatusTypeId: 1,  // Still 1 (guest)
  ...
}

// user_identity_links collection (NEW ENTRY)
{
  firebaseUid: "firebase-abc123",
  userId: "existing-guest-uuid",
  revenueCatAppUserId: "firebase-abc123",
  userStatusTypeId: 1,  // Guest
  userIdentityStateTypeId: 2,  // Linked
  createdAtUtc: "2026-02-23T20:30:00Z",
  lastAuthenticatedAtUtc: "2026-02-23T20:30:00Z"
}
```

---

### Flow 4: User Purchases Game

**Scenario:** Logged-in user clicks "Purchase" button

```
1. User clicks "Purchase $2.99 Lifetime"
   └─> App verifies user is logged in (required)

2. App initiates RevenueCat purchase:
   └─> RevenueCat.purchase(package: lifetimePackage)
   └─> iOS/Android shows native payment dialog
   └─> User completes purchase with Touch ID/Google Pay

3. RevenueCat processes purchase:
   └─> Links purchase to firebaseUid (app user ID)
   └─> Validates receipt with Apple/Google
   └─> Activates entitlement

4. App receives purchase confirmation:
   └─> RevenueCat webhook fires (optional)
   └─> App calls: POST /api/v2/entitlements/sync

5. API Processing:
   └─> Validates firebaseToken
   └─> Queries RevenueCat API:
       GET /v1/subscribers/{firebaseUid}
   └─> RevenueCat returns entitlements:
       {
         "entitlements": {
           "pro": {
             "expires_date": null,  // Lifetime
             "product_identifier": "reword.pro.lifetime",
             "purchase_date": "2026-02-23T20:45:00Z"
           }
         }
       }
   └─> Updates user_identity_links.userStatusTypeId = 2
   └─> Updates users.userStatusTypeId = 2
   └─> Creates entitlement_snapshots entry

6. API Response:
   {
     "synced": true,
     "userStatusTypeId": 2,  // NOW PAID!
     "entitlements": { ... },
     "message": "Thank you! All features unlocked."
   }

7. App updates UI:
   └─> Shows "Pro" badge
   └─> Unlocks paid game modes (Scribe, Wordsmith, Master)
   └─> Enables "Submit to Leaderboard" button
   └─> Shows "Set Alias" if not set
```

**Database State After:**
```javascript
// users collection (updated)
{
  userId: "existing-guest-uuid",
  userStatusTypeId: 2,  // NOW PAID!
  ...
}

// user_identity_links collection (updated)
{
  firebaseUid: "firebase-abc123",
  userId: "existing-guest-uuid",
  revenueCatAppUserId: "firebase-abc123",
  userStatusTypeId: 2,  // NOW PAID!
  userIdentityStateTypeId: 2,
  ...
}

// entitlement_snapshots collection (NEW ENTRY)
{
  firebaseUid: "firebase-abc123",
  userId: "existing-guest-uuid",
  revenueCatAppUserId: "firebase-abc123",
  entitlements: {
    "pro": {
      "isActive": true,
      "productIdentifier": "reword.pro.lifetime",
      "purchaseDateUtc": "2026-02-23T20:45:00Z"
    }
  },
  source: "revenuecat",
  createdAtUtc: "2026-02-23T20:45:30Z"
}
```

---

### Flow 5: Paid User Submits High Score

**Scenario:** Paid user finishes game, wants to submit score

```
1. User completes game:
   └─> Score: 125000
   └─> Word count: 52
   └─> Completion: 92%

2. App checks:
   └─> User authenticated? YES (has firebaseToken)
   └─> User paid? YES (userStatusTypeId = 2)
   └─> User has alias? NO (first time)

3. App shows "Submit to Leaderboard" dialog:
   └─> Prompts for alias: "Enter your leaderboard name"
   └─> User enters: "Sprockett"

4. App calls: POST /api/v2/game/submit
   Request: {
     "userId": "existing-guest-uuid",
     "sessionData": {
       "boardId": "board-20260223",
       "score": 125000,
       "wordCount": 52,
       ...
     },
     "userAlias": "Sprockett"
   }

5. API Processing:
   └─> Validates firebaseToken (Layer 2)
   └─> Checks userStatusTypeId = 2 ✓
   └─> Validates alias:
       - Profanity check ✓
       - Uniqueness check ✓
       - Format check ✓
   └─> Sets users.userAlias = "Sprockett"
   └─> Creates game_sessions entry
   └─> Creates high_scores entry
   └─> Queries rank: Counts scores higher than 125000
   └─> Rank = 42

6. API Response:
   {
     "highScoreSubmitted": true,
     "userAlias": "Sprockett",
     "leaderboard": {
       "rank": 42,
       "totalEntries": 1247,
       "percentile": 96.6
     },
     "message": "You're ranked #42!"
   }

7. App shows celebration:
   └─> "🎉 High Score Submitted!"
   └─> "You're ranked #42 out of 1,247 players"
   └─> "Top 4% of players!"
   └─> Button: "View Leaderboard"
```

**Database State After:**
```javascript
// users collection (updated with alias)
{
  userId: "existing-guest-uuid",
  userStatusTypeId: 2,
  userAlias: "Sprockett",  // NEW!
  ...
}

// game_sessions collection (new entry)
{
  sessionId: "session-uuid-2",
  boardId: "board-20260223",
  userId: "existing-guest-uuid",
  score: 125000,
  wordCount: 52,
  leaderboardGameTypeId: 1,
  ...
}

// high_scores collection (NEW ENTRY)
{
  highScoreId: "highscore-uuid",
  boardId: "board-20260223",
  sessionId: "session-uuid-2",
  userId: "existing-guest-uuid",
  leaderboardGameTypeId: 1,
  leaderboardCategoryTypeId: 1,
  score: 125000,
  wordCount: 52,
  wildcardsUsed: 2,
  longestWord: "generation",
  createdAtUtc: "2026-02-23T21:15:00Z"
}
```

---

### Flow 6: Device Switching (Same User, Different Device)

**Scenario:** User logs in on Device B with same account used on Device A

```
DEVICE A (Original):
- userId: "user-original"
- firebaseUid: "firebase-abc123" (linked)
- userStatusTypeId: 2 (paid)
- Has 10 high scores

DEVICE B (New):
- User downloads app
- Plays as guest
- userId: "user-temp-guest"
- Has 3 local sessions (not synced yet)

USER LOGS IN ON DEVICE B:

1. User clicks "Login" on Device B
   └─> Chooses Apple Sign In
   └─> Same Apple account as Device A

2. Firebase authenticates:
   └─> Returns same firebaseUid: "firebase-abc123"

3. App calls: POST /api/v2/auth/link
   Request: {
     "userId": "user-temp-guest",  // Device B guest ID
     "firebaseToken": "<jwt>",
     "authProvider": "apple"
   }

4. API Processing:
   └─> Decodes firebaseToken
   └─> Extract firebaseUid: "firebase-abc123"
   └─> Checks user_identity_links:
       └─> FOUND! Already linked to "user-original"
   
   └─> MERGE LOGIC:
       a. Update game_sessions:
          - Find all sessions with userId = "user-temp-guest"
          - Update userId = "user-original"
          - Result: 3 Device B sessions now belong to original account
       
       b. Delete guest user:
          - Remove "user-temp-guest" from users collection
       
       c. Query RevenueCat:
          - Fetch entitlements for firebaseUid
          - User is paid (purchased on Device A)

5. API Response:
   {
     "linked": true,
     "userId": "user-original",  // Different from request!
     "userStatus": "paid",
     "userStatusTypeId": 2,
     "sessionsMerged": 3,  // Device B sessions merged
     "guestAccountDeleted": true,
     "message": "Welcome back! Your guest progress has been merged."
   }

6. App updates:
   └─> Replaces "user-temp-guest" with "user-original"
   └─> Shows paid status
   └─> Shows all 13 sessions (10 from A + 3 from B)
   └─> Enables leaderboard submissions
```

**Database Operations:**

```javascript
// Before merge
db.users.find({ userId: "user-temp-guest" });  // Guest account on Device B

db.game_sessions.find({ userId: "user-temp-guest" });  
// Returns 3 sessions from Device B

// Merge operation
db.game_sessions.updateMany(
  { userId: "user-temp-guest" },
  { $set: { userId: "user-original" } }
);

db.users.deleteOne({ userId: "user-temp-guest" });

// After merge
db.game_sessions.find({ userId: "user-original" });
// Returns 13 sessions (10 original + 3 merged)
```

**Key Point:** User doesn't lose any progress when logging in on a new device!

---

## Database Operations

### Collection Usage Summary

| Collection | Create | Read | Update | Delete |
|------------|--------|------|--------|--------|
| `users` | bootstrap (new user) | All endpoints | link, purchase | Device switch |
| `game_boards` | Admin only | bootstrap, leaderboard | Admin only | Never |
| `game_sessions` | bootstrap, submit | User stats | Never | Never |
| `high_scores` | submit | leaderboard | Never | Never |
| `user_identity_links` | link | All auth endpoints | purchase | Never |
| `entitlement_snapshots` | purchase sync | Admin analytics | Never | Never |
| `game_words` | Board generator | Admin only | Never | Never |

### Index Usage

**High Priority (Query Performance):**
```javascript
// user_identity_links
{ firebaseUid: 1 }  // UNIQUE, used on every authenticated request
{ userId: 1 }  // UNIQUE, join to users

// high_scores  
{ boardId: 1, leaderboardGameTypeId: 1, score: -1 }  // Leaderboard queries

// game_sessions
{ userId: 1, createdAtUtc: -1 }  // User history

// users
{ userId: 1 }  // UNIQUE, primary lookup
{ userAlias: 1 }  // UNIQUE, alias validation
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 200 | OK | Successful request |
| 201 | Created | New resource created (session, high score) |
| 400 | Bad Request | Invalid request data |
| 401 | Unauthorized | Invalid/expired Firebase token |
| 403 | Forbidden | Invalid X-API-Key |
| 404 | Not Found | userId or boardId not found |
| 409 | Conflict | Alias already taken |
| 422 | Unprocessable | Validation failed (profanity, format) |
| 500 | Server Error | Internal error |
| 503 | Service Unavailable | RevenueCat/Firebase down |

### Error Response Format

```json
{
  "success": false,
  "error": "ERROR_CODE",
  "message": "Human-readable error message",
  "details": {
    "field": "userAlias",
    "validation": "profanity_detected"
  },
  "timestamp": "2026-02-23T21:00:00Z"
}
```

### Common Error Codes

```python
# Authentication Errors
"MISSING_API_KEY" - X-API-Key header not provided
"INVALID_API_KEY" - X-API-Key doesn't match
"MISSING_FIREBASE_TOKEN" - Authorization header required
"INVALID_FIREBASE_TOKEN" - JWT validation failed
"EXPIRED_FIREBASE_TOKEN" - Token expired, refresh needed

# User Errors
"USER_NOT_FOUND" - userId doesn't exist
"USER_NOT_LINKED" - Firebase authentication required
"PURCHASE_REQUIRED" - Leaderboard access requires payment
"ALIAS_REQUIRED" - Must set alias before submitting

# Validation Errors
"ALIAS_TAKEN" - Alias already in use
"ALIAS_PROFANITY" - Alias contains inappropriate content
"ALIAS_INVALID" - Alias format invalid
"BOARD_NOT_FOUND" - boardId doesn't exist
"BOARD_EXPIRED" - Board is no longer active

# Service Errors
"REVENUECAT_ERROR" - RevenueCat API unreachable
"FIREBASE_ERROR" - Firebase Admin SDK error
"DATABASE_ERROR" - MongoDB operation failed
```

---

## Security Layers

### Layer 1: X-API-Key (Bot Protection)

**Purpose:** Prevent random bots/scrapers from accessing API

**Implementation:** Middleware validates SHA-512 hash on every request

**Validation:**
```python
expected_hash = SHA512(API_SALT_V2 + API_KEY_V2)
received_hash = request.headers['X-API-Key']

if received_hash != expected_hash:
    return 403 Forbidden
```

**Bypasses:**
- `/health` endpoint (monitoring)
- `/` root endpoint (info)

---

### Layer 2: Firebase Authentication (User Identity)

**Purpose:** Identify and authenticate individual users

**Implementation:** Dependency validates JWT on protected endpoints

**Validation:**
```python
token = request.headers['Authorization'].split('Bearer ')[1]
decoded = firebase_admin.auth.verify_id_token(token)

# Firebase validates:
# 1. Signature (cryptographic)
# 2. Expiration (1 hour)
# 3. Revocation status
# 4. Project ID

return {
    "firebaseUid": decoded['uid'],
    "email": decoded['email']
}
```

**Endpoints that require this:**
- `/auth/link` - REQUIRED
- `/game/submit` - REQUIRED
- `/user/alias` - REQUIRED
- `/entitlements/sync` - REQUIRED
- `/game/bootstrap` - OPTIONAL

---

### Layer 3: Business Logic (Authorization)

**Purpose:** Control feature access based on user status

**Implementation:** Check `userStatusTypeId` at application level

**Rules:**
```python
# Guest (userStatusTypeId = 1)
- CAN: Play Classic mode
- CAN: Save sessions
- CANNOT: Submit to leaderboards
- CANNOT: Access paid modes
- CANNOT: Set alias

# Paid (userStatusTypeId = 2)
- CAN: Everything guests can do
- CAN: Submit to leaderboards
- CAN: Access all game modes
- CAN: Set alias
- CAN: Cloud sync (Phase D)
```

---

## Apple & Google Sign-In Notes

### How It Works (You Don't Need to Worry!)

Firebase abstracts away the complexity:

**Apple Sign In:**
```dart
// Flutter code
final provider = AppleAuthProvider();
final credential = await FirebaseAuth.instance.signInWithProvider(provider);

// Firebase handles:
// 1. Redirect to Apple's auth servers
// 2. User authenticates with Face ID/Touch ID
// 3. Apple returns identity token
// 4. Firebase validates with Apple
// 5. Firebase creates/returns user account

String firebaseUid = credential.user!.uid;  // This is all you need!
```

**Google Sign In:**
```dart
// Flutter code
final provider = GoogleAuthProvider();
final credential = await FirebaseAuth.instance.signInWithProvider(provider);

// Firebase handles:
// 1. Redirect to Google's OAuth
// 2. User selects Google account
// 3. Google returns OAuth token
// 4. Firebase validates with Google
// 5. Firebase creates/returns user account

String firebaseUid = credential.user!.uid;  // Same interface!
```

**Your API doesn't care:**
- Don't need Apple Developer APIs
- Don't need Google OAuth setup
- Don't need to validate tokens yourself
- Firebase gives you one unified `firebaseUid`

**Setup Required:**
1. Enable Apple/Google in Firebase Console (5 minutes)
2. Add Firebase SDK to Flutter app (already done)
3. Configure entitlements (iOS) / SHA keys (Android)
4. Test sign-in flow

That's it! Firebase does the rest.

---

## Next Steps

### Phase C: Implementation

1. **Implement bootstrap endpoint**
2. **Implement auth/link endpoint**
3. **Implement game/submit endpoint**
4. **Implement user/alias endpoint**
5. **Implement leaderboard endpoint**
6. **Implement entitlements/sync endpoint**

### Phase D: Advanced Features (Future)

- **Cloud Sync:** Save/restore board state across devices
- **Weekly/Monthly Leaderboards:** Additional leaderboard categories
- **Friends System:** Add friends, compare scores
- **Achievements:** Track milestones and badges
- **Daily Challenges:** Special constraints for bonus points

---

## Questions for Review

1. **Is the guest → linked guest → paid user flow clear?**

2. **Do the device switching mechanics make sense?** (merge sessions)

3. **Are the leaderboard access rules what you want?** (paid only)

4. **Is the alias system adequate?** (uniqueness, profanity filter)

5. **Should we add any other endpoints for Phase C?**

6. **Any concerns about the Firebase auth integration?**

---

## Glossary

- **userId:** Internal game user ID (UUID), stored in client
- **firebaseUid:** Firebase authentication ID (external identity)
- **userStatusTypeId:** 1 = guest, 2 = paid
- **userIdentityStateTypeId:** 1 = unlinked, 2 = linked
- **leaderboardGameTypeId:** 1 = Classic, 2 = Scribe, 3 = Wordsmith, 4 = Master
- **leaderboardCategoryTypeId:** 1 = Daily, 2 = Weekly, 3 = Monthly, 4 = All-Time
- **revenueCatAppUserId:** RevenueCat user ID (same as firebaseUid)
- **boardId:** Unique identifier for each daily board

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-23  
**Status:** Ready for Review

Read this through tonight and let me know what questions you have! We can refine until it's perfect before writing any code.
