// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html; // For web cookies
import 'package:flutter/foundation.dart' show kIsWeb;

class UserIdStorage {
  static const _cookieName = 'reword_user_id';
  static const _prefKey = 'userId';

  /// Get the stored userId, or null if none exists
  static Future<String?> getUserId() async {
    if (kIsWeb) {
      final cookies = html.document.cookie?.split(';') ?? [];
      for (var cookie in cookies) {
        final parts = cookie.trim().split('=');
        if (parts.length == 2 && parts[0] == _cookieName) {
          return parts[1];
        }
      }
      return null;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKey);
    }
  }

  /// Store a new userId
  static Future<void> setUserId(String userId) async {
    if (kIsWeb) {
      final expires = DateTime.now().add(Duration(days: 365)).toUtc();
      html.document.cookie = '$_cookieName=$userId; expires=${expires.toString()}; path=/';
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, userId);
    }
  }
}
