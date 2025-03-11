// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
class ApiResponse {
  final String? message;
  final SecurityData? security;
  final GameData? gameData;
  final HighScoreData? highScoreData;
  final ApiException? error;

  ApiResponse({this.message, this.security, this.gameData, this.highScoreData, this.error});
}

class SecurityData {
  final String userId;
  final String? accessToken;
  final String? refreshToken;
  final String? expirationSeconds;

  SecurityData({required this.userId, this.accessToken, this.refreshToken, this.expirationSeconds});
}

class GameData {
  final String grid;
  final String wildcards;
  final String dateStart;
  final String dateExpire;
  final int wordCount;
  final int estimatedHighScore;

  GameData({
    required this.grid,
    required this.wildcards,
    required this.dateStart,
    required this.dateExpire,
    required this.wordCount,
    required this.estimatedHighScore,
  });

  factory GameData.fromJson(Map<String, dynamic> json) => GameData(
    grid: json['grid'] ?? '',
    wildcards: json['wildcards'] ?? '',
    dateStart: json['dateStart'] ?? '',
    dateExpire: json['dateExpire'] ?? '',
    wordCount: json['wordCount'] ?? 0,
    estimatedHighScore: json['estimatedHighScore'] ?? 0,
  );
}

class ApiException implements Exception {
  final int statusCode;
  final String detail;

  ApiException({required this.statusCode, required this.detail});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, detail: $detail)';
}

class HighScoreData {
  final String? gameId;
  final String? date;
  final List<HighScore> highScores;

  HighScoreData({this.gameId, this.date, required this.highScores});

  factory HighScoreData.fromJson(Map<String, dynamic> json) {
    return HighScoreData(
      gameId: json['gameId'] as String?,
      date: json['date'] as String?,
      highScores: (json['highScores'] as List?)?.map((score) => HighScore.fromJson(score)).toList() ?? [],
    );
  }
}

class HighScore {
  final String userId;
  final int wordCount;
  final int timePlayedSeconds;
  final int score;
  final String displayName;

  HighScore({
    required this.userId,
    required this.wordCount,
    required this.timePlayedSeconds,
    required this.score,
    required this.displayName,
  });

  factory HighScore.fromJson(Map<String, dynamic> json) {
    return HighScore(
      userId: json['userId'] as String,
      wordCount: json['wordCount'] as int,
      timePlayedSeconds: json['timePlayedSeconds'] as int,
      score: json['score'] as int,
      displayName: json['displayName'] as String,
    );
  }
}
