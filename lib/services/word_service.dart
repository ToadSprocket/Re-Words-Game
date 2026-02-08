// File: /lib/services/word_service.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/services.dart' show rootBundle;

class WordService {
  static final WordService _instance = WordService._internal();
  static final Set<String> _wordSet = {};

  factory WordService() => _instance;

  WordService._internal();

  Future<void> initialize() async {
    if (_wordSet.isNotEmpty) return; // Only load once

    final String content = await rootBundle.loadString('assets/words.txt');
    _wordSet.addAll(content.split('\n').map((w) => w.trim().toLowerCase()));
  }

  Future<bool> isValidWord(String word) async {
    await initialize(); // Ensure words are loaded
    return _wordSet.contains(word.toLowerCase());
  }

  Future<int> getWordCount() async {
    await initialize();
    return _wordSet.length;
  }

  // Useful for testing
  void clearWords() {
    _wordSet.clear();
  }
}
