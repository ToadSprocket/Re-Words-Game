// logic/grid_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tile.dart'; // For Tile type

class GridLoader {
  static List<Map<String, dynamic>> gridTiles = [];
  static List<Map<String, dynamic>> wildcardTiles = [];
  static Map<String, dynamic> _gridData = {};

  // Scrabble letter values (moved from scoring.dart)
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

  static Future<void> loadGrid() async {
    String jsonString = await rootBundle.loadString('lib/data/daily_grid.json');
    _gridData = jsonDecode(jsonString);

    String gridString = _gridData['grid'] ?? '';
    gridTiles =
        gridString.split('').map((letter) {
          return {
            'letter': letter,
            'value': _letterValues[letter.toLowerCase()] ?? 0, // 0 for unknown
          };
        }).toList();

    String wildcardString = _gridData['wildcards'] ?? '';
    wildcardTiles =
        wildcardString.split('').map((letter) {
          return {
            'letter': letter,
            'value': _letterValues[letter.toLowerCase()] ?? 0, // 0 for non-Scrabble
          };
        }).toList();

    print('Grid tiles: ${gridTiles.length} (should be 49)');
    print('First 5 grid tiles: ${gridTiles.take(5).toList()}');
    print('Wildcard tiles: ${wildcardTiles.length} (should be 5)');
    print('Wildcards: $wildcardTiles');
    print('Word count: ${_gridData["wordCount"]}');
  }

  static int get wordCount => _gridData['wordCount'] ?? 0;
  static String get date => _gridData['date'] ?? '';
}
