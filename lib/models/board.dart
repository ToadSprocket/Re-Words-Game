// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:convert';

import 'package:reword_game/logic/logging_handler.dart';
import 'package:reword_game/models/game_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tile.dart';
import 'api_models.dart';
import 'board_state.dart';
import 'tile.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzd;
import 'package:flutter_timezone/flutter_timezone.dart';

class Board {
  static const String _boardStateName = "boardState";
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

  // Identification
  final String gameId;

  // Actual board values
  final String grid;
  final String wildcards;

  // Board configuration
  final List<Tile> gridTiles;
  final List<Tile> wildcardTiles;

  // Dates
  final DateTime boardDateTimeStart;
  final DateTime boardDateTimeExpire;
  final DateTime boardDateTimeLoaded;

  // Time statistics
  final int secondsPlayed;
  final DateTime? sessionStartTime;
  final DateTime? pausedAtTime;

  // Game statistics
  final int wordCount;
  final int estimatedHighScore;

  // Current state
  BoardState boardState;
  GameMode gameMode;
  DateTime boardStartDateTime;
  int boardElapsedTime;
  List<String> spelledWords;
  int score;
  double completionRatio;
  Orientation orientation;

  Board({
    required this.gameId,
    required this.grid,
    required this.wildcards,
    required this.gridTiles,
    required this.wildcardTiles,
    required this.boardDateTimeStart,
    required this.boardDateTimeExpire,
    required this.boardDateTimeLoaded,
    this.secondsPlayed = 0,
    required this.sessionStartTime,
    required this.pausedAtTime,
    required this.wordCount,
    required this.estimatedHighScore,
    required this.boardState,
    required this.gameMode,
    required this.boardStartDateTime,
    required this.boardElapsedTime,
    this.spelledWords = const [],
    this.score = 0,
    this.completionRatio = 0,
    this.orientation = Orientation.unknown,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'grid': grid,
      'wildcards': wildcards,
      'gridTiles': gridTiles.map((t) => t.toJson()).toList(),
      'wildcardTiles': wildcardTiles.map((t) => t.toJson()).toList(),
      'boardDateTimeStart': boardDateTimeStart.toIso8601String(),
      'boardDateTimeExpire': boardDateTimeExpire.toIso8601String(),
      'boardDateTimeLoaded': boardDateTimeLoaded.toIso8601String(),
      'secondsPlayed': secondsPlayed,
      'sessionStartTime': sessionStartTime?.toIso8601String(),
      'pauseAtTime': pausedAtTime?.toIso8601String(),
      'wordCount': wordCount,
      'estimatedHighScore': estimatedHighScore,
      'boardState': boardState.index,
      'gameMode': gameMode.index,
      'boardStartDateTime': boardStartDateTime,
      'boardElapsedTime': boardElapsedTime,
      'spelledWords': spelledWords,
      'score': score,
      'completionRatio': completionRatio,
      'orientation': orientation.name,
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      gameId: json['gameId'],
      grid: json['grid'],
      wildcards: json['wildcards'],
      gridTiles: (json['gridTiles'] as List).map((t) => Tile.fromJson(t)).toList(),
      wildcardTiles: (json['wildcardTiles'] as List).map((t) => Tile.fromJson(t)).toList(),
      boardDateTimeStart: DateTime.parse(json['boardDateTimeStart']),
      boardDateTimeExpire: DateTime.parse(json['boardDateTimeExpire']),
      boardDateTimeLoaded: DateTime.parse(json['boardDateTimeLoaded']),
      secondsPlayed: json['secondsPlayed'] ?? 0,
      sessionStartTime: json['sessionStartTime'] != null ? DateTime.parse(json['sessionStartTime']) : null,
      pausedAtTime: json['pausedAtTime'] != null ? DateTime.parse(json['pausedAtTime']) : null,
      wordCount: json['wordCount'],
      estimatedHighScore: json['estimatedHighScore'],
      boardState: BoardState.values[json['boardState']],
      gameMode: GameMode.values[json['gameMode']],
      boardStartDateTime: DateTime.parse(json['boardStartDateTime']),
      boardElapsedTime: json['boardElapsedTime'] ?? 0,
      spelledWords: (json['spelledWords'] as List).cast<String>(),
      score: json['score'],
      completionRatio: json['completionRatio'],
      orientation: Orientation.values.firstWhere(
        (e) => e.name == json['orientation'],
        orElse: () => Orientation.unknown, // Default if not found
      ),
    );
  }

  Board copyWith({
    String? gameId,
    String? gameHashCode,
    String? grid,
    String? wildcards,
    List<Tile>? gridTiles,
    List<Tile>? wildcardTiles,
    DateTime? boardDateTimeStart,
    DateTime? boardDateTimeExpire,
    DateTime? boardDateTimeLoaded,
    int? secondsPlayed,
    DateTime? sessionStartTime,
    DateTime? pausedAtTime,
    int? wordCount,
    int? estimatedHighScore,
    BoardState? boardState,
    GameMode? gameMode,
    DateTime? boardStartDateTime,
    int? boardElapsedTime,
    List<String>? spelledWords,
    int? score,
    double? completionRatio,
    Orientation? orientation,
  }) {
    return Board(
      gameId: gameId ?? this.gameId,
      grid: grid ?? this.grid,
      wildcards: wildcards ?? this.wildcards,
      gridTiles: gridTiles ?? List.from(this.gridTiles),
      wildcardTiles: wildcardTiles ?? List.from(this.wildcardTiles),
      boardDateTimeStart: boardDateTimeStart ?? this.boardDateTimeStart,
      boardDateTimeExpire: boardDateTimeExpire ?? this.boardDateTimeExpire,
      boardDateTimeLoaded: boardDateTimeLoaded ?? this.boardDateTimeLoaded,
      secondsPlayed: secondsPlayed ?? 0,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      pausedAtTime: pausedAtTime ?? this.pausedAtTime,
      wordCount: wordCount ?? this.wordCount,
      estimatedHighScore: estimatedHighScore ?? this.estimatedHighScore,
      boardState: boardState ?? this.boardState,
      gameMode: gameMode ?? this.gameMode,
      boardStartDateTime: boardStartDateTime ?? this.boardStartDateTime,
      boardElapsedTime: boardElapsedTime ?? this.boardElapsedTime,
      spelledWords: spelledWords ?? List.from(this.spelledWords),
      score: score ?? this.score,
      completionRatio: completionRatio ?? this.completionRatio,
      orientation: orientation ?? this.orientation,
    );
  }

  Board startNewBoard() {
    return copyWith(
      secondsPlayed: 0,
      boardStartDateTime: null,
      boardElapsedTime: 0,
      sessionStartTime: DateTime.now().toUtc(),
      pausedAtTime: null,
      boardState: BoardState.newBoard,
      gridTiles: <Tile>[],
      wildcardTiles: <Tile>[],
      spelledWords: <String>[],
    );
  }

  Board resetBoard() {
    return copyWith(
      secondsPlayed: 0,
      boardStartDateTime: null,
      boardElapsedTime: 0,
      sessionStartTime: DateTime.now().toUtc(),
      pausedAtTime: null,
      boardState: BoardState.newBoard,
      gridTiles: <Tile>[],
      wildcardTiles: <Tile>[],
      spelledWords: <String>[],
      grid: "",
      wildcards: "",
      gameId: "",
      wordCount: 0,
      score: 0,
    );
  }

  bool isBoardValid() {
    return gameId.isNotEmpty &&
        grid.isNotEmpty &&
        wildcards.isNotEmpty &&
        gridTiles.length == 49 &&
        wildcardTiles.isNotEmpty;
  }

  // Creates a new game board from the Api.
  Future<Board> fromApiData(GameData gameData, Orientation currentOrientation) async {
    return copyWith(
      secondsPlayed: 0,
      boardStartDateTime: null,
      boardElapsedTime: 0,
      sessionStartTime: DateTime.now().toUtc(),
      pausedAtTime: null,
      boardState: BoardState.newBoard,
      gameId: gameData.gameId,
      grid: gameData.grid,
      wildcards: gameData.wildcards,
      wordCount: gameData.wordCount,
      boardDateTimeStart: DateTime.parse(gameData.dateStart),
      boardDateTimeExpire: DateTime.parse(gameData.dateExpire),
      boardDateTimeLoaded: tzd.TZDateTime.now(await _getCurrentTimezoneLocation()),
      gridTiles: _createGameBoardTiles(gameData.grid, false),
      wildcardTiles: _createGameBoardTiles(gameData.wildcards, true),
      spelledWords: <String>[],
      score: 0,
      completionRatio: 0.0,
      orientation: currentOrientation,
    );
  }

  // New method for saving the board in it's current state.
  Future<bool> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boardStateJson = jsonEncode(this.toJson());
      await prefs.setString(_boardStateName, boardStateJson);
      LogService.logInfo("Board State Saved: ID: $gameId");
      LogService.logEvent("SBSTS:Success:$gameId");
      return true;
    } catch (e) {
      LogService.logError("Error saving board state: $e");
      LogService.logEvent("SBSTS:Failure");
      return false;
    }
  }

  Future<Board?> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boardStateJson = prefs.getString(_boardStateName);
      if (boardStateJson == null) {
        LogService.logError("No board data found in storage");
        return null;
      }

      final boardJson = jsonDecode(boardStateJson);
      final board = Board.fromJson(boardJson);

      LogService.logInfo("Board Loaded From Storage: ID: ${board.gameId}");
      LogService.logEvent("SBSTS:Success:${board.gameId}");

      return board;
    } catch (e) {
      LogService.logError("Error loading board state: $e");
      LogService.logEvent("SBSTS:Failure");
      return null;
    }
  }

  Board startBoardActivity() {
    return copyWith(boardState: BoardState.inProgress, boardStartDateTime: DateTime.now(), boardElapsedTime: 0);
  }

  Board endBoardActivity() {
    return copyWith(boardState: BoardState.finished);
  }

  Board pauseSession() {
    return copyWith(pausedAtTime: DateTime.now().toUtc());
  }

  Board resumeSession() {
    if (pausedAtTime == null || sessionStartTime == null) {
      // If not paused or no session, just start a new session
      return startNewBoard();
    }

    // Calculate pause duration
    final now = DateTime.now().toUtc();
    final pauseDuration = now.difference(pausedAtTime!);

    // Adjust session start time by adding the pause duration
    final adjustedSessionStart = sessionStartTime!.add(pauseDuration);

    return copyWith(sessionStartTime: adjustedSessionStart, pausedAtTime: null);
  }

  Board updatePlayTime() {
    if (sessionStartTime == null) {
      return this;
    }
    // Calculate elapsed time since session start
    final now = DateTime.now().toUtc();
    final elapsed = now.difference(sessionStartTime!).inSeconds;

    // Add to total time
    final updatedTime = secondsPlayed + elapsed;

    // Start a new session to reset the clock
    return copyWith(secondsPlayed: updatedTime, sessionStartTime: now);
  }

  int getTotalPlayTime() {
    if (sessionStartTime == null) {
      return secondsPlayed;
    }

    // Calculate current session time
    final now = DateTime.now().toUtc();
    final currentSessionTime = now.difference(sessionStartTime!).inSeconds;

    // Add to stored time
    return secondsPlayed + currentSessionTime;
  }

  // Used to update the elapsed time
  int updateBoardElapsedTimeInMinutes() {
    final now = DateTime.now();
    final elapsedDuration = now.difference(boardStartDateTime);
    boardElapsedTime = elapsedDuration.inMinutes;
    return boardElapsedTime;
  }

  // Method to get the timezone of the user
  Future<tzd.Location> _getCurrentTimezoneLocation() async {
    String localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.initializeTimeZones();
    final location = tzd.getLocation(localTimeZone);
    return location;
  }

  // Validate if the board is in fact current
  Future<bool> isBoardCurrent() async {
    final tzd.Location location = await _getCurrentTimezoneLocation();
    final localLoadDateTime = tzd.TZDateTime.from(boardDateTimeLoaded, location);
    final currentDateTime = tzd.TZDateTime.now(location);

    final isSameDay =
        localLoadDateTime.year == currentDateTime.year &&
        localLoadDateTime.month == currentDateTime.month &&
        localLoadDateTime.day == currentDateTime.day;

    LogService.logInfo("Board Current State: $isSameDay");
    LogService.logEvent("IBC:Current:$isSameDay");

    return isSameDay;
  }

  // Check to see if the board has expired.
  Future<bool> isBoardExpired() async {
    final tzd.Location location = await _getCurrentTimezoneLocation();
    final localExpirationDateTime = tzd.TZDateTime.from(boardDateTimeExpire, location);
    final currentDateTime = tzd.TZDateTime.now(location);
    var isExpired = false;
    var reason = "";

    // First check if the year is older.
    if (currentDateTime.year > localExpirationDateTime.year) {
      reason = 'Year';
      isExpired = true;
    }

    // Then check the month
    if (currentDateTime.month > localExpirationDateTime.month) {
      reason = 'Month';
      isExpired = true;
    }

    // Finally check the day
    if (currentDateTime.day > localExpirationDateTime.day) {
      reason = 'Day';
      isExpired = true;
    }

    LogService.logInfo("Board Expired: $isExpired-$reason");
    LogService.logEvent("IBC:Expired:$isExpired");
    return isExpired;
  }

  // returns how long the board has lived past midnight
  Future<int> minutesBoardIsExpired() async {
    // First is the board even expired?
    if (!await isBoardExpired()) {
      return 0;
    }

    final tzd.Location location = await _getCurrentTimezoneLocation();
    final currentDateTime = tzd.TZDateTime.now(location);

    // Create current midnight to find difference
    tzd.TZDateTime currentMidnight = tzd.TZDateTime(
      location,
      currentDateTime.year,
      currentDateTime.month,
      currentDateTime.day,
    );

    // How long since midnight
    Duration difference = currentDateTime.difference(currentMidnight);
    LogService.logInfo("Board Expired Minutes: ${difference.inMinutes}");
    LogService.logEvent("MBIE:${difference.inMinutes}");

    return difference.inMinutes;
  }

  // Gets the value of a tile for both regular and wildcard
  int _getLetterValue(String letter, bool isWildCard) {
    final value = _letterValues[letter.toLowerCase()] ?? 0;
    if (isWildCard) {
      return value == 1 ? 2 : value;
    } else {
      return value;
    }
  }

  // Creates the list of tiles for a new board that's being loaded from the API.
  List<Tile> _createGameBoardTiles(String gridTiles, bool isWildCard) {
    return gridTiles.split('').map((letter) {
      return Tile(
        letter: letter,
        isExtra: false,
        isRemoved: false,
        isHybrid: false,
        state: 'unused',
        useCount: 0,
        multiplier: 1.0,
        value: _getLetterValue(letter, isWildCard),
      );
    }).toList();
  }

  // Gets the current completion ratio for the board.
  double getCompletionRatio() {
    if (wordCount == 0) {
      return 0.0; // Avoid division by zero
    }
    completionRatio = spelledWords.length / wordCount;
    return completionRatio;
  }

  void setOrientation(Orientation newOrientation) {
    orientation = newOrientation;
  }
}
