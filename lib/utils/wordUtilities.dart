// File: /lib/utils/wordUtilities.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.

import '../models/tile.dart';

/// Pure utility functions for word-related operations.
/// No state - takes inputs, returns outputs.
class WordUtilities {
  // ─────────────────────────────────────────────────────────────────────
  // UI LAYOUT HELPERS
  // ─────────────────────────────────────────────────────────────────────

  /// Calculate how many words fit in a column
  static int _wordsPerColumn(double columnHeight, double fontSize, double spacing) {
    const lineHeightFactor = 1.4;
    final totalItemHeight = (fontSize * lineHeightFactor) + spacing;
    return (columnHeight / totalItemHeight).floor();
  }

  /// Split word list into columns for UI display
  static List<List<String>> splitWords({
    required List<String> words,
    required double columnHeight,
    required double fontSize,
    required double spacing,
  }) {
    if (words.isEmpty) return [[]];

    final wordsPerColumn = _wordsPerColumn(columnHeight, fontSize, spacing);
    final totalWords = words.length;
    final numColumns = (totalWords / wordsPerColumn).ceil();

    List<List<String>> columns = [];
    for (int i = 0; i < numColumns; i++) {
      final start = i * wordsPerColumn;
      final end = (i + 1) * wordsPerColumn;
      columns.add(words.sublist(start, end > totalWords ? totalWords : end));
    }

    return columns;
  }

  // ─────────────────────────────────────────────────────────────────────
  // WILDCARD HELPERS
  // ─────────────────────────────────────────────────────────────────────

  /// Check if any tiles in the selection are wildcards (hybrid)
  static bool doesWordContainWildcard(List<Tile> tiles) {
    return tiles.any((tile) => tile.isHybrid);
  }

  /// Calculate total wildcard multiplier value
  static double getWildcardMultiplier(List<Tile> tiles) {
    double multiplier = 0;
    for (var tile in tiles) {
      if (tile.isHybrid) {
        multiplier += tile.value;
      }
    }
    return multiplier;
  }

  // ─────────────────────────────────────────────────────────────────────
  // WORD STATS
  // ─────────────────────────────────────────────────────────────────────

  /// Get the longest word from a list
  static String getLongestWord(List<String> words) {
    if (words.isEmpty) return '';
    return words.fold('', (longest, word) => word.length > longest.length ? word : longest);
  }

  /// Check if a word is already in the spelled list
  static bool isDuplicateWord(String word, List<String> spelledWords) {
    return spelledWords.contains(word);
  }
}
