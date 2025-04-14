// logic/spelled_words_handler.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'scoring.dart';
import '../models/tile.dart';
import '../managers/state_manager.dart';
import '../models/api_models.dart';
import '../services/word_service.dart';

class SpelledWordsLogic {
  final bool disableSpellCheck;
  final WordService _wordService = WordService();

  SpelledWordsLogic({this.disableSpellCheck = false});

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

  Future<bool> isValidWord(String word) async {
    if (disableSpellCheck) return true;

    return await _wordService.isValidWord(word.toLowerCase());
  }

  Future<(bool, String)> addWord(List<Tile> selectedTiles) async {
    String word = selectedTiles.map((tile) => tile.letter).join();
    String casedWord = word.isEmpty ? '' : word.toLowerCase();
    String reason = "";
    word = casedWord.replaceFirst(casedWord[0], casedWord[0].toUpperCase());

    if (casedWord.isEmpty) {
      return (false, "");
    } else if (casedWord.length >= 4 && casedWord.length <= 12) {
      // Check if word is valid using the database first
      bool isValid = await isValidWord(casedWord);
      if (!isValid) {
        return (false, "'$word' invalid");
      }

      // Then check for duplicates
      if (isDuplicateWord(word)) {
        return (false, "'$word' already used");
      }

      int wordScore = Scoring.calculateScore(selectedTiles);
      spelledWords.add(word);
      score += wordScore;

      // Check for wildcards and apply multiplier
      bool hasWildcard = doesWordContainWildcard(selectedTiles);
      if (hasWildcard) {
        double multiplier = getWildcardMutlipliersValue(selectedTiles);
        int bonusScore = (wordScore * multiplier).toInt();
        score += bonusScore;
        wildCardUses++;

        // Log wildcard usage for debugging
        print("WILDCARD USED: Word: $word, Base Score: $wordScore, Multiplier: $multiplier, Bonus: $bonusScore");

        // Always return the multiplier message when a wildcard is used
        return (true, "Word score multiplied by $multiplier!");
      }

      return (true, "");
    } else {
      if (casedWord.length < 4) {
        reason = "'$word' too short";
      } else if (casedWord.length > 12) {
        reason = "Word too long";
      } else {
        reason = "'$word' invalid";
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
      locale: kIsWeb ? 'en-US' : Platform.localeName,
      timePlayedSeconds: timePlayed,
      wordCount: spelledWords.length,
      wildcardUses: wildCardUses,
      score: score,
      completionRate: completionRate,
      longestWordLength: longestWordLength,
    );
  }
}
