// File: /lib/utils/secure_storage.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// A utility class for securely storing sensitive data
/// Uses flutter_secure_storage for native platforms and SharedPreferences for web
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;

  SecureStorage._internal();

  // Create storage instance with AES encryption for native platforms
  final _secureStorage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  // Key constants
  static const String _keyUserId = 'secure_userId';
  static const String _keyDisplayName = 'secure_displayName';
  static const String _keyAccessToken = 'secure_accessToken';
  static const String _keyRefreshToken = 'secure_refreshToken';
  static const String _keyTokenExpiration = 'secure_tokenExpiration';
  static const String _keyRefreshTokenDate = 'secure_refreshTokenDate';
  static const String _keyLoginAttempts = 'secure_loginAttempts';
  static const String _keyLoginLockoutUntil = 'secure_loginLockoutUntil';

  /// Store user ID securely
  Future<void> setUserId(String userId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
    } else {
      await _secureStorage.write(key: _keyUserId, value: userId);
    }
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserId);
    } else {
      return await _secureStorage.read(key: _keyUserId);
    }
  }

  /// Store user ID securely
  Future<void> setDisplayName(String displayName) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDisplayName, displayName);
    } else {
      await _secureStorage.write(key: _keyDisplayName, value: displayName);
    }
  }

  /// Retrieve user ID
  Future<String?> getDisplayName() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDisplayName);
    } else {
      return await _secureStorage.read(key: _keyDisplayName);
    }
  }

  /// Store access token securely
  Future<void> setAccessToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, token);
    } else {
      await _secureStorage.write(key: _keyAccessToken, value: token);
    }
  }

  /// Retrieve access token
  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccessToken);
    } else {
      return await _secureStorage.read(key: _keyAccessToken);
    }
  }

  /// Store refresh token securely
  Future<void> setRefreshToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRefreshToken, token);
    } else {
      await _secureStorage.write(key: _keyRefreshToken, value: token);
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    } else {
      return await _secureStorage.read(key: _keyRefreshToken);
    }
  }

  /// Store token expiration timestamp
  Future<void> setTokenExpiration(int expirationTimestamp) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTokenExpiration, expirationTimestamp);
    } else {
      await _secureStorage.write(key: _keyTokenExpiration, value: expirationTimestamp.toString());
    }
  }

  /// Retrieve token expiration timestamp
  Future<int?> getTokenExpiration() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyTokenExpiration);
    } else {
      final value = await _secureStorage.read(key: _keyTokenExpiration);
      return value != null ? int.tryParse(value) : null;
    }
  }

  /// Store refresh token date
  Future<void> setRefreshTokenDate(String isoDate) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRefreshTokenDate, isoDate);
    } else {
      await _secureStorage.write(key: _keyRefreshTokenDate, value: isoDate);
    }
  }

  /// Retrieve refresh token date
  Future<String?> getRefreshTokenDate() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshTokenDate);
    } else {
      return await _secureStorage.read(key: _keyRefreshTokenDate);
    }
  }

  /// Store login attempts count
  Future<void> setLoginAttempts(int attempts) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLoginAttempts, attempts);
    } else {
      await _secureStorage.write(key: _keyLoginAttempts, value: attempts.toString());
    }
  }

  /// Retrieve login attempts count
  Future<int> getLoginAttempts() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyLoginAttempts) ?? 0;
    } else {
      final value = await _secureStorage.read(key: _keyLoginAttempts);
      return value != null ? int.tryParse(value) ?? 0 : 0;
    }
  }

  /// Store lockout timestamp
  Future<void> setLoginLockoutUntil(int timestamp) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLoginLockoutUntil, timestamp);
    } else {
      await _secureStorage.write(key: _keyLoginLockoutUntil, value: timestamp.toString());
    }
  }

  /// Retrieve lockout timestamp
  Future<int?> getLoginLockoutUntil() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyLoginLockoutUntil);
    } else {
      final value = await _secureStorage.read(key: _keyLoginLockoutUntil);
      return value != null ? int.tryParse(value) : null;
    }
  }

  /// Reset login attempts and lockout
  Future<void> resetLoginAttempts() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLoginAttempts);
      await prefs.remove(_keyLoginLockoutUntil);
    } else {
      await _secureStorage.delete(key: _keyLoginAttempts);
      await _secureStorage.delete(key: _keyLoginLockoutUntil);
    }
  }

  /// Clear all stored authentication data
  Future<void> clearAuthData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyTokenExpiration);
      await prefs.remove(_keyRefreshTokenDate);
      // Don't clear login attempts when logging out
      // This prevents bypassing lockout by logging out
    } else {
      await _secureStorage.delete(key: _keyUserId);
      await _secureStorage.delete(key: _keyAccessToken);
      await _secureStorage.delete(key: _keyRefreshToken);
      await _secureStorage.delete(key: _keyTokenExpiration);
      await _secureStorage.delete(key: _keyRefreshTokenDate);
      // Don't clear login attempts when logging out
    }
  }
}
