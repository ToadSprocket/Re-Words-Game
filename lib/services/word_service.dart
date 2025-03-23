import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class WordService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> importWords(List<String> words) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final word in words) {
      batch.insert('words', {
        'word': word.toLowerCase(),
        'length': word.length,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit();
  }

  Future<List<String>> getWordsByLength(int length) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('words', where: 'length = ?', whereArgs: [length]);

    return List.generate(maps.length, (i) => maps[i]['word'] as String);
  }

  Future<bool> isValidWord(String word) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('words', where: 'word = ?', whereArgs: [word.toLowerCase()]);

    return maps.isNotEmpty;
  }

  Future<int> getWordCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearWords() async {
    final db = await _dbHelper.database;
    await db.delete('words');
  }
}
