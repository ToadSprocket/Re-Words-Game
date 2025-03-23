import 'dart:io';
import 'package:flutter/services.dart';
import 'word_service.dart';

class WordImportService {
  final WordService _wordService = WordService();

  Future<void> importWordList() async {
    try {
      // Read the word list file
      final String wordList = await rootBundle.loadString('assets/word_list.txt');

      // Split into lines and filter out empty lines
      final List<String> words =
          wordList.split('\n').map((word) => word.trim()).where((word) => word.isNotEmpty).toList();

      // Import words into database
      await _wordService.importWords(words);

      // Verify import
      final int wordCount = await _wordService.getWordCount();
      print('Successfully imported $wordCount words into database');
    } catch (e) {
      print('Error importing word list: $e');
      rethrow;
    }
  }

  Future<bool> validateWordList() async {
    try {
      final int wordCount = await _wordService.getWordCount();
      return wordCount > 0;
    } catch (e) {
      print('Error validating word list: $e');
      return false;
    }
  }
}
