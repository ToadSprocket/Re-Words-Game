// logic/scoring.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import '../models/tile.dart';
import 'word_loader.dart'; // For validWords

class Scoring {
  static int calculateScore(List<Tile> tiles) {
    int score = 0;
    for (var tile in tiles) {
      score += tile.value * tile.multiplier.round();
    }
    return score;
  }

  static bool isValidWord(String word, List<String> validWords) {
    return validWords.contains(word.toLowerCase());
  }
}
