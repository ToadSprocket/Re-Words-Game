import 'scoring.dart';

class SpelledWordsLogic {
  // Static state (for now, until you refactor to a proper state manager)
  static List<String> spelledWords = [];
  static int score = 0;

  static int _wordsPerColumn(double columnHeight, double fontSize, double spacing) {
    const lineHeightFactor = 1.4; // Your adjusted value
    final totalItemHeight = (fontSize * lineHeightFactor) + spacing;
    final maxWords = (columnHeight / totalItemHeight).floor();
    print("Column height: $columnHeight, Item height: $totalItemHeight, Max words: $maxWords");
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

  static void addWord(String word, {int multiplier = 1}) {
    // Case the word
    String casedWord = word.isEmpty ? '' : word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();

    // Placeholder spell check (replace with real validation)
    bool isValid = true; // e.g., checkDictionary(casedWord);

    if (isValid) {
      int wordScore = Scoring.calculateWordScore(casedWord, multiplier);
      spelledWords.add(casedWord);
      score += wordScore;
      print("Added '$casedWord', Score: $score, Words: ${spelledWords.length}");
    }
  }
}
