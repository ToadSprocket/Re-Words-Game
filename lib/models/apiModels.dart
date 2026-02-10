// File: /lib/models/apiModels.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
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
  final String? displayName;

  SecurityData({required this.userId, this.accessToken, this.refreshToken, this.expirationSeconds, this.displayName});
}

class GameData {
  final String gameId;
  final String gridLetters;
  final String wildcardLetters;
  final String dateStart;
  final String dateExpire;
  final int wordCount;
  final int estimatedHighScore;

  GameData({
    required this.gameId,
    required this.gridLetters,
    required this.wildcardLetters,
    required this.dateStart,
    required this.dateExpire,
    required this.wordCount,
    required this.estimatedHighScore,
  });

  factory GameData.fromJson(Map<String, dynamic> json) => GameData(
    gameId: json['gameId'] ?? '',
    gridLetters: json['grid'] ?? '',
    wildcardLetters: json['wildcards'] ?? '',
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
  final int? totalScoresToday;
  final bool? userHasSubmitted;
  final int? userRank;
  final List<HighScore> highScores;

  HighScoreData({
    this.gameId,
    this.date,
    required this.highScores,
    this.totalScoresToday,
    this.userHasSubmitted,
    this.userRank,
  });

  factory HighScoreData.fromJson(Map<String, dynamic> json) {
    return HighScoreData(
      gameId: json['gameId'] as String?,
      date: json['date'] as String?,
      highScores: (json['highScores'] as List?)?.map((score) => HighScore.fromJson(score)).toList() ?? [],
      totalScoresToday: json['totalScoresToday'] as int?,
      userHasSubmitted: json['userHasSubmitted'] as bool?,
      userRank: json['userRank'] as int?,
    );
  }
}

class HighScore {
  final int ranking;
  final int wordCount;
  final int timePlayedSeconds;
  final int score;
  final String displayName;
  final String userId;

  HighScore({
    required this.ranking,
    required this.wordCount,
    required this.timePlayedSeconds,
    required this.score,
    required this.displayName,
    required this.userId,
  });

  factory HighScore.fromJson(Map<String, dynamic> json) {
    return HighScore(
      ranking: json['ranking'] as int,
      wordCount: json['wordCount'] as int,
      timePlayedSeconds: json['timePlayedSeconds'] as int,
      score: json['score'] as int,
      displayName: json['displayName'] as String,
      userId: json['userId'],
    );
  }
}

class SubmitScoreRequest {
  String userId;
  String gameId;
  String platform;
  String locale;
  int timePlayedSeconds;
  int wordCount;
  int wildcardUses;
  int score;
  int completionRate;
  int longestWordLength;

  SubmitScoreRequest({
    required this.userId,
    required this.gameId,
    required this.platform,
    required this.locale,
    required this.timePlayedSeconds,
    required this.wordCount,
    required this.wildcardUses,
    required this.score,
    required this.completionRate,
    required this.longestWordLength,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "gameId": gameId,
      "platform": platform,
      "locale": locale,
      "timePlayedSeconds": timePlayedSeconds,
      "wordCount": wordCount,
      "wildcardUses": wildcardUses,
      "score": score,
      "completionRate": completionRate,
      "longestWordLength": longestWordLength,
    };
  }
}
