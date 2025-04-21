// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board_state.dart';
import '../models/game_mode.dart';
import '../logic/spelled_words_handler.dart';
import '../logic/logging_handler.dart';

/// GameStateProvider centralizes all game state management in one place.
/// This provider serves as the single source of truth for game state,
/// making it easier to maintain consistency across the app and during
/// orientation changes.
class GameStateProvider extends ChangeNotifier {
  // Game state
  BoardState _boardState = BoardState.newBoard;
  GameMode _gameMode = GameMode.classic;
  List<String> _spelledWords = [];
  int _score = 0;

  // Board data
  List<Map<String, dynamic>> _gridTiles = [];
  List<Map<String, dynamic>> _wildcardTiles = [];

  // Flag to track orientation changes
  bool _isChangingOrientation = false;

  // Getters
  BoardState get boardState => _boardState;
  GameMode get gameMode => _gameMode;
  List<String> get spelledWords => List.from(_spelledWords);
  int get score => _score;
  List<Map<String, dynamic>> get gridTiles => List.from(_gridTiles);
  List<Map<String, dynamic>> get wildcardTiles => List.from(_wildcardTiles);
  bool get isChangingOrientation => _isChangingOrientation;

  // Methods to update state
  void updateBoardState(BoardState newState) {
    if (_boardState != newState) {
      LogService.logInfo("Updating board state from $_boardState to $newState");
      _boardState = newState;
      notifyListeners();
    }
  }

  void updateGameMode(GameMode newMode) {
    if (_gameMode != newMode) {
      LogService.logInfo("Updating game mode from $_gameMode to $newMode");
      _gameMode = newMode;
      notifyListeners();
    }
  }

  void updateScore(int newScore) {
    if (_score != newScore) {
      _score = newScore;
      notifyListeners();
    }
  }

  void updateSpelledWords(List<String> words) {
    _spelledWords = List.from(words);
    notifyListeners();
  }

  void addSpelledWord(String word) {
    if (!_spelledWords.contains(word)) {
      _spelledWords.add(word);
      notifyListeners();
    }
  }

  void setGridTiles(List<Map<String, dynamic>> tiles) {
    _gridTiles = List.from(tiles);
    notifyListeners();
  }

  void setWildcardTiles(List<Map<String, dynamic>> tiles) {
    _wildcardTiles = List.from(tiles);
    notifyListeners();
  }

  void setOrientationChanging(bool changing) {
    _isChangingOrientation = changing;
    notifyListeners();
  }

  /// Save the current game state to SharedPreferences
  Future<void> saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save board state
      await prefs.setInt('boardState', _boardState.index);

      // Save game mode
      await prefs.setInt('gameMode', _gameMode.index);

      // Save spelled words and score
      await prefs.setStringList('spelledWords', _spelledWords);
      await prefs.setInt('score', _score);

      // Save grid and wildcard tiles
      await prefs.setString('gridTiles', jsonEncode(_gridTiles));
      await prefs.setString('wildcardTiles', jsonEncode(_wildcardTiles));

      LogService.logInfo("Game state saved successfully");
    } catch (e) {
      LogService.logError("Error saving game state: $e");
    }
  }

  /// Restore the game state from SharedPreferences
  Future<void> restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Restore board state
      final boardStateIndex = prefs.getInt('boardState');
      if (boardStateIndex != null) {
        _boardState = BoardState.values[boardStateIndex];
        LogService.logInfo("Restored board state: $_boardState");
      }

      // Restore game mode
      final gameModeIndex = prefs.getInt('gameMode');
      if (gameModeIndex != null) {
        _gameMode = GameMode.values[gameModeIndex];
        LogService.logInfo("Restored game mode: $_gameMode");
      }

      // Restore spelled words and score
      _spelledWords = prefs.getStringList('spelledWords') ?? [];
      _score = prefs.getInt('score') ?? 0;
      LogService.logInfo("Restored score: $_score, spelled words count: ${_spelledWords.length}");

      // Restore grid and wildcard tiles
      final gridTilesJson = prefs.getString('gridTiles');
      if (gridTilesJson != null) {
        _gridTiles = List<Map<String, dynamic>>.from(
          (jsonDecode(gridTilesJson) as List).map((item) => Map<String, dynamic>.from(item)),
        );
        LogService.logInfo("Restored grid tiles: ${_gridTiles.length}");
      }

      final wildcardTilesJson = prefs.getString('wildcardTiles');
      if (wildcardTilesJson != null) {
        _wildcardTiles = List<Map<String, dynamic>>.from(
          (jsonDecode(wildcardTilesJson) as List).map((item) => Map<String, dynamic>.from(item)),
        );
        LogService.logInfo("Restored wildcard tiles: ${_wildcardTiles.length}");
      }

      notifyListeners();
      LogService.logInfo("Game state restored successfully");
    } catch (e) {
      LogService.logError("Error restoring game state: $e");
    }
  }

  /// Sync with SpelledWordsLogic to ensure consistency
  void syncWithSpelledWordsLogic() {
    _spelledWords = List.from(SpelledWordsLogic.spelledWords);
    _score = SpelledWordsLogic.score;
    notifyListeners();
    LogService.logInfo("Synced with SpelledWordsLogic: score=${_score}, words=${_spelledWords.length}");
  }

  /// Update SpelledWordsLogic with current state
  void updateSpelledWordsLogic() {
    SpelledWordsLogic.spelledWords = List.from(_spelledWords);
    SpelledWordsLogic.score = _score;
    LogService.logInfo("Updated SpelledWordsLogic: score=${_score}, words=${_spelledWords.length}");
  }

  /// Reset the game state
  void resetState() {
    _boardState = BoardState.newBoard;
    _spelledWords = [];
    _score = 0;
    notifyListeners();
    LogService.logInfo("Game state reset");
  }
}
