// Loads and processes the word list
import 'package:flutter/services.dart' show rootBundle; // For reading files

class WordLoader {
  // List to store cleaned words
  static List<String> _words = [];

  // Load words from the file
  static Future<void> loadWords() async {
    // Read the text file as a string
    String fileContent = await rootBundle.loadString('lib/data/words.txt');

    // Split into lines and filter words
    _words =
        fileContent
            .split('\n') // Break into individual lines
            .map(
              (word) => word.trim().toLowerCase(),
            ) // Remove whitespace, make lowercase
            .where(
              (word) => _isAlphaOnly(word) && word.length > 2,
            ) // Keep only alphabetic words
            .toList();

    // Print some debug info to check the result
    print('Total words loaded: ${_words.length}');
    print('First 5 words: ${_words.take(5).toList()}');
  }

  // Check if a word has only letters (a-z)
  static bool _isAlphaOnly(String word) {
    // Regular expression: only letters allowed
    return RegExp(r'^[a-z]+$').hasMatch(word);
  }

  // Get the list of cleaned words
  static List<String> get words => _words;
}
