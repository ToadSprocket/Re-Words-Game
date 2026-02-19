// File: /lib/utils/secure_storage.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

/// A utility class for securely storing sensitive data
/// Uses flutter_secure_storage for native platforms and SharedPreferences for web
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;

  SecureStorage._internal();

  // Create storage instance for native platforms
  // flutter_secure_storage 10.x auto-migrates to custom ciphers; encryptedSharedPreferences removed
  final _secureStorage = const FlutterSecureStorage();

  /// Store user ID securely
  Future<void> setUserId(String userId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Config.secureUserIdKey, userId);
    } else {
      await _secureStorage.write(key: Config.secureUserIdKey, value: userId);
    }
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(Config.secureUserIdKey);
    } else {
      return await _secureStorage.read(key: Config.secureUserIdKey);
    }
  }

  /// Store user ID securely
  Future<void> setDisplayName(String displayName) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Config.secureDisplayNameKey, displayName);
    } else {
      await _secureStorage.write(key: Config.secureDisplayNameKey, value: displayName);
    }
  }

  /// Retrieve user ID
  Future<String?> getDisplayName() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(Config.secureDisplayNameKey);
    } else {
      return await _secureStorage.read(key: Config.secureDisplayNameKey);
    }
  }

  /// Store access token securely
  Future<void> setAccessToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Config.secureAccessTokenKey, token);
    } else {
      await _secureStorage.write(key: Config.secureAccessTokenKey, value: token);
    }
  }

  /// Retrieve access token
  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(Config.secureAccessTokenKey);
    } else {
      return await _secureStorage.read(key: Config.secureAccessTokenKey);
    }
  }

  /// Store refresh token securely
  Future<void> setRefreshToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Config.secureRefreshTokenKey, token);
    } else {
      await _secureStorage.write(key: Config.secureRefreshTokenKey, value: token);
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(Config.secureRefreshTokenKey);
    } else {
      return await _secureStorage.read(key: Config.secureRefreshTokenKey);
    }
  }

  /// Store token expiration timestamp
  Future<void> setTokenExpiration(int expirationTimestamp) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(Config.secureTokenExpirationKey, expirationTimestamp);
    } else {
      await _secureStorage.write(key: Config.secureTokenExpirationKey, value: expirationTimestamp.toString());
    }
  }

  /// Retrieve token expiration timestamp
  Future<int?> getTokenExpiration() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(Config.secureTokenExpirationKey);
    } else {
      final value = await _secureStorage.read(key: Config.secureTokenExpirationKey);
      return value != null ? int.tryParse(value) : null;
    }
  }

  /// Store refresh token date
  Future<void> setRefreshTokenDate(String isoDate) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Config.secureRefreshTokenDateKey, isoDate);
    } else {
      await _secureStorage.write(key: Config.secureRefreshTokenDateKey, value: isoDate);
    }
  }

  /// Retrieve refresh token date
  Future<String?> getRefreshTokenDate() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(Config.secureRefreshTokenDateKey);
    } else {
      return await _secureStorage.read(key: Config.secureRefreshTokenDateKey);
    }
  }

  /// Store login attempts count
  Future<void> setLoginAttempts(int attempts) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(Config.secureLoginAttemptsKey, attempts);
    } else {
      await _secureStorage.write(key: Config.secureLoginAttemptsKey, value: attempts.toString());
    }
  }

  /// Retrieve login attempts count
  Future<int> getLoginAttempts() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(Config.secureLoginAttemptsKey) ?? 0;
    } else {
      final value = await _secureStorage.read(key: Config.secureLoginAttemptsKey);
      return value != null ? int.tryParse(value) ?? 0 : 0;
    }
  }

  /// Store lockout timestamp
  Future<void> setLoginLockoutUntil(int timestamp) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(Config.secureLoginLockoutUntilKey, timestamp);
    } else {
      await _secureStorage.write(key: Config.secureLoginLockoutUntilKey, value: timestamp.toString());
    }
  }

  /// Retrieve lockout timestamp
  Future<int?> getLoginLockoutUntil() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(Config.secureLoginLockoutUntilKey);
    } else {
      final value = await _secureStorage.read(key: Config.secureLoginLockoutUntilKey);
      return value != null ? int.tryParse(value) : null;
    }
  }

  /// Reset login attempts and lockout
  Future<void> resetLoginAttempts() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(Config.secureLoginAttemptsKey);
      await prefs.remove(Config.secureLoginLockoutUntilKey);
    } else {
      await _secureStorage.delete(key: Config.secureLoginAttemptsKey);
      await _secureStorage.delete(key: Config.secureLoginLockoutUntilKey);
    }
  }

  /// Clear all stored authentication data
  Future<void> clearAuthData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(Config.secureUserIdKey);
      await prefs.remove(Config.secureAccessTokenKey);
      await prefs.remove(Config.secureRefreshTokenKey);
      await prefs.remove(Config.secureTokenExpirationKey);
      await prefs.remove(Config.secureRefreshTokenDateKey);
      // Don't clear login attempts when logging out
      // This prevents bypassing lockout by logging out
    } else {
      await _secureStorage.delete(key: Config.secureUserIdKey);
      await _secureStorage.delete(key: Config.secureAccessTokenKey);
      await _secureStorage.delete(key: Config.secureRefreshTokenKey);
      await _secureStorage.delete(key: Config.secureTokenExpirationKey);
      await _secureStorage.delete(key: Config.secureRefreshTokenDateKey);
      // Don't clear login attempts when logging out
    }
  }
}
