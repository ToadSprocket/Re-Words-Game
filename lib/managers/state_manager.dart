// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../logic/spelled_words_handler.dart';
import '../components/game_grid_component.dart';
import '../components/wildcard_column_component.dart';
import '../models/tile.dart';
import '../models/api_models.dart';
import '../logic/logging_handler.dart';

extension DateTimeExtension on DateTime {
  DateTime dateOnly() => DateTime(year, month, day);
}

class StateManager {
  // Existing game state methods (unchanged)
  static Future<void> saveState(
    GlobalKey<GameGridComponentState> gridKey,
    GlobalKey<WildcardColumnComponentState> wildcardKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('spelledWords', SpelledWordsLogic.spelledWords);
    await prefs.setInt('score', SpelledWordsLogic.score);
    await prefs.setInt('wildcardUses', prefs.getInt('wildcardUses') ?? 0);
    if (gridKey.currentState != null) {
      final gridState = gridKey.currentState!;
      await prefs.setString('gridTiles', jsonEncode(gridState.tiles.map((t) => t.toJson()).toList()));
      await prefs.setString('selectedIndices', jsonEncode(gridState.selectedIndices));
    }
    if (wildcardKey.currentState != null) {
      final wildcardState = wildcardKey.currentState!;
      await prefs.setString('wildcardTiles', jsonEncode(wildcardState.tiles.map((t) => t.toJson()).toList()));
    }
  }

  static Future<void> restoreState(
    GlobalKey<GameGridComponentState>? gridKey,
    GlobalKey<WildcardColumnComponentState>? wildcardKey,
    ValueNotifier<int> scoreNotifier,
    ValueNotifier<List<String>> spelledWordsNotifier,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Restore SpelledWordsLogic
    SpelledWordsLogic.score = prefs.getInt('score') ?? 0;
    SpelledWordsLogic.spelledWords = prefs.getStringList('spelledWords') ?? [];
    scoreNotifier.value = SpelledWordsLogic.score;
    spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);

    // Restore grid state
    final gridTilesJson = prefs.getString('gridTiles');
    final selectedIndicesJson = prefs.getString('selectedIndices');
    if (gridTilesJson != null) {
      final List<dynamic> tileData = jsonDecode(gridTilesJson);
      gridKey?.currentState?.tiles = tileData.map((data) => Tile.fromJson(data)).toList();
    }
    if (selectedIndicesJson != null) {
      gridKey?.currentState?.selectedIndices = (jsonDecode(selectedIndicesJson) as List).cast<int>();
    }
    gridKey?.currentState?.setState(() {}); // Trigger UI update

    // Restore wildcard state
    final wildcardTilesJson = prefs.getString('wildcardTiles');
    if (wildcardTilesJson != null) {
      final List<dynamic> tileData = jsonDecode(wildcardTilesJson);
      wildcardKey?.currentState?.tiles = tileData.map((data) => Tile.fromJson(data)).toList();
      wildcardKey?.currentState?.setState(() {}); // Trigger UI update
    }
    LogService.logInfo('Game state restored successfully');
  }

  static Future<void> resetState(GlobalKey<GameGridComponentState>? gridKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spelledWords');
    await prefs.remove('score');
    await prefs.remove('gridTiles');
    await prefs.remove('selectedIndices');
    await prefs.remove('wildcardTiles');
    await prefs.remove('timePlayedSeconds');
    SpelledWordsLogic.spelledWords = [];
    SpelledWordsLogic.score = 0;
    if (gridKey?.currentState != null) {
      gridKey!.currentState!.selectedIndices.clear();
    }
    LogService.logInfo('Game state reset successfully');
  }

  static Future<void> setStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final existingStart = prefs.getString('sessionStart');

    if (existingStart == null) {
      String now = DateTime.now().toIso8601String();
      await prefs.setString('sessionStart', now);
    } else {}
  }

  static Future<void> updatePlayTime() async {
    final prefs = await SharedPreferences.getInstance();

    String? storedStart = prefs.getString('sessionStart');
    if (storedStart != null) {
      DateTime sessionStart = DateTime.parse(storedStart);
      int elapsed = DateTime.now().difference(sessionStart).inSeconds;

      int totalTime = (prefs.getInt('timePlayedSeconds') ?? 0) + elapsed;
      await prefs.setInt('timePlayedSeconds', totalTime);

      // Move the clock forward so we can keep updating the time as the game progresses.
      // This because the user can go into the stats window multiple times and we don't want to keep adding time.
      await setStartTime();
    } else {
      LogService.logError("🚨 No session start found! Play time not updated.");
    }
  }

  static Future<int> getTotalPlayTime() async {
    await updatePlayTime(); // Update play time before returning
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('timePlayedSeconds') ?? 0;
  }

  // Storage-only methods
  static Future<bool> isNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final refreshToken = prefs.getString('refreshToken');
    final refreshTokenDate = prefs.getString('refreshTokenDate');
    if (userId == null || refreshToken == null || refreshTokenDate == null) return true;
    return DateTime.now().difference(DateTime.parse(refreshTokenDate)).inDays > 90; // 3-month expiry
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<bool> isBoardExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expireDateUtc = prefs.getString('boardExpireDate');

    if (expireDateUtc == null) {
      LogService.logError("🚨 No board expiration date found. Returning true.");
      return true;
    }

    // Convert stored UTC expiration to DateTime
    final utcDate = DateTime.parse(expireDateUtc).toUtc();
    final utcExpireDate = utcDate.dateOnly();

    // ✅ Get the player's local time
    final nowLocal = DateTime.now().dateOnly();

    LogService.logInfo("🌍 Local Timezone: ${nowLocal.timeZoneName}");
    LogService.logInfo("🌍 Expiration UTC: $utcExpireDate");
    LogService.logInfo("🌍 Current Local Time: $nowLocal");
    LogService.logInfo("🌍 Expired?: ${nowLocal.isAfter(utcExpireDate)}");

    // ✅ Check if local time has passed expiration time
    return nowLocal.isAfter(utcExpireDate);
  }

  static Future<int?> boardExpiredDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final expireDateUtc = prefs.getString('boardExpireDate');

    if (expireDateUtc == null) {
      LogService.logError("🚨 No board expiration date found. Returning null.");
      return null; // No board data yet
    }

    final utcExpireTime = DateTime.parse(expireDateUtc).toUtc();
    final localExpireTime = utcExpireTime.toLocal();
    final nowLocal = DateTime.now();
    if (isSameDay(localExpireTime, utcExpireTime)) {
      return 0; // Board is still valid
    } else {
      DateTime todayMidnight = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
      Duration difference = nowLocal.difference(todayMidnight);
      int minutesSinceMidnight = difference.inMinutes;
      return minutesSinceMidnight; // Return minutes since midnight
    }
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId'),
      'accessToken': prefs.getString('accessToken'),
      'refreshToken': prefs.getString('refreshToken'),
      'refreshTokenDate': prefs.getString('refreshTokenDate'),
    };
  }

  static Future<void> saveUserData(SecurityData security) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', security.userId);
    await prefs.setString('accessToken', security.accessToken!);
    await prefs.setString('refreshToken', security.refreshToken!);

    // Store token expiration
    if (security.expirationSeconds != null) {
      final expirationTimestamp =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + int.parse(security.expirationSeconds!);
      await prefs.setInt('accessTokenExpiration', expirationTimestamp);
    }

    print("✅ Saved user data - Expires in: ${security.expirationSeconds}");
  }

  static Future<Map<String, dynamic>> getBoardData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedGrid = prefs.getString('cachedGrid');
    if (cachedGrid == null) return {};

    final Map<String, dynamic> gridData = jsonDecode(cachedGrid);

    // ✅ Ensure dateExpire is treated as UTC DateTime
    if (gridData.containsKey('dateExpire')) {
      gridData['dateExpire'] = DateTime.parse(gridData['dateExpire']).toUtc();
    }

    return gridData;
  }

  static Future<void> saveBoardData(GameData gameData) async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ Get user's local timezone
    String localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.initializeTimeZones();
    final location = tz.getLocation(localTimeZone);

    // ✅ Convert expiration time to local midnight
    DateTime nowLocal = tz.TZDateTime.now(location);
    DateTime nextMidnightLocal = tz.TZDateTime(
      location,
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    ).add(const Duration(days: 1));

    // ✅ Convert local midnight to UTC before saving
    DateTime nextMidnightUtc = DateTime.now()
        .toUtc()
        .add(const Duration(days: 1))
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    final boardData = {
      'grid': gameData.grid,
      'wildcards': gameData.wildcards,
      'dateStart': gameData.dateStart,
      'dateExpire': nextMidnightUtc.toIso8601String(), // ✅ Store as UTC
      'wordCount': gameData.wordCount,
      'estimatedHighScore': gameData.estimatedHighScore,
    };

    await prefs.setString('cachedGrid', jsonEncode(boardData));
    await prefs.setString('boardExpireDate', nextMidnightUtc.toIso8601String());
    await prefs.setString('boardLoadedDate', DateTime.now().toUtc().toIso8601String());
  }
}
