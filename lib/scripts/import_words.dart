import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  try {
    // Initialize FFI for Windows
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Get the current directory and construct paths
    final currentDir = Directory.current.path;
    final dbDir = Directory(join(currentDir, 'database'));
    final wordsFile = File(join(currentDir, 'assets', 'words.txt'));

    // Ensure directories exist
    if (!dbDir.existsSync()) {
      print('Creating database directory...');
      dbDir.createSync();
    }

    if (!wordsFile.existsSync()) {
      print('Error: Cannot find words.txt at ${wordsFile.path}');
      print('Current directory: $currentDir');
      print('Available files in assets:');
      final assetsDir = Directory(join(currentDir, 'assets'));
      if (assetsDir.existsSync()) {
        assetsDir.listSync().forEach((entity) => print('  ${basename(entity.path)}'));
      } else {
        print('Assets directory does not exist!');
      }
      return;
    }

    final dbPath = join(dbDir.path, 'words.db');
    print('Database path: $dbPath');

    // Open and initialize database
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        print('Creating words table...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL UNIQUE COLLATE NOCASE,
            length INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );

    print('Reading words from ${wordsFile.path}');
    final words = wordsFile.readAsLinesSync().map((word) => word.trim()).where((word) => word.isNotEmpty).toList();
    print('Found ${words.length} words in file');

    try {
      print('Beginning word import...');
      await db.transaction((txn) async {
        var imported = 0;
        for (final word in words) {
          try {
            await txn.insert('words', {
              'word': word.toLowerCase(),
              'length': word.length,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
            imported++;
            if (imported % 1000 == 0) {
              print('Imported $imported words...');
            }
          } catch (e) {
            print('Error importing word "$word": $e');
          }
        }
      });

      final count = (await db.rawQuery('SELECT COUNT(*) as count FROM words')).first['count'] as int;
      print('Import complete. Database contains $count words.');

      // Verify some common words
      final testWords = ['meat', 'test', 'hello', 'world'];
      print('\nVerifying word import:');
      for (final word in testWords) {
        final result = await db.query('words', where: 'word = ? COLLATE NOCASE', whereArgs: [word]);
        print('Word "$word" exists in database: ${result.isNotEmpty}');
      }
    } finally {
      await db.close();
    }
  } catch (e, stackTrace) {
    print('Fatal error: $e');
    print('Stack trace: $stackTrace');
  }
}
