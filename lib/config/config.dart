// File: /lib/config/config.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
class Config {
  static const apiUrl = 'https://rewordgame.net/api';

  // Certificate pinning configuration
  static const bool enableCertificatePinning = true; // Set to false to disable certificate pinning
  static const String certificateFingerprint =
      'DD:E9:59:7B:3C:5D:3F:11:00:85:06:6D:B4:5E:1B:80:16:F8:3A:2A:30:5C:33:BF:45:E5:4B:67:CF:05:3B:14';

  // Login security settings
  static const int maxLoginAttempts = 3; // Maximum allowed attempts before lockout
  static const int initialLockoutSeconds = 60; // 1 minute initial lockout
  static const int maxLockoutSeconds = 3600; // 1 hour maximum lockout

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
