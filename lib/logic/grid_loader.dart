// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:reword_game/models/api_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../managers/state_manager.dart';
import '../services/api_service.dart';
import '../logic/logging_handler.dart';

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
    _gridData = await StateManager.getBoardData();
    if (_gridData.isEmpty) {
      LogService.logError('No stored board data available');
      return false;
    }
    _setBoardValues();
    return true;
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
          return {'letter': letter, 'value': value};
        }).toList();
  }

  static int get wordCount => _gridData['wordCount'] ?? 0;
  static String get date => _gridData['dateStart'] ?? '';
  static String get dateExpire => _gridData['dateExpire'] ?? '';
  static int get estimatedHighScore => _gridData['estimatedHighScore'] ?? 0;
}
