// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
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
    print('Saved game state');
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
    print('Restored SpelledWordsLogic - Score: ${SpelledWordsLogic.score}, Words: ${SpelledWordsLogic.spelledWords}');

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
    print(
      'Restored grid - Tiles: ${gridKey?.currentState?.tiles.length}, Selected: ${gridKey?.currentState?.selectedIndices}',
    );

    // Restore wildcard state
    final wildcardTilesJson = prefs.getString('wildcardTiles');
    if (wildcardTilesJson != null) {
      final List<dynamic> tileData = jsonDecode(wildcardTilesJson);
      wildcardKey?.currentState?.tiles = tileData.map((data) => Tile.fromJson(data)).toList();
      wildcardKey?.currentState?.setState(() {}); // Trigger UI update
      print('Restored wildcards - Tiles: ${wildcardKey?.currentState?.tiles.length}');
    }
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
    print('Reset game state');
  }

  static Future<void> updatePlayTime(DateTime? sessionStart) async {
    if (sessionStart != null) {
      final prefs = await SharedPreferences.getInstance();
      final elapsed = DateTime.now().difference(sessionStart).inSeconds;
      final totalTime = (prefs.getInt('timePlayedSeconds') ?? 0) + elapsed;
      await prefs.setInt('timePlayedSeconds', totalTime);
      print('Updated play time: $totalTime seconds');
    }
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

  static Future<bool> isBoardExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expireDateUtc = prefs.getString('boardExpireDate');

    if (expireDateUtc == null) {
      print("🚨 No expire date stored! Board is expired by default.");
      return true;
    }

    final utcExpireTime = DateTime.parse(expireDateUtc).toUtc();
    final utcNow = DateTime.now().toUtc();

    print("⏳ Current UTC Time: $utcNow");
    print("📌 Board Expiration UTC: $utcExpireTime");

    return utcNow.isAfter(utcExpireTime);
  }

  static Future<int?> boardExpiredDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final expireDate = prefs.getString('boardExpireDate');
    if (expireDate == null) return null; // No board yet
    final expiry = DateTime.parse(expireDate);
    if (DateTime.now().toUtc().isBefore(expiry)) return 0; // Not expired
    return DateTime.now().toUtc().difference(expiry).inMinutes; // Minutes expired
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
    await prefs.setString('refreshTokenDate', DateTime.now().toIso8601String());

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
    return cachedGrid != null ? jsonDecode(cachedGrid) : {};
  }

  static Future<void> saveBoardData(GameData gameData) async {
    final prefs = await SharedPreferences.getInstance();
    final boardData = {
      'grid': gameData.grid,
      'wildcards': gameData.wildcards,
      'dateStart': gameData.dateStart,
      'dateExpire': gameData.dateExpire,
      'wordCount': gameData.wordCount,
      'estimatedHighScore': gameData.estimatedHighScore,
    };
    await prefs.setString('cachedGrid', jsonEncode(boardData));
    await prefs.setString('boardExpireDate', gameData.dateExpire);
    await prefs.setString('boardLoadedDate', DateTime.now().toUtc().toIso8601String());
  }

  // Removed: registerUser, fetchNewBoard, _getStats, _minutesFromMidnight
}
