// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../managers/state_manager.dart';
import '../logic/api_service.dart';
import 'spelled_words_handler.dart';

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
      print('No stored board data available');
      return false;
    }
    _setBoardValues();
    print('Loaded stored board: ${_gridData['dateStart']}');
    return true;
  }

  static Future<bool> loadNewBoard(ApiService apiService) async {
    print("📢 loadNewBoard() called!");

    final prefs = await SharedPreferences.getInstance();
    final stats = {
      'wordCount': SpelledWordsLogic.spelledWords.length,
      'timePlayedSeconds': prefs.getInt('timePlayedSeconds') ?? 0,
      'wildcardUses': prefs.getInt('wildcardUses') ?? 0,
      'score': SpelledWordsLogic.score,
      'platform': kIsWeb ? 'Web' : 'Windows',
      'locale': Platform.localeName,
    };

    print("🔍 Stats for request: $stats");

    try {
      print("📡 Calling getGameToday API...");
      final response = await apiService.getGameToday(stats);
      final gameData = response.gameData;

      if (gameData == null) {
        print("🚨 Error: getGameToday returned null gameData");
        return false;
      }

      print("✅ Successfully fetched new game: ${gameData.dateStart}");

      await StateManager.saveBoardData(gameData);

      _gridData = {
        'grid': gameData.grid,
        'wildcards': gameData.wildcards,
        'dateStart': gameData.dateStart,
        'dateExpire': gameData.dateExpire,
        'wordCount': gameData.wordCount,
        'estimatedHighScore': gameData.estimatedHighScore,
      };

      _setBoardValues();
      print("✅ Loaded new board: ${_gridData['dateStart']}");
      return true;
    } catch (e, stacktrace) {
      print("🚨 Failed to load new board: $e");
      print(stacktrace);
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
