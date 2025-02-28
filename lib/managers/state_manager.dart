// lib/managers/state_manager.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/spelled_words_handler.dart';
import '../components/game_grid_component.dart';
import '../components/wildcard_column_component.dart';
import '../models/tile.dart';

class StateManager {
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
    GlobalKey<GameGridComponentState> gridKey,
    GlobalKey<WildcardColumnComponentState> wildcardKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final savedWords = prefs.getStringList('spelledWords');
    if (savedWords != null) {
      SpelledWordsLogic.spelledWords = savedWords;
      SpelledWordsLogic.score = prefs.getInt('score') ?? 0;
      final timePlayedSeconds = prefs.getInt('timePlayedSeconds') ?? 0;
      final boardLoadedDate = prefs.getString('boardLoadedDate');
    }
    if (gridKey.currentState != null) {
      final gridState = gridKey.currentState!;
      final savedTiles = prefs.getString('gridTiles');
      final savedIndices = prefs.getString('selectedIndices');
      if (savedTiles != null) {
        gridState.tiles =
            (jsonDecode(savedTiles) as List).map((item) => Tile.fromJson(item as Map<String, dynamic>)).toList();
        print('Restored grid tiles');
      }
      if (savedIndices != null) {
        gridState.selectedIndices = (jsonDecode(savedIndices) as List).map((i) => i as int).toList();
        print('Restored selected indices');
      }
    }
    if (wildcardKey.currentState != null) {
      final savedWildcardTiles = prefs.getString('wildcardTiles');
      if (savedWildcardTiles != null) {
        wildcardKey.currentState!.tiles =
            (jsonDecode(savedWildcardTiles) as List)
                .map((item) => Tile.fromJson(item as Map<String, dynamic>))
                .toList();
        print('Restored wildcard tiles');
      }
    }
  }

  static Future<void> resetState(GlobalKey<GameGridComponentState> gridKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spelledWords');
    await prefs.remove('score');
    await prefs.remove('gridTiles');
    await prefs.remove('selectedIndices');
    await prefs.remove('wildcardTiles');
    await prefs.remove('timePlayedSeconds');
    SpelledWordsLogic.spelledWords = [];
    SpelledWordsLogic.score = 0;
    if (gridKey.currentState != null) {
      gridKey.currentState!.selectedIndices.clear();
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
}
