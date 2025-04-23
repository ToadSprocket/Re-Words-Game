// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board_state.dart';
import '../models/game_mode.dart';
import '../logic/spelled_words_handler.dart';
import '../logic/logging_handler.dart';
import '../logic/grid_loader.dart';

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
    // Update GridLoader with the new tiles
    if (_gridTiles.isNotEmpty) {
      LogService.logInfo("Updating GridLoader.gridTiles from setGridTiles (${_gridTiles.length} tiles)");
      GridLoader.gridTiles = List.from(_gridTiles);
    }
    notifyListeners();
  }

  void setWildcardTiles(List<Map<String, dynamic>> tiles) {
    _wildcardTiles = List.from(tiles);
    // Update GridLoader with the new tiles
    if (_wildcardTiles.isNotEmpty) {
      LogService.logInfo("Updating GridLoader.wildcardTiles from setWildcardTiles (${_wildcardTiles.length} tiles)");
      GridLoader.wildcardTiles = List.from(_wildcardTiles);
    }
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

      // CRITICAL: If our tiles are empty but GridLoader has tiles, use those instead
      if (_gridTiles.isEmpty && GridLoader.gridTiles.isNotEmpty) {
        LogService.logInfo(
          "Using GridLoader.gridTiles because _gridTiles is empty (${GridLoader.gridTiles.length} tiles)",
        );
        _gridTiles = List.from(GridLoader.gridTiles);
      }

      if (_wildcardTiles.isEmpty && GridLoader.wildcardTiles.isNotEmpty) {
        LogService.logInfo(
          "Using GridLoader.wildcardTiles because _wildcardTiles is empty (${GridLoader.wildcardTiles.length} tiles)",
        );
        _wildcardTiles = List.from(GridLoader.wildcardTiles);
      }

      // Save board state
      await prefs.setInt('boardState', _boardState.index);

      // Save game mode
      await prefs.setInt('gameMode', _gameMode.index);

      // Save spelled words and score
      await prefs.setStringList('spelledWords', _spelledWords);
      await prefs.setInt('score', _score);

      // Save grid and wildcard tiles
      if (_gridTiles.isNotEmpty) {
        await prefs.setString('gridTiles', jsonEncode(_gridTiles));
        LogService.logInfo("Saved ${_gridTiles.length} grid tiles to SharedPreferences");
      } else {
        LogService.logError("No grid tiles to save to SharedPreferences");
      }

      if (_wildcardTiles.isNotEmpty) {
        await prefs.setString('wildcardTiles', jsonEncode(_wildcardTiles));
        LogService.logInfo("Saved ${_wildcardTiles.length} wildcard tiles to SharedPreferences");
      } else {
        LogService.logError("No wildcard tiles to save to SharedPreferences");
      }

      // CRITICAL: Update GridLoader with the current state
      // This ensures GridLoader is always in sync with GameStateProvider
      if (_gridTiles.isNotEmpty) {
        LogService.logInfo("Updating GridLoader.gridTiles with current state (${_gridTiles.length} tiles)");
        GridLoader.gridTiles = List.from(_gridTiles);
      }

      if (_wildcardTiles.isNotEmpty) {
        LogService.logInfo("Updating GridLoader.wildcardTiles with current state (${_wildcardTiles.length} tiles)");
        GridLoader.wildcardTiles = List.from(_wildcardTiles);
      }

      // Save a flag to indicate we have saved state
      await prefs.setBool('hasGameState', true);

      LogService.logInfo("Game state saved successfully");
    } catch (e) {
      LogService.logError("Error saving game state: $e");
    }
  }

  /// Restore the game state from SharedPreferences
  Future<void> restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we have saved game state
      final hasGameState = prefs.getBool('hasGameState') ?? false;
      if (!hasGameState) {
        LogService.logInfo("No saved game state found, attempting to load from GridLoader");

        // If we don't have saved state but GridLoader has tiles, use those
        if (GridLoader.gridTiles.isNotEmpty) {
          _gridTiles = List.from(GridLoader.gridTiles);
          LogService.logInfo("Using ${_gridTiles.length} tiles from GridLoader for grid tiles");
        }

        if (GridLoader.wildcardTiles.isNotEmpty) {
          _wildcardTiles = List.from(GridLoader.wildcardTiles);
          LogService.logInfo("Using ${_wildcardTiles.length} tiles from GridLoader for wildcard tiles");
        }

        // If we still don't have tiles, try to load from cachedGrid
        if (_gridTiles.isEmpty || _wildcardTiles.isEmpty) {
          LogService.logInfo("Attempting to load tiles from cachedGrid");
          await _loadTilesFromCachedGrid(prefs);
        }
      }

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
        try {
          _gridTiles = List<Map<String, dynamic>>.from(
            (jsonDecode(gridTilesJson) as List).map((item) => Map<String, dynamic>.from(item)),
          );
          LogService.logInfo("Restored grid tiles: ${_gridTiles.length}");
        } catch (e) {
          LogService.logError("Error parsing grid tiles JSON: $e");
        }
      }

      final wildcardTilesJson = prefs.getString('wildcardTiles');
      if (wildcardTilesJson != null) {
        try {
          _wildcardTiles = List<Map<String, dynamic>>.from(
            (jsonDecode(wildcardTilesJson) as List).map((item) => Map<String, dynamic>.from(item)),
          );
          LogService.logInfo("Restored wildcard tiles: ${_wildcardTiles.length}");
        } catch (e) {
          LogService.logError("Error parsing wildcard tiles JSON: $e");
        }
      }

      // If we still don't have tiles after trying to restore from SharedPreferences,
      // try to load from GridLoader as a last resort
      if (_gridTiles.isEmpty && GridLoader.gridTiles.isNotEmpty) {
        _gridTiles = List.from(GridLoader.gridTiles);
        LogService.logInfo("Using ${_gridTiles.length} tiles from GridLoader as fallback for grid tiles");
      }

      if (_wildcardTiles.isEmpty && GridLoader.wildcardTiles.isNotEmpty) {
        _wildcardTiles = List.from(GridLoader.wildcardTiles);
        LogService.logInfo("Using ${_wildcardTiles.length} tiles from GridLoader as fallback for wildcard tiles");
      }

      // CRITICAL: Update GridLoader with the restored data
      // This ensures UI components that load from GridLoader get the correct data
      if (_gridTiles.isNotEmpty) {
        LogService.logInfo("Updating GridLoader.gridTiles with restored data (${_gridTiles.length} tiles)");
        GridLoader.gridTiles = List.from(_gridTiles);
      } else {
        LogService.logError("No grid tiles to update GridLoader with");
      }

      if (_wildcardTiles.isNotEmpty) {
        LogService.logInfo("Updating GridLoader.wildcardTiles with restored data (${_wildcardTiles.length} tiles)");
        GridLoader.wildcardTiles = List.from(_wildcardTiles);
      } else {
        LogService.logError("No wildcard tiles to update GridLoader with");
      }

      notifyListeners();
      LogService.logInfo("Game state restored successfully");
    } catch (e) {
      LogService.logError("Error restoring game state: $e");
    }
  }

  /// Load tiles from cachedGrid as a fallback
  Future<void> _loadTilesFromCachedGrid(SharedPreferences prefs) async {
    try {
      final cachedGrid = prefs.getString('cachedGrid');
      if (cachedGrid != null) {
        final Map<String, dynamic> gridData = jsonDecode(cachedGrid);

        // Check if the required fields are present
        if (gridData.containsKey('grid') && gridData.containsKey('wildcards')) {
          final grid = gridData['grid'] as String?;
          final wildcards = gridData['wildcards'] as String?;

          if (grid != null && grid.isNotEmpty) {
            // Create grid tiles from the grid string
            _gridTiles =
                grid.split('').map((letter) {
                  final value = _getLetterValue(letter);
                  return {'letter': letter, 'value': value};
                }).toList();
            LogService.logInfo("Created ${_gridTiles.length} grid tiles from cachedGrid");
          }

          if (wildcards != null && wildcards.isNotEmpty) {
            // Create wildcard tiles from the wildcards string
            _wildcardTiles =
                wildcards.split('').map((letter) {
                  final baseValue = _getLetterValue(letter);
                  final value = baseValue == 1 ? 2 : baseValue;
                  return {'letter': letter, 'value': value, 'isRemoved': false};
                }).toList();
            LogService.logInfo("Created ${_wildcardTiles.length} wildcard tiles from cachedGrid");
          }
        }
      }
    } catch (e) {
      LogService.logError("Error loading tiles from cachedGrid: $e");
    }
  }

  /// Get the value of a letter
  int _getLetterValue(String letter) {
    const Map<String, int> letterValues = {
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

    return letterValues[letter.toLowerCase()] ?? 0;
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

    // Don't clear the tiles here, as we want to keep the current board
    // But we do need to make sure GridLoader is in sync
    if (_gridTiles.isNotEmpty) {
      LogService.logInfo("Updating GridLoader.gridTiles after reset (${_gridTiles.length} tiles)");
      GridLoader.gridTiles = List.from(_gridTiles);
    }

    if (_wildcardTiles.isNotEmpty) {
      LogService.logInfo("Updating GridLoader.wildcardTiles after reset (${_wildcardTiles.length} tiles)");
      GridLoader.wildcardTiles = List.from(_wildcardTiles);
    }

    notifyListeners();
    LogService.logInfo("Game state reset");
  }

  /// Mark the game as finished
  Future<void> finishGame() async {
    if (_boardState == BoardState.inProgress) {
      updateBoardState(BoardState.finished);
      // Save state immediately
      await saveState();
      LogService.logInfo("Game marked as finished");
    }
  }
}
