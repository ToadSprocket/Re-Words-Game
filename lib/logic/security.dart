// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/config.dart';
import '../utils/secure_storage.dart';

class Security {
  static String generateApiKeyHash() {
    final saltBytes = utf8.encode(Config.getApiSalt()); // Plain string, no base64
    final keyBytes = utf8.encode(Config.getApiKey());
    final bytesToHash = saltBytes + keyBytes;
    return sha512.convert(bytesToHash).toString();
  }
}

/// Handles login attempt rate limiting and account lockouts
class LoginSecurity {
  // Use configuration values from Config class
  static int get maxAttempts => Config.maxLoginAttempts;
  static int get initialLockoutSeconds => Config.initialLockoutSeconds;
  static int get maxLockoutSeconds => Config.maxLockoutSeconds;

  final SecureStorage _secureStorage = SecureStorage();

  /// Check if login is currently locked out
  /// Returns a tuple (isLocked, remainingSeconds)
  Future<Map<String, dynamic>> checkLockoutStatus() async {
    final lockoutUntil = await _secureStorage.getLoginLockoutUntil();

    // If no lockout is set
    if (lockoutUntil == null) {
      return {'isLocked': false, 'remainingSeconds': 0};
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remainingSeconds = lockoutUntil - now;

    // If lockout has expired
    if (remainingSeconds <= 0) {
      return {'isLocked': false, 'remainingSeconds': 0};
    }

    // Still locked out
    return {'isLocked': true, 'remainingSeconds': remainingSeconds};
  }

  /// Record a failed login attempt and apply lockout if needed
  /// Returns a tuple (isLocked, remainingSeconds)
  Future<Map<String, dynamic>> recordFailedAttempt() async {
    // First check if already locked out
    final lockoutStatus = await checkLockoutStatus();
    if (lockoutStatus['isLocked']) {
      return lockoutStatus; // Already locked out
    }

    // Get current attempt count and increment
    final attempts = await _secureStorage.getLoginAttempts();
    final newAttempts = attempts + 1;
    await _secureStorage.setLoginAttempts(newAttempts);

    // If we've reached max attempts, apply lockout
    if (newAttempts >= maxAttempts) {
      // Calculate lockout duration based on number of attempts
      // This creates an exponential backoff
      final lockoutMultiplier = (newAttempts - maxAttempts + 1);
      final lockoutDuration = initialLockoutSeconds * lockoutMultiplier;

      // Cap at maximum lockout time
      final actualLockoutDuration = lockoutDuration > maxLockoutSeconds ? maxLockoutSeconds : lockoutDuration;

      // Set lockout until timestamp
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final lockoutUntil = now + actualLockoutDuration;
      await _secureStorage.setLoginLockoutUntil(lockoutUntil);

      return {'isLocked': true, 'remainingSeconds': actualLockoutDuration};
    }

    // Not locked out yet
    return {'isLocked': false, 'remainingSeconds': 0, 'attemptsRemaining': maxAttempts - newAttempts};
  }

  /// Reset login attempts counter on successful login
  Future<void> resetAttempts() async {
    await _secureStorage.resetLoginAttempts();
  }

  /// Format remaining lockout time into a user-friendly string
  static String formatLockoutTime(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      if (minutes > 0) {
        return '$hours hour${hours > 1 ? 's' : ''} and $minutes minute${minutes > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''}';
      }
    }
  }
}
