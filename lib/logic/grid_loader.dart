// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:convert';
import 'package:reword_game/models/api_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../managers/state_manager.dart';
import '../services/api_service.dart';
import '../logic/logging_handler.dart';
import '../models/tile.dart';

class GridLoader {
  static List<Map<String, dynamic>> gridTiles = [];
  static List<Map<String, dynamic>> wildcardTiles = [];
  static Map<String, dynamic> _gridData = {};

  static const Map<String, int> _letterValues = {
    'a': 1,
    'e': 1,
    'i': 1,
    'o': 1,
    'u': 1,
    'l': 1,
    'n': 1,
    's': 1,
    't': 1,
    'r': 1,
    'd': 2,
    'g': 2,
    'b': 3,
    'c': 3,
    'm': 3,
    'p': 3,
    'f': 4,
    'h': 4,
    'v': 4,
    'w': 4,
    'y': 4,
    'k': 5,
    'j': 8,
    'x': 8,
    'q': 10,
    'z': 10,
  };

  static Future<bool> loadStoredBoard() async {
    LogService.logEvent("GL:LoadStoredBoard");
    try {
      // Clear existing data first
      gridTiles.clear();
      wildcardTiles.clear();
      _gridData.clear();

      // Get board data from StateManager
      _gridData = await StateManager.getBoardData();
      if (_gridData.isEmpty) {
        LogService.logError("No stored board data available");
        LogService.logEvent("GL:LoadStoredBoard:NoData");
        return false;
      }

      // Check if the required fields are present
      if (!_gridData.containsKey('grid') || !_gridData.containsKey('wildcards')) {
        LogService.logError(
          "Stored board data is missing required fields: grid=${_gridData.containsKey('grid')}, wildcards=${_gridData.containsKey('wildcards')}",
        );
        LogService.logEvent("GL:LoadStoredBoard:MissingFields");
        return false;
      }

      // Check if the grid and wildcards are non-empty strings
      final grid = _gridData['grid'] as String?;
      final wildcards = _gridData['wildcards'] as String?;

      if (grid == null || grid.isEmpty || wildcards == null || wildcards.isEmpty) {
        LogService.logError(
          "Stored board data has empty grid or wildcards: grid=${grid?.length ?? 0}, wildcards=${wildcards?.length ?? 0}",
        );
        LogService.logEvent("GL:LoadStoredBoard:EmptyData");
        return false;
      }

      // Set board values directly from the grid data - this is now the only way to load tiles
      _setBoardValues();

      // Verify that tiles were actually loaded
      if (gridTiles.isEmpty || wildcardTiles.isEmpty) {
        LogService.logError(
          "Failed to load tiles from stored board data: gridTiles=${gridTiles.length}, wildcardTiles=${wildcardTiles.length}",
        );
        LogService.logEvent("GL:LoadStoredBoard:NoTiles");
        return false;
      }

      LogService.logInfo(
        "Successfully loaded board from stored data: " +
            "gridTiles=${gridTiles.length}, wildcardTiles=${wildcardTiles.length}",
      );
      LogService.logEvent("GL:LoadStoredBoard:Success");
      return true;
    } catch (e) {
      LogService.logError("Error loading stored board: $e");
      LogService.logEvent("GL:LoadStoredBoard:Error");
      return false;
    }
  }

  static Future<bool> loadNewBoard(ApiService apiService, SubmitScoreRequest scoreData) async {
    LogService.logEvent("GL:LoadNewBoard");
    final prefs = await SharedPreferences.getInstance();

    try {
      _gridData.clear();
      gridTiles.clear();
      wildcardTiles.clear();

      final response = await apiService.getGameToday(scoreData);
      final gameData = response.gameData;

      if (gameData == null) {
        LogService.logError("getGameToday returned null gameData");
        LogService.logEvent("GL:LoadNewBoard:NullData");
        return false;
      }

      // ✅ Save board data to preferences
      await StateManager.saveBoardData(gameData);

      // ✅ Assign new grid data
      _gridData = {
        'grid': gameData.grid,
        'wildcards': gameData.wildcards,
        'dateStart': DateTime.parse(gameData.dateStart).toUtc(), // ✅ Convert to DateTime
        'dateExpire': DateTime.parse(gameData.dateExpire).toUtc(), // ✅ Convert to DateTime
        'wordCount': gameData.wordCount,
        'estimatedHighScore': gameData.estimatedHighScore,
      };

      // ✅ Set board values (letters, wildcards)
      _setBoardValues();

      LogService.logEvent("GL:LoadNewBoard:Success");
      return true;
    } catch (e) {
      LogService.logError("Error loading new board: $e");
      LogService.logEvent("GL:LoadNewBoard:Error");
      return false;
    }
  }

  static void _setBoardValues() {
    gridTiles =
        (_gridData['grid'] as String).split('').map((letter) {
          return {'letter': letter, 'value': _letterValues[letter.toLowerCase()] ?? 0};
        }).toList();

    wildcardTiles =
        (_gridData['wildcards'] as String).split('').map((letter) {
          final baseValue = _letterValues[letter.toLowerCase()] ?? 0;
          final value = baseValue == 1 ? 2 : baseValue;
          return {'letter': letter, 'value': value, 'isRemoved': false};
        }).toList();
  }

  static int get wordCount => _gridData['wordCount'] ?? 0;
  static String get date => _gridData['dateStart'] ?? '';
  static String get dateExpire => _gridData['dateExpire'] ?? '';
  static int get estimatedHighScore => _gridData['estimatedHighScore'] ?? 0;
}
