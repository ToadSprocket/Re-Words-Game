// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../providers/game_state_provider.dart';
import '../logic/spelled_words_handler.dart';
import '../components/game_grid_component.dart';
import '../components/wildcard_column_component.dart';
import '../models/tile.dart';
import '../models/api_models.dart';
import '../models/board_state.dart';
import '../models/board.dart';
import '../logic/logging_handler.dart';
import '../logic/grid_loader.dart';

extension DateTimeExtension on DateTime {
  DateTime dateOnly() => DateTime(year, month, day);
}

class StateManager {
  // Modified Board Save, saves the entire board in one blob.
  static Future<bool> saveBoardState(Board board) async {
    LogService.logInfo("Saving the Board State");
    LogService.logEvent("SBS:SaveBoardState:GameId:$board.gameId");

    try {
      final prefs = await SharedPreferences.getInstance();
      final boardJson = jsonEncode(board.toJson());
      await prefs.setString('boardState', jsonEncode(boardJson));
      return true;
    } catch (e) {
      LogService.logError("Error saving board state");
      LogService.logEvent("SBS:ErrorSaving");
      return false;
    }
  }

  // Modified Board Load, Loads the blob and returns a board object.
  static Future<Board?> loadBoardState() async {
    LogService.logInfo("Loading the Board State");
    LogService.logEvent("LBS:LoadingBoardFromStorage");
    final prefs = await SharedPreferences.getInstance();
    final boardJson = prefs.getString('boardState');

    if (boardJson == null) {
      LogService.logError("No Board Data Found");
      LogService.logEvent("LBS:NoData");
      return null;
    }

    final Map<String, dynamic> boardData = jsonDecode(boardJson);
    final board = Board.fromJson(boardData);

    LogService.logEvent("LBS:BoardLoaded:GameId:$board.gameId");
    return board;
  }

  static Future<void> saveState(
    GlobalKey<GameGridComponentState> gridKey,
    GlobalKey<WildcardColumnComponentState> wildcardKey,
  ) async {
    LogService.logEvent("SS:SaveState");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('spelledWords', SpelledWordsLogic.spelledWords);
    await prefs.setInt('score', SpelledWordsLogic.score);
    await prefs.setInt('wildcardUses', prefs.getInt('wildcardUses') ?? 0);
    if (gridKey.currentState != null) {
      final gridState = gridKey.currentState!;

      // Get the original tiles
      List<Tile> originalTiles = gridState.getTiles();

      List<Tile> cleanedTiles =
          originalTiles.map((tile) {
            // Create a copy of the tile
            Map<String, dynamic> tileJson = tile.toJson();
            Tile tileCopy = Tile.fromJson(tileJson);

            // If the tile is in 'selected' state, revert it to its previous state
            if (tileCopy.state == 'selected') {
              tileCopy.state = tileCopy.previousState ?? (tileCopy.useCount > 0 ? 'used' : 'unused');
              tileCopy.previousState = null;
            }
            return tileCopy;
          }).toList();

      await prefs.setString('gridTiles', jsonEncode(cleanedTiles.map((t) => t.toJson()).toList()));
      await prefs.setString('selectedIndices', jsonEncode(gridState.getSelectedIndices()));
    }
    if (wildcardKey.currentState != null) {
      final wildcardState = wildcardKey.currentState!;
      await prefs.setString('wildcardTiles', jsonEncode(wildcardState.getTiles().map((t) => t.toJson()).toList()));
    }

    // Save a special flag to indicate that we have saved state for orientation change
    await prefs.setBool('hasOrientationState', true);
  }

  static Future<void> restoreState(
    GlobalKey<GameGridComponentState>? gridKey,
    GlobalKey<WildcardColumnComponentState>? wildcardKey,
    ValueNotifier<int> scoreNotifier,
    ValueNotifier<List<String>> spelledWordsNotifier,
  ) async {
    LogService.logEvent("RS:RestoreState");
    final prefs = await SharedPreferences.getInstance();

    // Check if we have orientation state
    final hasOrientationState = prefs.getBool('hasOrientationState') ?? false;
    if (hasOrientationState) {
      LogService.logInfo("Restoring state after orientation change");
    }

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
      final List<Tile> restoredTiles = tileData.map((data) => Tile.fromJson(data)).toList();

      // Convert restored tiles to GridLoader format
      GridLoader.gridTiles = restoredTiles.map((tile) => {'letter': tile.letter, 'value': tile.value}).toList();

      // Set tiles in grid component
      if (gridKey?.currentState != null) {
        LogService.logInfo("Setting grid tiles in component");
        gridKey!.currentState!.setTiles(restoredTiles);
      }
    }

    if (selectedIndicesJson != null && gridKey?.currentState != null) {
      LogService.logInfo("Setting selected indices in grid component");
      gridKey!.currentState!.setSelectedIndices((jsonDecode(selectedIndicesJson) as List).cast<int>());
      gridKey.currentState!.setState(() {}); // Trigger UI update
    }

    // Restore wildcard state
    final wildcardTilesJson = prefs.getString('wildcardTiles');
    if (wildcardTilesJson != null) {
      final List<dynamic> tileData = jsonDecode(wildcardTilesJson);
      final List<Tile> restoredTiles = tileData.map((data) => Tile.fromJson(data)).toList();

      // Convert restored tiles to GridLoader format, preserving isRemoved property
      GridLoader.wildcardTiles =
          restoredTiles
              .map((tile) => {'letter': tile.letter, 'value': tile.value, 'isRemoved': tile.isRemoved})
              .toList();

      // Set tiles in wildcard component
      if (wildcardKey?.currentState != null) {
        LogService.logInfo("Setting wildcard tiles in component");
        wildcardKey!.currentState!.tiles = restoredTiles;
        wildcardKey.currentState!.setState(() {}); // Trigger UI update
      }
    }

    // Clear the orientation state flag
    if (hasOrientationState) {
      await prefs.setBool('hasOrientationState', false);
    }

    // Ensure the GameStateProvider is updated with the board state
    try {
      final boardStateIndex = prefs.getInt('boardState');
      if (boardStateIndex != null) {
        // Find the GameStateProvider and update it
        final context = gridKey?.currentContext;
        if (context != null) {
          final gameStateProvider = Provider.of<GameStateProvider>(context, listen: false);
          final boardState = BoardState.values[boardStateIndex];
          gameStateProvider.updateBoardState(boardState);
          LogService.logInfo("Updated GameStateProvider with board state: $boardState");
        }
      }
    } catch (e) {
      LogService.logError("Error updating GameStateProvider with board state: $e");
    }

    LogService.logInfo('Game state restored successfully');
  }

  static Future<void> resetState(GlobalKey<GameGridComponentState>? gridKey) async {
    LogService.logEvent("RS:ResetState");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spelledWords');
    await prefs.remove('score');
    await prefs.remove('gridTiles');
    await prefs.remove('selectedIndices');
    await prefs.remove('wildcardTiles');
    await prefs.remove('timePlayedSeconds');
    await prefs.remove('boardState'); // Clear the stored board state
    await prefs.setInt('boardState', BoardState.newBoard.index); // Explicitly set to newBoard
    SpelledWordsLogic.spelledWords = [];
    SpelledWordsLogic.score = 0;
    if (gridKey?.currentState != null) {
      gridKey!.currentState!.setSelectedIndices([]);
    }
    LogService.logInfo('Game state reset successfully with board state set to newBoard');
  }

  static Future<bool> hasBoardData() async {
    final prefs = await SharedPreferences.getInstance();

    // Check all required components
    final hasGridTiles = prefs.containsKey('gridTiles');
    final hasSelectedIndices = prefs.containsKey('selectedIndices');
    final hasWildcardTiles = prefs.containsKey('wildcardTiles');
    final hasBoardExpireDate = prefs.containsKey('boardExpireDate');

    var hasData = hasGridTiles && hasSelectedIndices && hasWildcardTiles && hasBoardExpireDate;

    LogService.logEvent("HSB:HasData:$hasData");

    // All components must be present for valid board data
    return hasGridTiles && hasSelectedIndices && hasWildcardTiles && hasBoardExpireDate;
  }

  static Future<void> setStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final existingStart = prefs.getString('sessionStart');

    if (existingStart == null) {
      String now = DateTime.now().toIso8601String();
      await prefs.setString('sessionStart', now);
    } else {}
  }

  /// Save the current time when app is paused
  static Future<void> savePauseTime() async {
    final prefs = await SharedPreferences.getInstance();
    String now = DateTime.now().toIso8601String();
    await prefs.setString('appPausedAt', now);
    LogService.logInfo("App paused at: $now");
  }

  /// Reset activity time after app resume to exclude pause duration
  static Future<void> resetActivityTimeAfterPause() async {
    final prefs = await SharedPreferences.getInstance();
    final pausedAtStr = prefs.getString('appPausedAt');

    if (pausedAtStr != null) {
      final pausedAt = DateTime.parse(pausedAtStr);
      final now = DateTime.now();
      final pauseDuration = now.difference(pausedAt);

      // Get current session start
      final sessionStartStr = prefs.getString('sessionStart');
      if (sessionStartStr != null) {
        final sessionStart = DateTime.parse(sessionStartStr);

        // Adjust session start by adding pause duration
        final adjustedSessionStart = sessionStart.add(pauseDuration);
        await prefs.setString('sessionStart', adjustedSessionStart.toIso8601String());

        LogService.logInfo("Activity time adjusted: Paused for ${pauseDuration.inSeconds} seconds");
      }

      // Clear the pause timestamp
      await prefs.remove('appPausedAt');
    }
  }

  /// Check if the game is fully loaded
  static Future<bool> isGameLoaded() async {
    return GridLoader.gridTiles.isNotEmpty;
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

  /// Check if welcome animation has been shown
  static Future<bool> hasShownWelcomeAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasShownWelcomeAnimation') ?? false;
  }

  /// Mark welcome animation as shown
  static Future<void> markWelcomeAnimationShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasShownWelcomeAnimation', true);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if the board is current (loaded today)
  /// This is different from isBoardExpired() which checks if the board has expired
  /// A board can be not expired but also not current (e.g., if it was loaded yesterday)
  static Future<bool> isBoardCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final boardLoadedDateUtc = prefs.getString('boardLoadedDate');

    if (boardLoadedDateUtc == null) {
      LogService.logError("🚨 No board loaded date found. Returning false.");
      return false;
    }

    // ✅ Get user's timezone
    String localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.initializeTimeZones();
    final location = tz.getLocation(localTimeZone);

    // ✅ Convert stored UTC load date to DateTime
    final utcLoadTime = DateTime.parse(boardLoadedDateUtc).toUtc();

    // ✅ Convert UTC load date to user's local timezone
    final localLoadTime = tz.TZDateTime.from(utcLoadTime, location);

    // ✅ Get current time in user's timezone
    final nowLocal = tz.TZDateTime.now(location);

    // ✅ Check if the board was loaded today
    final isSameDay =
        localLoadTime.year == nowLocal.year &&
        localLoadTime.month == nowLocal.month &&
        localLoadTime.day == nowLocal.day;

    LogService.logInfo("🌍 User Timezone: $localTimeZone");
    LogService.logInfo("🌍 Current Local Time: $nowLocal");
    LogService.logInfo("🌍 Board Loaded UTC: $utcLoadTime");
    LogService.logInfo("🌍 Board Loaded Local: $localLoadTime");
    LogService.logInfo("🌍 Board Loaded Today?: $isSameDay");

    LogService.logEvent("IBC:IsCurrent:$isSameDay");

    return isSameDay;
  }

  static Future<bool> isBoardExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expireDateUtc = prefs.getString('boardExpireDate');

    if (expireDateUtc == null) {
      LogService.logError("🚨 No board expiration date found. Returning true.");
      return true;
    }

    // ✅ Get user's timezone
    String localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.initializeTimeZones();
    final location = tz.getLocation(localTimeZone);

    // ✅ Convert stored UTC expiration to DateTime
    final utcExpireTime = DateTime.parse(expireDateUtc).toUtc();

    // ✅ Convert UTC expiration to user's local timezone
    final localExpireTime = tz.TZDateTime.from(utcExpireTime, location);

    // ✅ Get current time in user's timezone
    final nowLocal = tz.TZDateTime.now(location);

    // ✅ Compare dates (not times)
    final isExpired =
        nowLocal.year > localExpireTime.year ||
        (nowLocal.year == localExpireTime.year && nowLocal.month > localExpireTime.month) ||
        (nowLocal.year == localExpireTime.year &&
            nowLocal.month == localExpireTime.month &&
            nowLocal.day >= localExpireTime.day);

    LogService.logInfo("🌍 User Timezone: $localTimeZone");
    LogService.logInfo("🌍 Current Local Time: $nowLocal");
    LogService.logInfo("🌍 Expiration UTC: $utcExpireTime");
    LogService.logInfo("🌍 Expiration Local: $localExpireTime");
    LogService.logInfo("🌍 Board Expired?: $isExpired");

    LogService.logEvent("IBE:Expired:$isExpired");

    return isExpired;
  }

  static Future<int?> boardExpiredDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final expireDateUtc = prefs.getString('boardExpireDate');

    if (expireDateUtc == null) {
      LogService.logError("🚨 No board expiration date found. Returning null.");
      return null; // No board data yet
    }

    // ✅ Get user's timezone
    String localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.initializeTimeZones();
    final location = tz.getLocation(localTimeZone);

    // ✅ Convert stored UTC expiration to DateTime
    final utcExpireTime = DateTime.parse(expireDateUtc).toUtc();

    // ✅ Convert UTC expiration to user's local timezone
    final localExpireTime = tz.TZDateTime.from(utcExpireTime, location);

    // ✅ Get current time in user's timezone
    final nowLocal = tz.TZDateTime.now(location);

    // Check if the board is still valid (not expired)
    if (nowLocal.year < localExpireTime.year ||
        (nowLocal.year == localExpireTime.year && nowLocal.month < localExpireTime.month) ||
        (nowLocal.year == localExpireTime.year &&
            nowLocal.month == localExpireTime.month &&
            nowLocal.day < localExpireTime.day)) {
      return 0; // Board is still valid
    } else {
      // Calculate minutes since midnight in user's timezone
      tz.TZDateTime todayMidnight = tz.TZDateTime(location, nowLocal.year, nowLocal.month, nowLocal.day);
      Duration difference = nowLocal.difference(todayMidnight);
      int minutesSinceMidnight = difference.inMinutes;

      LogService.logInfo("🌍 Minutes since midnight: $minutesSinceMidnight");
      return minutesSinceMidnight;
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

    // ✅ Get current time in user's timezone
    tz.TZDateTime nowLocal = tz.TZDateTime.now(location);

    // ✅ Calculate next midnight in user's timezone
    tz.TZDateTime nextMidnightLocal = tz.TZDateTime(
      location,
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    ).add(const Duration(days: 1));

    // ✅ Convert to UTC for storage
    DateTime nextMidnightUtc = nextMidnightLocal.toUtc();

    LogService.logInfo("🌍 User Timezone: $localTimeZone");
    LogService.logInfo("🌍 Current Local Time: $nowLocal");
    LogService.logInfo("🌍 Next Midnight Local: $nextMidnightLocal");
    LogService.logInfo("🌍 Next Midnight UTC: $nextMidnightUtc");

    final boardData = {
      'gameId': gameData.gameId,
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

    // Always set board state to newBoard when saving new board data
    await prefs.setInt('boardState', BoardState.newBoard.index);
    LogService.logInfo("Board state explicitly set to newBoard during saveBoardData");
  }
}
