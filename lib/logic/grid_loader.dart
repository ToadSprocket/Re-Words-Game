import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb; // Add this
import '../models/tile.dart';
import 'security.dart';
import 'user_storage.dart';
import '../config/config.dart';

class GridLoader {
  static List<Map<String, dynamic>> gridTiles = [];
  static List<Map<String, dynamic>> wildcardTiles = [];
  static Map<String, dynamic> _gridData = {};

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
    final userId = await UserIdStorage.getUserId();
    final uri = Uri.parse(Config.apiUrl);
    final headers = {
      'accept': 'application/json',
      'x-api-key': Security.generateApiKeyHash(),
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'userId': userId ?? '',
      'platform': kIsWeb ? 'Web' : 'Windows',
      'sessionStart': DateTime.now().toUtc().toIso8601String(),
      'sessionEnd': DateTime.now().toUtc().toIso8601String(),
    });

    print('Sending API request: $uri');
    print('Headers: $headers');
    print('Body: $body');

    final response = await http.post(uri, headers: headers, body: body);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      _gridData = jsonDecode(response.body);
      final newUserId = _gridData['userId'];
      if (newUserId != null && newUserId != userId) {
        await UserIdStorage.setUserId(newUserId);
        print('Updated userId: $newUserId');
      }
      String gridString = _gridData['grid'] ?? '';
      gridTiles =
          gridString.split('').map((letter) {
            return {'letter': letter, 'value': _letterValues[letter.toLowerCase()] ?? 0};
          }).toList();

      String wildcardString = _gridData['wildcards'] ?? '';
      wildcardTiles =
          wildcardString.split('').map((letter) {
            final baseValue = _letterValues[letter.toLowerCase()] ?? 0;
            final value = baseValue == 1 ? 2 : baseValue; // If 1, make it 2
            return {'letter': letter, 'value': value};
          }).toList();

      print('Loaded grid: ${_gridData['dateStart']}');
    } else {
      throw Exception('Failed to fetch game board');
    }
  }

  static int get wordCount => _gridData['wordCount'] ?? 0;
  static String get date => _gridData['dateStart'] ?? '';
  static String get dateExpire => _gridData['dateExpire'] ?? '';
  static int get estimatedHighScore => _gridData['estimatedHighScore'] ?? 0;
}
