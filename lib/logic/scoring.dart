// Handles scoring logic based on Scrabble values
class Scoring {
  // Map of letter values (lowercase)
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

  // Calculate the score for a word
  static int calculateWordScore(String word, int multiplier) {
    // Convert to lowercase and split into letters
    String lowerWord = word.toLowerCase();
    int score = 0;

    // Add up the value of each letter
    for (String letter in lowerWord.split('')) {
      score += _letterValues[letter] ?? 0; // 0 if letter not found (e.g., wildcard)
    }

    if (multiplier > 1) {
      score *= multiplier;
    }

    return score;
  }

  // Get the value of a single letter
  static int getLetterValue(String letter) {
    return _letterValues[letter.toLowerCase()] ?? 0;
  }
}
