// logic/spelled_words_handler.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'scoring.dart';
import 'word_loader.dart';
import '../models/tile.dart';
import '../managers/state_manager.dart';
import '../models/api_models.dart';

class SpelledWordsLogic {
  static List<String> spelledWords = [];
  static int score = 0;
  static int wildCardUses = 0;

  static int _wordsPerColumn(double columnHeight, double fontSize, double spacing) {
    const lineHeightFactor = 1.4;
    final totalItemHeight = (fontSize * lineHeightFactor) + spacing;
    final maxWords = (columnHeight / totalItemHeight).floor();
    return maxWords;
  }

  static List<List<String>> splitWords({
    required List<String> words,
    required double columnHeight,
    required double fontSize,
    required double spacing,
  }) {
    final wordsPerColumn = _wordsPerColumn(columnHeight, fontSize, spacing);
    final totalWords = words.length;

    if (totalWords == 0) {
      return [[], [], []];
    } else if (totalWords <= wordsPerColumn) {
      return [words, [], []];
    } else if (totalWords <= wordsPerColumn * 2) {
      final firstColumn = words.sublist(0, wordsPerColumn);
      final secondColumn = words.sublist(wordsPerColumn);
      return [firstColumn, secondColumn, []];
    } else {
      final firstColumn = words.sublist(0, wordsPerColumn);
      final secondColumn = words.sublist(wordsPerColumn, wordsPerColumn * 2);
      final thirdColumn = words.sublist(
        wordsPerColumn * 2,
        totalWords > wordsPerColumn * 3 ? wordsPerColumn * 3 : totalWords,
      );
      return [firstColumn, secondColumn, thirdColumn];
    }
  }

  static (bool, String) addWord(List<Tile> selectedTiles) {
    String word = selectedTiles.map((tile) => tile.letter).join();
    String casedWord = word.isEmpty ? '' : word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();
    String reason = "";

    if (casedWord.isEmpty) {
      return (false, "");
    } else if (casedWord.length >= 4 &&
        casedWord.length <= 12 &&
        Scoring.isValidWord(casedWord, WordLoader.words) & !isDuplicateWord(casedWord)) {
      int wordScore = Scoring.calculateScore(selectedTiles);
      spelledWords.add(casedWord);
      score += wordScore;

      if (doesWordContainWildcard(selectedTiles)) {
        double multiplier = getWildcardMutlipliersValue(selectedTiles);
        score += (wordScore * multiplier).toInt();
        wildCardUses++;
        return (true, "Word score multiplied by $multiplier!");
      }

      return (true, "");
    } else {
      if (casedWord.length < 4) {
        reason = "'$casedWord' too short";
      } else if (casedWord.length > 12) {
        reason = "Word too long";
      } else if (isDuplicateWord(casedWord)) {
        reason = "'$casedWord' already used";
      } else {
        reason = "'$casedWord' Invalid";
      }
      return (false, reason);
    }
  }

  static bool doesWordContainWildcard(List selectedTiles) {
    return selectedTiles.any((tile) => tile.isHybrid);
  }

  static double getWildcardMutlipliersValue(List selectedTiles) {
    double multiplier = 0;
    for (var tile in selectedTiles) {
      if (tile.isHybrid) {
        multiplier += tile.value;
      }
    }

    return multiplier;
  }

  static bool isDuplicateWord(String word) {
    return spelledWords.contains(word);
  }

  static getLongestWord() {
    return spelledWords.fold("", (longest, word) => word.length > longest.length ? word : longest);
  }

  static Future<SubmitScoreRequest> getCurrentScore() async {
    final boardData = await StateManager.getBoardData();
    int totalWordsInBoard = boardData['wordCount'] ?? 0;

    int completionRate = totalWordsInBoard > 0 ? ((spelledWords.length / totalWordsInBoard) * 100).ceil() : 0;

    int longestWordLength = getLongestWord().length;
    int timePlayed = await StateManager.getTotalPlayTime();

    // 🔥 Construct and return the SubmitScoreRequest object
    return SubmitScoreRequest(
      userId: "", // ✅ This will be filled in the API service
      platform: kIsWeb ? "Web" : "Windows",
      locale: Platform.localeName,
      timePlayedSeconds: timePlayed,
      wordCount: spelledWords.length,
      wildcardUses: wildCardUses,
      score: score,
      completionRate: completionRate,
      longestWordLength: longestWordLength,
    );
  }
}
