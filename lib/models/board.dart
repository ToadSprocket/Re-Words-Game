// File: /lib/models/board.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'dart:convert';
import 'package:reword_game/logic/logging_handler.dart';
import 'package:reword_game/models/gameMode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tile.dart';
import 'apiModels.dart';
import 'boardState.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzd;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../config/config.dart';

/// Represents the game board state for the Re-Word puzzle game.
///
/// This class serves as the single source of truth for all board-related data,
/// including puzzle configuration, player progress, tile states, and timing.
///
/// The Board can be:
/// - Created fresh from API data via [fromApiData]
/// - Loaded from local storage via [loadBoardFromStorage]
/// - Saved to local storage via [saveBoardToStorage]
///
/// Key responsibilities:
/// - Store puzzle letters and tile configurations
/// - Track player's spelled words and score
/// - Manage session timing and play time statistics
/// - Handle expiration logic for daily puzzles
/// - Persist and restore game state
class Board {
  /// Point values for each letter, following Scrabble-style scoring.
  /// Vowels and common consonants = 1, rare letters like Q and Z = 10.
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

  // ─────────────────────────────────────────────────────────────────────────
  // IDENTIFICATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Unique identifier for this puzzle from the API.
  final String gameId;

  // ─────────────────────────────────────────────────────────────────────────
  // PUZZLE CONFIGURATION (from API)
  // ─────────────────────────────────────────────────────────────────────────

  /// The 49 letters that make up the 7x7 grid, as a string (e.g., "ABCDE...").
  final String gridLetters;

  /// The wildcard letters available for this puzzle.
  final String wildcardLetters;

  // ─────────────────────────────────────────────────────────────────────────
  // TILE STATE
  // ─────────────────────────────────────────────────────────────────────────

  /// The 49 grid tiles with their current state (unused, used, selected, etc.).
  final List<Tile> gridTiles;

  /// The wildcard tiles with their current state.
  final List<Tile> wildcardTiles;

  // ─────────────────────────────────────────────────────────────────────────
  // DATE/TIME TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// When this puzzle was created on the server (UTC).
  final DateTime puzzleDate;

  /// When this puzzle expires (midnight in user's timezone, stored as UTC).
  final DateTime puzzleExpires;

  /// When the user loaded this puzzle locally (for "current" check).
  final DateTime loadedAt;

  // ─────────────────────────────────────────────────────────────────────────
  // TIME STATISTICS
  // ─────────────────────────────────────────────────────────────────────────

  /// Total seconds played across all sessions (persisted).
  final int secondsPlayed;

  /// When the current play session started (UTC). Used to calculate elapsed time.
  final DateTime? sessionStartedAt;

  /// When the app was paused (UTC). Used to exclude pause time from play time.
  final DateTime? pausedAt;

  // ─────────────────────────────────────────────────────────────────────────
  // GAME STATISTICS
  // ─────────────────────────────────────────────────────────────────────────

  /// Total number of valid words in this puzzle (from API).
  final int wordCount;

  /// Estimated maximum possible score (from API).
  final int estimatedHighScore;

  /// Number of wildcard tiles used by the player.
  int wildcardUses;

  // ─────────────────────────────────────────────────────────────────────────
  // CURRENT GAME STATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Current state of the board (newBoard, inProgress, finished).
  BoardState boardState;

  /// Current game mode (normal, practice, etc.).
  GameMode gameMode;

  /// When the current board activity session started.
  DateTime sessionStartDateTime;

  /// Elapsed time in minutes for the current session.
  int boardElapsedTime;

  /// List of words the player has successfully spelled.
  List<String> spelledWords;

  /// Player's current score.
  int score;

  /// Ratio of words found vs total words (spelledWords.length / wordCount).
  double completionRatio;

  /// Current device orientation (portrait/landscape).
  Orientation orientation;

  /// Grid indices of currently selected tiles (in selection order).
  /// Used to build the current word and highlight selected tiles.
  List<int> selectedWordIndex;

  Board({
    required this.gameId,
    required this.gridLetters,
    required this.wildcardLetters,
    required this.gridTiles,
    required this.wildcardTiles,
    required this.puzzleDate,
    required this.puzzleExpires,
    required this.loadedAt,
    this.secondsPlayed = 0,
    required this.sessionStartedAt,
    required this.pausedAt,
    required this.wordCount,
    required this.estimatedHighScore,
    this.wildcardUses = 0,
    required this.boardState,
    required this.gameMode,
    required this.sessionStartDateTime,
    required this.boardElapsedTime,
    this.spelledWords = const [],
    this.score = 0,
    this.completionRatio = 0,
    this.orientation = Orientation.unknown,
    this.selectedWordIndex = const [],
  });

  /// Serializes the board state to a JSON-compatible Map.
  /// Used by [saveBoardToStorage] to persist the board.
  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'gridLetters': gridLetters,
      'wildcardLetters': wildcardLetters,
      'gridTiles': gridTiles.map((t) => t.toJson()).toList(),
      'wildcardTiles': wildcardTiles.map((t) => t.toJson()).toList(),
      'puzzleDate': puzzleDate.toIso8601String(),
      'puzzleExpires': puzzleExpires.toIso8601String(),
      'loadedAt': loadedAt.toIso8601String(),
      'secondsPlayed': secondsPlayed,
      'sessionStartedAt': sessionStartedAt?.toIso8601String(),
      'pausedAt': pausedAt?.toIso8601String(),
      'wordCount': wordCount,
      'estimatedHighScore': estimatedHighScore,
      'wildcardUses': wildcardUses,
      'boardState': boardState.index,
      'gameMode': gameMode.index,
      'sessionStartDateTime': sessionStartDateTime.toIso8601String(),
      'boardElapsedTime': boardElapsedTime,
      'spelledWords': spelledWords,
      'score': score,
      'completionRatio': completionRatio,
      'orientation': orientation.name,
      'selectedWordIndex': selectedWordIndex,
    };
  }

  /// Creates a Board instance from a JSON Map.
  /// Used by [loadBoardFromStorage] to restore board state.
  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      gameId: json['gameId'],
      gridLetters: json['gridLetters'],
      wildcardLetters: json['wildcardLetters'],
      gridTiles: (json['gridTiles'] as List).map((t) => Tile.fromJson(t)).toList(),
      wildcardTiles: (json['wildcardTiles'] as List).map((t) => Tile.fromJson(t)).toList(),
      puzzleDate: DateTime.parse(json['puzzleDate']),
      puzzleExpires: DateTime.parse(json['puzzleExpires']),
      loadedAt: DateTime.parse(json['loadedAt']),
      secondsPlayed: json['secondsPlayed'] ?? 0,
      sessionStartedAt: json['sessionStartedAt'] != null ? DateTime.parse(json['sessionStartedAt']) : null,
      pausedAt: json['pausedAt'] != null ? DateTime.parse(json['pausedAt']) : null,
      wordCount: json['wordCount'],
      estimatedHighScore: json['estimatedHighScore'],
      wildcardUses: json['wildcardUses'],
      boardState: BoardState.values[json['boardState']],
      gameMode: GameMode.values[json['gameMode']],
      sessionStartDateTime: DateTime.parse(json['sessionStartDateTime']),
      boardElapsedTime: json['boardElapsedTime'] ?? 0,
      spelledWords: (json['spelledWords'] as List).cast<String>(),
      score: json['score'],
      completionRatio: json['completionRatio'],
      orientation: Orientation.values.firstWhere(
        (e) => e.name == json['orientation'],
        orElse: () => Orientation.unknown, // Default if not found
      ),
      selectedWordIndex: (json['selectedWordIndex'] as List).cast<int>(),
    );
  }

  /// Creates a copy of this Board with the specified fields replaced.
  /// Unspecified fields retain their current values.
  /// This is the preferred way to update Board state (immutable pattern).
  Board copyWith({
    String? gameId,
    String? gameHashCode,
    String? gridLetters,
    String? wildcardLetters,
    List<Tile>? gridTiles,
    List<Tile>? wildcardTiles,
    DateTime? puzzleDate,
    DateTime? puzzleExpires,
    DateTime? loadedAt,
    int? secondsPlayed,
    DateTime? sessionStartedAt,
    DateTime? pausedAt,
    int? wordCount,
    int? estimatedHighScore,
    int? wildcardUses,
    BoardState? boardState,
    GameMode? gameMode,
    DateTime? sessionStartDateTime,
    int? boardElapsedTime,
    List<String>? spelledWords,
    int? score,
    double? completionRatio,
    Orientation? orientation,
    List<int>? selectedWordIndex,
  }) {
    return Board(
      gameId: gameId ?? this.gameId,
      gridLetters: gridLetters ?? this.gridLetters,
      wildcardLetters: wildcardLetters ?? this.wildcardLetters,
      gridTiles: gridTiles ?? List.from(this.gridTiles),
      wildcardTiles: wildcardTiles ?? List.from(this.wildcardTiles),
      puzzleDate: puzzleDate ?? this.puzzleDate,
      puzzleExpires: puzzleExpires ?? this.puzzleExpires,
      loadedAt: loadedAt ?? this.loadedAt,
      secondsPlayed: secondsPlayed ?? this.secondsPlayed,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      wordCount: wordCount ?? this.wordCount,
      estimatedHighScore: estimatedHighScore ?? this.estimatedHighScore,
      wildcardUses: wildcardUses ?? this.wildcardUses,
      boardState: boardState ?? this.boardState,
      gameMode: gameMode ?? this.gameMode,
      sessionStartDateTime: sessionStartDateTime ?? this.sessionStartDateTime,
      boardElapsedTime: boardElapsedTime ?? this.boardElapsedTime,
      spelledWords: spelledWords ?? List.from(this.spelledWords),
      score: score ?? this.score,
      completionRatio: completionRatio ?? this.completionRatio,
      orientation: orientation ?? this.orientation,
      selectedWordIndex: selectedWordIndex ?? this.selectedWordIndex,
    );
  }

  /// Resets board state for starting a new game session.
  /// Clears tiles, spelled words, score, and resets timing.
  /// Does NOT clear puzzle configuration (gameId, gridLetters, etc.).
  Board startNewBoard() {
    return copyWith(
      secondsPlayed: 0,
      sessionStartDateTime: null,
      boardElapsedTime: 0,
      sessionStartedAt: DateTime.now().toUtc(),
      pausedAt: null,
      boardState: BoardState.newBoard,
      gridTiles: <Tile>[],
      wildcardTiles: <Tile>[],
      spelledWords: <String>[],
      wildcardUses: 0,
      selectedWordIndex: <int>[],
    );
  }

  /// Completely resets the board to an empty state.
  /// Clears ALL data including puzzle configuration.
  /// Use this when loading a completely new puzzle from the API.
  Board resetBoard() {
    return copyWith(
      secondsPlayed: 0,
      sessionStartDateTime: null,
      boardElapsedTime: 0,
      sessionStartedAt: DateTime.now().toUtc(),
      pausedAt: null,
      boardState: BoardState.newBoard,
      gridTiles: <Tile>[],
      wildcardTiles: <Tile>[],
      spelledWords: <String>[],
      gridLetters: "",
      wildcardLetters: "",
      gameId: "",
      wordCount: 0,
      wildcardUses: 0,
      score: 0,
    );
  }

  /// Validates that the board has all required data to be playable.
  /// Checks: gameId exists, letters exist, grid has 49 tiles, wildcards exist.
  bool isBoardValid() {
    return gameId.isNotEmpty &&
        gridLetters.isNotEmpty &&
        wildcardLetters.isNotEmpty &&
        gridTiles.length == 49 &&
        wildcardTiles.isNotEmpty;
  }

  /// Check if there is valid board data in storage
  /// Returns true only if data exists AND can be parsed successfully
  static Future<bool> hasBoardData() async {
    final prefs = await SharedPreferences.getInstance();
    final boardStateJson = prefs.getString(Config.boardStateKeyName);

    if (boardStateJson == null || boardStateJson.isEmpty) {
      return false;
    }

    try {
      // Attempt to parse to verify it's valid
      final boardJson = jsonDecode(boardStateJson);
      // Check required fields exist
      return boardJson['gameId'] != null &&
          boardJson['gridLetters'] != null &&
          boardJson['wildcardLetters'] != null &&
          boardJson['puzzleDate'] != null;
    } catch (e) {
      LogService.logError("Invalid board data in storage: $e");
      return false;
    }
  }

  /// Creates a new Board populated with data from the API response.
  /// Sets up tiles, dates, and resets all gameplay state.
  /// [gameData] - The puzzle data from the API.
  /// [currentOrientation] - Current device orientation for layout.
  Future<Board> fromApiData(GameData gameData, Orientation currentOrientation) async {
    return copyWith(
      secondsPlayed: 0,
      sessionStartDateTime: null,
      boardElapsedTime: 0,
      sessionStartedAt: DateTime.now().toUtc(),
      pausedAt: null,
      boardState: BoardState.newBoard,
      gameId: gameData.gameId,
      gridLetters: gameData.gridLetters,
      wildcardLetters: gameData.wildcardLetters,
      wordCount: gameData.wordCount,
      puzzleDate: DateTime.parse(gameData.dateStart),
      puzzleExpires: DateTime.parse(gameData.dateExpire),
      loadedAt: tzd.TZDateTime.now(await _getCurrentTimezoneLocation()),
      gridTiles: _createGameBoardTiles(gameData.gridLetters, false),
      wildcardTiles: _createGameBoardTiles(gameData.wildcardLetters, true),
      spelledWords: <String>[],
      score: 0,
      completionRatio: 0.0,
      orientation: currentOrientation,
    );
  }

  /// Persists the current board state to SharedPreferences.
  /// Serializes the entire board to JSON and saves it.
  /// Returns true if save was successful, false if an error occurred.
  Future<bool> saveBoardToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boardStateJson = jsonEncode(this.toJson());
      await prefs.setString(Config.boardStateKeyName, boardStateJson);
      LogService.logInfo("Board State Saved: ID: $gameId");
      LogService.logEvent("SBSTS:Success:$gameId");
      return true;
    } catch (e) {
      LogService.logError("Error saving board state: $e");
      LogService.logEvent("SBSTS:Failure");
      return false;
    }
  }

  /// Loads a previously saved board state from SharedPreferences.
  /// Returns null if no saved data exists or if parsing fails.
  static Future<Board?> loadBoardFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boardStateJson = prefs.getString(Config.boardStateKeyName);
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

  /// Marks the board as in-progress and starts the activity timer.
  /// Call when user begins actively playing.
  Board startBoardActivity() {
    return copyWith(boardState: BoardState.inProgress, sessionStartDateTime: DateTime.now(), boardElapsedTime: 0);
  }

  /// Marks the board as finished (game complete).
  Board endBoardActivity() {
    return copyWith(boardState: BoardState.finished);
  }

  /// Records the current time as pause time.
  /// Call when app goes to background or user pauses.
  Board pauseSession() {
    return copyWith(pausedAt: DateTime.now().toUtc());
  }

  /// Resumes from a paused state, adjusting session start time to exclude pause duration.
  /// If not paused, starts a new board instead.
  Board resumeSession() {
    if (pausedAt == null || sessionStartedAt == null) {
      // If not paused or no session, just start a new session
      return startNewBoard();
    }

    // Calculate pause duration
    final now = DateTime.now().toUtc();
    final pauseDuration = now.difference(pausedAt!);

    // Adjust session start time by adding the pause duration
    final adjustedSessionStart = sessionStartedAt!.add(pauseDuration);

    return copyWith(sessionStartedAt: adjustedSessionStart, pausedAt: null);
  }

  /// Updates total play time by adding elapsed time since session start.
  /// Resets session start to now for next calculation.
  Board updateBoardPlayTime() {
    if (sessionStartedAt == null) {
      return this;
    }
    // Calculate elapsed time since session start
    final now = DateTime.now().toUtc();
    final elapsed = now.difference(sessionStartedAt!).inSeconds;

    // Add to total time
    final updatedTime = secondsPlayed + elapsed;

    // Start a new session to reset the clock
    return copyWith(secondsPlayed: updatedTime, sessionStartedAt: now);
  }

  /// Gets total play time including current session.
  /// Returns stored time + current session elapsed time.
  int getTotalBoardPlayTime() {
    if (sessionStartedAt == null) {
      return secondsPlayed;
    }

    // Calculate current session time
    final now = DateTime.now().toUtc();
    final currentSessionTime = now.difference(sessionStartedAt!).inSeconds;

    // Add to stored time
    return secondsPlayed + currentSessionTime;
  }

  /// Updates and returns elapsed time in minutes for current session.
  /// Calculates difference between now and sessionStartDateTime.
  int updateBoardElapsedTimeInMinutes() {
    final now = DateTime.now();
    final elapsedDuration = now.difference(sessionStartDateTime);
    boardElapsedTime = elapsedDuration.inMinutes;
    return boardElapsedTime;
  }

  /// Gets the user's timezone location for date/time calculations.
  /// Uses FlutterTimezone to detect the device's local timezone.
  Future<tzd.Location> _getCurrentTimezoneLocation() async {
    String localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.initializeTimeZones();
    final location = tzd.getLocation(localTimeZone);
    return location;
  }

  /// Checks if the board was loaded today (in user's local timezone).
  /// Returns true if loadedAt is the same calendar day as now.
  Future<bool> isBoardCurrent() async {
    final tzd.Location location = await _getCurrentTimezoneLocation();
    final localLoadDateTime = tzd.TZDateTime.from(loadedAt, location);
    final currentDateTime = tzd.TZDateTime.now(location);

    final isSameDay =
        localLoadDateTime.year == currentDateTime.year &&
        localLoadDateTime.month == currentDateTime.month &&
        localLoadDateTime.day == currentDateTime.day;

    LogService.logInfo("Board Current State: $isSameDay");
    LogService.logEvent("IBC:Current:$isSameDay");

    return isSameDay;
  }

  /// Checks if the board has passed its expiration datetime.
  /// The API's dateExpire is in UTC/GMT — the server operates on GMT and
  /// will not serve a new board until after midnight GMT. We must compare
  /// current UTC time against the UTC expiration to stay aligned with the server.
  Future<bool> isBoardExpired() async {
    // Convert both times to UTC to align with the server's GMT-based schedule
    final nowUtc = DateTime.now().toUtc();
    final expirationUtc = puzzleExpires.toUtc();

    // Expired when current UTC time reaches or passes the UTC expiration
    final isExpired = nowUtc.isAfter(expirationUtc) || nowUtc.isAtSameMomentAs(expirationUtc);

    final reason =
        isExpired
            ? 'Current UTC ($nowUtc) is past expiration UTC ($expirationUtc)'
            : 'Board still valid until $expirationUtc (now UTC: $nowUtc)';

    LogService.logInfo("Board Expired: $isExpired - $reason");
    LogService.logEvent("IBC:Expired:$isExpired");
    return isExpired;
  }

  /// Returns how many minutes have passed since the board expired (since midnight).
  /// Returns 0 if the board is not expired.
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

  /// Gets the point value of a letter tile.
  /// Wildcard tiles get a minimum value of 2 (even for common letters).
  int _getLetterValue(String letter, bool isWildCard) {
    final value = _letterValues[letter.toLowerCase()] ?? 0;
    if (isWildCard) {
      return value == 1 ? 2 : value;
    } else {
      return value;
    }
  }

  /// Creates Tile objects from a string of letters (for grid or wildcards).
  /// Each letter becomes a Tile with its point value calculated.
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

  /// Calculates and returns the completion ratio (words found / total words).
  /// Returns 0.0 if wordCount is 0 to avoid division by zero.
  double getCompletionRatio() {
    if (wordCount == 0) {
      return 0.0; // Avoid division by zero
    }
    completionRatio = spelledWords.length / wordCount;
    return completionRatio;
  }

  /// Updates the current device orientation.
  void setOrientation(Orientation newOrientation) {
    orientation = newOrientation;
  }

  /// Builds the current word being spelled from selected tile indices.
  /// Returns uppercase string of letters at each selected grid position.
  String getCurrentWord() {
    if (selectedWordIndex.isEmpty || gridTiles.isEmpty) {
      return '';
    }

    return selectedWordIndex
        .where((index) => index >= 0 && index < gridTiles.length) // Safety check
        .map((index) => gridTiles[index].letter)
        .join()
        .toUpperCase();
  }

  /// Debug: Clear stored board data for fresh start
  static Future<void> clearBoardFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Config.boardStateKeyName);
    LogService.logInfo("🧹 Debug: Cleared stored board data");
  }
}
