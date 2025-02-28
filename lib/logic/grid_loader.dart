// lib/logic/grid_loader.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import '../models/tile.dart';
import 'security.dart';
import 'user_storage.dart';
import '../config/config.dart';
import 'spelled_words_handler.dart'; // Add for SpelledWordsLogic

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

  static Future<bool> loadGrid({bool forceRefresh = false, Map<String, dynamic>? previousStats}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedGrid');
    final cachedExpire = prefs.getString('cachedExpireDate');

    if (!forceRefresh && cachedData != null && cachedExpire != null) {
      final expireDate = DateTime.parse(cachedExpire);
      if (DateTime.now().toUtc().isBefore(expireDate)) {
        _gridData = jsonDecode(cachedData);
        gridTiles =
            (jsonDecode(prefs.getString('cachedGridTiles') ?? '[]') as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
        wildcardTiles =
            (jsonDecode(prefs.getString('cachedWildcardTiles') ?? '[]') as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
        print('Loaded cached grid: ${_gridData['dateStart']}');
        return true;
      }
    }

    const maxRetries = 3;
    const retryDelay = Duration(seconds: 3);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final userId = await UserIdStorage.getUserId();
        final uri = Uri.parse(Config.apiUrl);
        final headers = {
          'accept': 'application/json',
          'x-api-key': Security.generateApiKeyHash(),
          'Content-Type': 'application/json',
        };

        final stats = {
          'wordCount': SpelledWordsLogic.spelledWords.length,
          'timePlayedSeconds': prefs.getInt('timePlayedSeconds') ?? 0,
          'wildcardUses': prefs.getInt('wildcardUses') ?? 0,
          'score': SpelledWordsLogic.score,
          'completionRate': (SpelledWordsLogic.spelledWords.length / (_gridData['wordCount'] ?? 85)) * 100,
          'longestWordLength':
              SpelledWordsLogic.spelledWords.isEmpty
                  ? 0
                  : SpelledWordsLogic.spelledWords.map((w) => w.length).reduce((a, b) => a > b ? a : b),
        };

        final body = jsonEncode({
          'userId': userId ?? '',
          'platform': kIsWeb ? 'Web' : 'Windows',
          'locale': Platform.localeName,
          'timePlayedSeconds': stats['timePlayedSeconds'],
          'wordCount': stats['wordCount'],
          'wildcardUses': stats['wildcardUses'],
          'score': stats['score'],
          'completionRate': stats['completionRate'],
          'longestWordLength': stats['longestWordLength'],
        });

        print('Sending API request (attempt $attempt/$maxRetries): $uri');
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
                final value = baseValue == 1 ? 2 : baseValue;
                return {'letter': letter, 'value': value};
              }).toList();

          await prefs.setString('cachedGrid', jsonEncode(_gridData));
          await prefs.setString('cachedGridTiles', jsonEncode(gridTiles));
          await prefs.setString('cachedWildcardTiles', jsonEncode(wildcardTiles));
          await prefs.setString('cachedExpireDate', _gridData['dateExpire'] ?? '');

          // Reset stats if forceRefresh (new board)
          if (forceRefresh) {
            await prefs.remove('spelledWords');
            await prefs.remove('score');
            await prefs.remove('timePlayedSeconds');
            await prefs.remove('wildcardUses');
            SpelledWordsLogic.spelledWords = [];
            SpelledWordsLogic.score = 0;
            await prefs.setString('boardLoadedDate', DateTime.now().toUtc().toIso8601String());
            print('Reset stats for new board');
          }

          print('Loaded and cached grid: ${_gridData['dateStart']}');
          return true;
        } else {
          print('API failed with status: ${response.statusCode}');
          if (attempt == maxRetries) return false;
        }
      } catch (e) {
        print('Grid load error (attempt $attempt/$maxRetries): $e');
        if (attempt == maxRetries) return false;
      }
      if (attempt < maxRetries) {
        print('Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      }
    }
    return false;
  }

  static int get wordCount => _gridData['wordCount'] ?? 0;
  static String get date => _gridData['dateStart'] ?? '';
  static String get dateExpire => _gridData['dateExpire'] ?? '';
  static int get estimatedHighScore => _gridData['estimatedHighScore'] ?? 0;
}
