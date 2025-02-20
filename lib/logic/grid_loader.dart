// Loads the daily grid data
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'scoring.dart'; // Import scoring for letter values

class GridLoader {
  // Store the grid as a list of letter-value pairs
  static List<Map<String, dynamic>> _gridTiles = [];
  // Store wildcards as a list of letter-value pairs
  static List<Map<String, dynamic>> _wildcardTiles = [];
  // Other grid metadata
  static Map<String, dynamic> _gridData = {};

  // Load the grid from a local file (for testing)
  static Future<void> loadGrid() async {
    // Read the JSON file as a string
    String jsonString = await rootBundle.loadString('lib/data/daily_grid.json');
    _gridData = jsonDecode(jsonString);

    // Process the grid (49 characters) into tiles
    String gridString = _gridData['grid'] ?? '';
    _gridTiles =
        gridString.split('').map((letter) {
          return {'letter': letter, 'value': Scoring.getLetterValue(letter)};
        }).toList();

    // Process the wildcards (5 characters) into tiles
    String wildcardString = _gridData['wildcards'] ?? '';
    _wildcardTiles =
        wildcardString.split('').map((letter) {
          return {
            'letter': letter,
            'value': Scoring.getLetterValue(
              letter,
            ), // 0 for non-Scrabble letters
          };
        }).toList();

    // Debug output to verify
    print('Grid tiles: ${_gridTiles.length} (should be 49)');
    print('First 5 grid tiles: ${_gridTiles.take(5)}');
    print('Wildcard tiles: ${_wildcardTiles.length} (should be 5)');
    print('Wildcards: $_wildcardTiles');
    print('Word count: ${_gridData["wordCount"]}');
  }

  // Getters for the data
  static List<Map<String, dynamic>> get gridTiles => _gridTiles;
  static List<Map<String, dynamic>> get wildcardTiles => _wildcardTiles;
  static int get wordCount => _gridData['wordCount'] ?? 0;
  static String get date => _gridData['date'] ?? '';
}
