import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class WordDatabase {
  static Database? _database;
  static const String tableName = 'words';
  static const String columnWord = 'word';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'word_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName(
            $columnWord TEXT PRIMARY KEY
          )
        ''');
      },
    );
  }

  Future<void> initializeIfEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName'));

    if (count == 0) {
      // Import words from assets/words.txt
      final file = File('assets/words.txt');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        final words = lines.where((line) => line.trim().isNotEmpty).toList();
        print('Importing ${words.length} words from file...');
        await insertWords(words);
        final newCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName'));
        print('Database now contains $newCount words');
      } else {
        print('Error: words.txt file not found in assets directory');
      }
    } else {
      print('Database already contains $count words');
    }
  }

  Future<void> insertWords(List<String> words) async {
    final db = await database;
    final batch = db.batch();

    for (final word in words) {
      batch.insert(tableName, {columnWord: word}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit();
  }

  Future<int> getWordCount() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName')) ?? 0;
  }

  Future<void> updateWordList(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Word list file not found at: $filePath');
    }

    final lines = await file.readAsLines();
    final words = lines.where((line) => line.trim().isNotEmpty).toList();

    // Clear existing words and insert new ones
    final db = await database;
    await db.delete(tableName);
    await insertWords(words);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
