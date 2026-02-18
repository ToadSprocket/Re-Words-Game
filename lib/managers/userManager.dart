// File: /lib/managers/userManager.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.

import 'dart:convert';
import 'package:reword_game/models/user.dart';
import 'package:reword_game/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/secure_storage.dart';
import '../logic/logging_handler.dart';
import '../config/config.dart';

/// Manages user authentication, state, and preferences.
///
/// Holds the current User instance and delegates API calls to ApiService.
/// Will be held by GameManager (coming soon).
class UserManager {
  // ─────────────────────────────────────────────────────────────────────────
  // DEPENDENCIES (passed in, later held by GameManager)
  // ─────────────────────────────────────────────────────────────────────────

  final ApiService _apiService;

  // ─────────────────────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────────────────────

  /// The current user (null if not loaded yet)
  User? currentUser;

  // Session tracking
  DateTime? sessionStartTime;
  DateTime? pausedAt;
  int totalPlayedSeconds = 0;

  // ─────────────────────────────────────────────────────────────────────────
  // CONSTRUCTOR
  // ─────────────────────────────────────────────────────────────────────────

  UserManager({required ApiService apiService}) : _apiService = apiService;

  // ─────────────────────────────────────────────────────────────────────────
  // CONVENIENCE GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  bool get isLoggedIn => currentUser?.isLoggedIn ?? false;
  bool get isGuest => currentUser?.isGuest ?? true;
  bool get isPro => currentUser?.isPro ?? false;
  String? get userId => currentUser?.userId;

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Load user from storage AND sync to ApiService
  Future<void> loadFromStorage() async {
    // Load User from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(Config.userDataKeyName);
    if (userJson != null) {
      currentUser = User.fromJson(jsonDecode(userJson));
      // SYNC: Give ApiService the loaded tokens
      _apiService.userId = currentUser?.userId;
      _apiService.accessToken = currentUser?.accessToken;
      _apiService.refreshToken = currentUser?.refreshToken;
    } else {
      currentUser = User();
    }
  }

  /// Save user to storage
  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (currentUser != null) {
      updatePlayTime();
      await prefs.setString(Config.userDataKeyName, jsonEncode(currentUser!.toJson()));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUTHENTICATION (delegates to ApiService)
  // ─────────────────────────────────────────────────────────────────────────

  /// Check if this is a new user (no stored credentials)
  Future<bool> isNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(Config.userDataKeyName)) {
      return true; // No stored user = IS new user
    }
    return false;
  }

  /// After registration, create User from ApiService tokens
  Future<bool> register(String locale, String platform) async {
    final response = await _apiService.register(locale, platform);
    if (response.security != null) {
      currentUser = User.fromSecurityData(response.security!);
      // ApiService already updated its tokens in register()
      await saveToStorage();
      return true;
    }
    return false;
  }

  /// Logout user - clears both UserManager and ApiService
  Future<void> logout() async {
    // Clear ApiService tokens (clears SecureStorage too)
    await _apiService.logout();

    // Reset to guest user
    currentUser = User();

    // Clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Config.userDataKeyName);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION TRACKING (moved from StateManager)
  // ─────────────────────────────────────────────────────────────────────────

  void startSession() {
    sessionStartTime = DateTime.now();
    pausedAt = null;
  }

  void pauseSession() {
    if (sessionStartTime == null) return;

    pausedAt = DateTime.now();

    final elapsed = pausedAt!.difference(sessionStartTime!).inSeconds;
    currentUser?.totalPlaytime = (currentUser?.totalPlaytime ?? 0) + elapsed;
  }

  void resumeSession() {
    if (pausedAt == null) return;

    sessionStartTime = DateTime.now();
    pausedAt = null;
  }

  int getTotalPlayTime() {
    int stored = currentUser?.totalPlaytime ?? 0;

    if (sessionStartTime == null || pausedAt != null) {
      // No active session or paused
      return stored;
    }

    // Add current session time
    final currentSession = DateTime.now().difference(sessionStartTime!).inSeconds;
    return stored + currentSession;
  }

  void updatePlayTime() {
    if (sessionStartTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(sessionStartTime!).inSeconds;

    currentUser?.totalPlaytime = (currentUser?.totalPlaytime ?? 0) + elapsed;

    // Reset session start to now (so we don't double-count)
    sessionStartTime = now;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER PREFERENCES
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> hasShownWelcome() async {
    return currentUser?.hasSeenWelcome ?? false;
  }

  Future<void> markWelcomeShown() async {
    currentUser ??= User();
    currentUser?.hasSeenWelcome = true;
    await saveToStorage();
  }

  /// Debug: Clear all user data (prefs + tokens) for fresh start
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Config.userDataKeyName);
    await SecureStorage().clearAuthData();
    currentUser = null;
    LogService.logInfo("🧹 Debug: Cleared all user data and tokens");
  }
}
