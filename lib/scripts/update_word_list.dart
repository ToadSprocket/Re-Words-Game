import 'dart:io';
import '../services/word_database.dart';
import '../logic/logging_handler.dart';

Future<void> updateWordList(String filePath) async {
  try {
    final wordDb = WordDatabase();

    // Update the word list
    await wordDb.updateWordList(filePath);

    // Get the final count
    final count = await wordDb.getWordCount();
    LogService.logInfo('Word list updated successfully. Total words: $count');

    await wordDb.close();
  } catch (e) {
    LogService.logError('Failed to update word list: $e');
    exit(1);
  }
}
