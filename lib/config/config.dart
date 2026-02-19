// File: /lib/config/config.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
class Config {
  // App version information
  static const String MAJOR = "2";
  static const String MINOR = "1";
  static const String PATCH = "2";
  static const String BUILD = "04";
  static const String PHASE = "B";

  static const String buildVersion = '$MAJOR.$MINOR.$PATCH.$BUILD-$PHASE';

  // Initial Screen Sizes
  // Window size constants for the initialization routines
  static const double MIN_WINDOW_WIDTH = 1000.0;
  static const double MIN_WINDOW_HEIGHT = 800.0;
  static const double NARROW_LAYOUT_THRESHOLD = 900.0;
  static const double INITIAL_WINDOW_WIDTH = 1024.0;
  static const double INITIAL_WINDOW_HEIGHT = 768.0;

  // API Url
  static const apiUrl = 'https://rewordgame.net/api';

  // Certificate pinning configuration
  static const bool enableCertificatePinning = true; // Set to false to disable certificate pinning
  static const String certificateFingerprint =
      'DD:E9:59:7B:3C:5D:3F:11:00:85:06:6D:B4:5E:1B:80:16:F8:3A:2A:30:5C:33:BF:45:E5:4B:67:CF:05:3B:14';

  // Login security settings
  static const int maxLoginAttempts = 3; // Maximum allowed attempts before lockout
  static const int initialLockoutSeconds = 60; // 1 minute initial lockout
  static const int maxLockoutSeconds = 3600; // 1 hour maximum lockout

  // Shared Preference Keys
  static const boardStateKeyName = "reWordBoardStateV1.1";
  static const userDataKeyName = "reWordUserStateV1.1";
  static const userIdKeyName = "reWordUserInfoV1.1";

  // Secure Storage Keys
  static const String secureUserIdKey = 'secure_userId';
  static const String secureDisplayNameKey = 'secure_displayName';
  static const String secureAccessTokenKey = 'secure_accessToken';
  static const String secureRefreshTokenKey = 'secure_refreshToken';
  static const String secureTokenExpirationKey = 'secure_tokenExpiration';
  static const String secureRefreshTokenDateKey = 'secure_refreshTokenDate';
  static const String secureLoginAttemptsKey = 'secure_loginAttempts';
  static const String secureLoginLockoutUntilKey = 'secure_loginLockoutUntil';

  // Board expiration settings
  // After this many minutes past local midnight, the board is force-loaded
  // without asking the user. Below this threshold, user gets a choice dialog.
  // This value is a candidate for Firebase Remote Config in a future release.
  static int expiredBoardGracePeriodMinutes = 120;

  // API timing + retry settings
  // Keep these as non-const values so they can be tuned quickly during
  // development/testing without touching request call sites.
  //
  // Timeout intent:
  // - connect timeout: fail fast when no route/socket can be established
  // - send timeout: request payload upload took too long
  // - receive timeout: server response exceeded expected SLA threshold
  //
  // Product guidance: responses beyond ~20 seconds are considered unhealthy
  // for this app's small, optimized payloads.
  static int apiConnectTimeoutSeconds = 5;
  static int apiSendTimeoutSeconds = 10;
  static int apiReceiveTimeoutSeconds = 20;

  // Retry policy is intentionally conservative to avoid retry storms and
  // duplicate side effects while still tolerating brief transient failures.
  // Idempotent calls (e.g., GET) are safer to retry because replaying the
  // request should not create duplicate side effects on the server.
  static int apiIdempotentRequestMaxRetries = 2;

  // Non-idempotent calls (most POST operations) should retry less aggressively
  // to reduce the risk of accidental duplicate state changes.
  static int apiNonIdempotentRequestMaxRetries = 1;

  // Token refresh is treated separately from business endpoints and remains
  // conservative because failed auth paths are already surfaced to the user.
  static int tokenRefreshMaxRetries = 2;
  static int apiRetryBaseDelayMilliseconds = 500;

  // Obfuscated API key and salt as integer arrays
  static const List<int> _obfuscatedApiKey = [
    112,
    50,
    76,
    71,
    90,
    49,
    115,
    49,
    79,
    55,
    48,
    105,
    99,
    109,
    85,
    112,
    101,
    48,
    89,
    53,
    75,
    99,
    85,
    77,
    85,
    113,
    57,
    98,
    101,
    114,
    71,
    108,
    106,
    121,
    78,
    114,
    107,
    65,
    118,
    101,
    67,
    48,
    115,
  ];

  static const List<int> _obfuscatedApiSalt = [
    55,
    50,
    85,
    110,
    79,
    118,
    103,
    116,
    106,
    80,
    110,
    57,
    82,
    54,
    57,
    109,
    83,
    118,
    80,
    90,
    116,
    71,
    82,
    70,
    103,
    99,
    108,
    109,
    95,
    97,
    95,
    80,
    99,
    49,
    78,
    55,
    69,
    85,
    79,
    50,
    80,
    100,
    73,
  ];

  // Methods to retrieve the actual values when needed
  static String getApiKey() {
    return String.fromCharCodes(_obfuscatedApiKey);
  }

  static String getApiSalt() {
    return String.fromCharCodes(_obfuscatedApiSalt);
  }
}
