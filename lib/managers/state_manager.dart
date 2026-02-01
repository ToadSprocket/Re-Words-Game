// /lib/managers/state_manager.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
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
import '../models/apiModels.dart';
import '../models/boardState.dart';
import '../models/board.dart';
import '../logic/logging_handler.dart';
import '../logic/grid_loader.dart';

class StateManager {
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
}
