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
    try {
      _gridData = await StateManager.getBoardData();
      if (_gridData.isEmpty) {
        LogService.logError("No stored board data available");
        return false;
      }

      // Check if the required fields are present
      if (!_gridData.containsKey('grid') || !_gridData.containsKey('wildcards')) {
        LogService.logError(
          "Stored board data is missing required fields: grid=${_gridData.containsKey('grid')}, wildcards=${_gridData.containsKey('wildcards')}",
        );
        return false;
      }

      // Check if the grid and wildcards are non-empty strings
      final grid = _gridData['grid'] as String?;
      final wildcards = _gridData['wildcards'] as String?;

      if (grid == null || grid.isEmpty || wildcards == null || wildcards.isEmpty) {
        LogService.logError(
          "Stored board data has empty grid or wildcards: grid=${grid?.length ?? 0}, wildcards=${wildcards?.length ?? 0}",
        );
        return false;
      }

      // Try to load the board data from SharedPreferences directly if GridLoader is empty
      final prefs = await SharedPreferences.getInstance();
      final gridTilesJson = prefs.getString('gridTiles');
      final wildcardTilesJson = prefs.getString('wildcardTiles');

      if (gridTilesJson != null && wildcardTilesJson != null) {
        LogService.logInfo("Loading tiles directly from SharedPreferences");

        // Load grid tiles
        final List<dynamic> gridTileData = jsonDecode(gridTilesJson);
        final List<Tile> restoredGridTiles = gridTileData.map((data) => Tile.fromJson(data)).toList();
        gridTiles = restoredGridTiles.map((tile) => {'letter': tile.letter, 'value': tile.value}).toList();

        // Load wildcard tiles
        final List<dynamic> wildcardTileData = jsonDecode(wildcardTilesJson);
        final List<Tile> restoredWildcardTiles = wildcardTileData.map((data) => Tile.fromJson(data)).toList();
        wildcardTiles =
            restoredWildcardTiles
                .map((tile) => {'letter': tile.letter, 'value': tile.value, 'isRemoved': tile.isRemoved})
                .toList();

        LogService.logInfo(
          "Loaded tiles directly from SharedPreferences: gridTiles=${gridTiles.length}, wildcardTiles=${wildcardTiles.length}",
        );
      } else {
        // If direct loading failed, try to set board values from _gridData
        _setBoardValues();
      }

      // Verify that tiles were actually loaded
      if (gridTiles.isEmpty || wildcardTiles.isEmpty) {
        LogService.logError(
          "Failed to load tiles from stored board data: gridTiles=${gridTiles.length}, wildcardTiles=${wildcardTiles.length}",
        );
        return false;
      }

      return true;
    } catch (e) {
      LogService.logError("Error loading stored board: $e");
      return false;
    }
  }

  static Future<bool> loadNewBoard(ApiService apiService, SubmitScoreRequest scoreData) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      _gridData.clear();
      gridTiles.clear();
      wildcardTiles.clear();

      final response = await apiService.getGameToday(scoreData);
      final gameData = response.gameData;

      if (gameData == null) {
        LogService.logError("getGameToday returned null gameData");
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

      return true;
    } catch (e) {
      LogService.logError("Error loading new board: $e");
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
