// logic/word_loader.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/services.dart' show rootBundle;

class WordLoader {
  static List<String> _words = [];

  static Future<void> loadWords() async {
    String fileContent = await rootBundle.loadString('lib/data/words.txt');
    _words =
        fileContent
            .split('\n')
            .map((word) => word.trim().toLowerCase())
            .where((word) => _isAlphaOnly(word) && word.length > 2 && word.length <= 12) // Added length <= 12
            .toList();
  }

  static bool _isAlphaOnly(String word) {
    return RegExp(r'^[a-z]+$').hasMatch(word);
  }

  static List<String> get words => _words;
}
