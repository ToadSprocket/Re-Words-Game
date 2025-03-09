class ApiResponse {
  final SecurityData? security;
  final GameData? gameData;

  ApiResponse({this.security, this.gameData});
}

class SecurityData {
  final String userId;
  final String? accessToken;
  final String? refreshToken;

  SecurityData({required this.userId, this.accessToken, this.refreshToken});
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
