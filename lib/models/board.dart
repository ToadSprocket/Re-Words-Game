// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:reword_game/models/game_mode.dart';
import 'tile.dart';
import 'board_state.dart';

class Board {
  // Identification
  final String gameId;

  // Actual board values
  final String grid;
  final String wildcards;

  // Board configuration
  final List<Tile> gridTiles;
  final List<Tile> wildcardTiles;

  // Dates
  final DateTime dateStart;
  final DateTime dateExpire;
  final DateTime loadedDate;
  final DateTime savedDate;

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
  List<String> spelledWords;
  int score;
  double completionRatio;

  Board({
    required this.gameId,
    required this.grid,
    required this.wildcards,
    required this.gridTiles,
    required this.wildcardTiles,
    required this.dateStart,
    required this.dateExpire,
    required this.loadedDate,
    required this.savedDate,
    this.secondsPlayed = 0,
    required this.sessionStartTime,
    required this.pausedAtTime,
    required this.wordCount,
    required this.estimatedHighScore,
    required this.boardState,
    required this.gameMode,
    this.spelledWords = const [],
    this.score = 0,
    this.completionRatio = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'grid': grid,
      'wildcards': wildcards,
      'gridTiles': gridTiles.map((t) => t.toJson()).toList(),
      'wildcardTiles': wildcardTiles.map((t) => t.toJson()).toList(),
      'dateStart': dateStart.toIso8601String(),
      'dateExpire': dateExpire.toIso8601String(),
      'loadedDate': loadedDate.toIso8601String(),
      'savedDate': savedDate.toIso8601String(),
      'secondsPlayed': secondsPlayed,
      'sessionStartTime': sessionStartTime?.toIso8601String(),
      'pauseAtTime': pausedAtTime?.toIso8601String(),
      'wordCount': wordCount,
      'estimatedHighScore': estimatedHighScore,
      'boardState': boardState.index,
      'gameMode': gameMode.index,
      'spelledWords': spelledWords,
      'score': score,
      'completionRatio': completionRatio,
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      gameId: json['gameId'],
      grid: json['grid'],
      wildcards: json['wildcards'],
      gridTiles: (json['gridTiles'] as List).map((t) => Tile.fromJson(t)).toList(),
      wildcardTiles: (json['wildcardTiles'] as List).map((t) => Tile.fromJson(t)).toList(),
      dateStart: DateTime.parse(json['dateStart']),
      dateExpire: DateTime.parse(json['dateExpire']),
      loadedDate: DateTime.parse(json['loadedDate']),
      savedDate: DateTime.parse(json['savedDate']),
      secondsPlayed: json['secondsPlayed'] ?? 0,
      sessionStartTime: json['sessionStartTime'] != null ? DateTime.parse(json['sessionStartTime']) : null,
      pausedAtTime: json['pausedAtTime'] != null ? DateTime.parse(json['pausedAtTime']) : null,
      wordCount: json['wordCount'],
      estimatedHighScore: json['estimatedHighScore'],
      boardState: BoardState.values[json['boardState']],
      gameMode: GameMode.values[json['gameMode']],
      spelledWords: (json['spelledWords'] as List).cast<String>(),
      score: json['score'],
      completionRatio: json['completionRatio'],
    );
  }

  Board copyWith({
    String? gameId,
    String? grid,
    String? wildcards,
    List<Tile>? gridTiles,
    List<Tile>? wildcardTiles,
    DateTime? dateStart,
    DateTime? dateExpire,
    DateTime? loadedDate,
    DateTime? savedDate,
    int? secondsPlayed,
    DateTime? sessionStartTime,
    DateTime? pausedAtTime,
    int? wordCount,
    int? estimatedHighScore,
    BoardState? boardState,
    GameMode? gameMode,
    List<String>? spelledWords,
    int? score,
    double? completionRatio,
  }) {
    return Board(
      gameId: gameId ?? this.gameId,
      grid: grid ?? this.grid,
      wildcards: wildcards ?? this.wildcards,
      gridTiles: gridTiles ?? List.from(this.gridTiles),
      wildcardTiles: wildcardTiles ?? List.from(this.wildcardTiles),
      dateStart: dateStart ?? this.dateStart,
      dateExpire: dateExpire ?? this.dateExpire,
      loadedDate: loadedDate ?? this.loadedDate,
      savedDate: savedDate ?? DateTime.now().toUtc(), // Always update saved date
      secondsPlayed: secondsPlayed ?? 0,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      pausedAtTime: pausedAtTime ?? this.pausedAtTime,
      wordCount: wordCount ?? this.wordCount,
      estimatedHighScore: estimatedHighScore ?? this.estimatedHighScore,
      boardState: boardState ?? this.boardState,
      gameMode: gameMode ?? this.gameMode,
      spelledWords: spelledWords ?? List.from(this.spelledWords),
      score: score ?? this.score,
      completionRatio: completionRatio ?? this.completionRatio,
    );
  }

  Board startNewSession() {
    return copyWith(
      secondsPlayed: 0,
      sessionStartTime: DateTime.now().toUtc(),
      pausedAtTime: null,
      savedDate: DateTime.now().toUtc(),
    );
  }

  Board pauseSession() {
    return copyWith(pausedAtTime: DateTime.now().toUtc(), savedDate: DateTime.now().toUtc());
  }

  Board resumeSession() {
    if (pausedAtTime == null || sessionStartTime == null) {
      // If not paused or no session, just start a new session
      return startNewSession();
    }

    // Calculate pause duration
    final now = DateTime.now().toUtc();
    final pauseDuration = now.difference(pausedAtTime!);

    // Adjust session start time by adding the pause duration
    final adjustedSessionStart = sessionStartTime!.add(pauseDuration);

    return copyWith(sessionStartTime: adjustedSessionStart, pausedAtTime: null, savedDate: now);
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
    return copyWith(secondsPlayed: updatedTime, sessionStartTime: now, savedDate: now);
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
}
