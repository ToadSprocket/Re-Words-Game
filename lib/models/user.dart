// File: /lib/models/user.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'apiModels.dart'; // For SecurityData

/// User subscription/account type
enum UserType {
  guest, // No account, limited features
  standard, // Free registered user
  pro, // Paid subscription
}

/// Represents the current user of the app.
///
/// This model wraps user identity and authentication data.
/// Currently uses our game API, will transition to Firebase later.
class User {
  // ─────────────────────────────────────────────────────────────────────────
  // IDENTITY
  // ─────────────────────────────────────────────────────────────────────────

  /// Unique user ID from the game server (required for high scores)
  final String? userId;

  /// User's display name for leaderboards
  String? displayName;

  /// Account type (guest, standard, pro)
  UserType userType;

  // ─────────────────────────────────────────────────────────────────────────
  // AUTHENTICATION (current API - will change with Firebase)
  // ─────────────────────────────────────────────────────────────────────────

  /// Access token for API calls
  String? accessToken;

  /// Refresh token for renewing access
  String? refreshToken;

  /// When the access token expires
  DateTime? tokenExpiration;

  /// Track the users total time playing the game (in seconds)
  int totalPlaytime;

  // ─────────────────────────────────────────────────────────────────────────
  // PREFERENCES (user-specific settings)
  // ─────────────────────────────────────────────────────────────────────────

  /// Has the user seen the welcome animation?
  bool hasSeenWelcome;

  // ─────────────────────────────────────────────────────────────────────────
  // CONSTRUCTOR
  // ─────────────────────────────────────────────────────────────────────────

  User({
    this.userId,
    this.displayName,
    this.userType = UserType.guest,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiration,
    this.hasSeenWelcome = false,
    this.totalPlaytime = 0,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CONVENIENCE GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Is user logged in (has valid userId)?
  bool get isLoggedIn => userId != null && userId!.isNotEmpty;

  /// Is user a guest (not registered)?
  bool get isGuest => userType == UserType.guest;

  /// Is user a paid subscriber?
  bool get isPro => userType == UserType.pro;

  /// Is access token expired?
  bool get isTokenExpired {
    if (tokenExpiration == null) return true;
    return DateTime.now().isAfter(tokenExpiration!);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FACTORY: Create from current SecurityData (bridge to existing API)
  // ─────────────────────────────────────────────────────────────────────────

  /// Create User from API SecurityData response
  factory User.fromSecurityData(SecurityData security) {
    DateTime? expiration;
    if (security.expirationSeconds != null) {
      expiration = DateTime.now().add(Duration(seconds: int.parse(security.expirationSeconds!)));
    }

    return User(
      userId: security.userId,
      displayName: security.displayName,
      userType: UserType.standard, // Registered users are standard
      accessToken: security.accessToken,
      refreshToken: security.refreshToken,
      tokenExpiration: expiration,
      totalPlaytime: 0,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SERIALIZATION (for SharedPreferences storage)
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'userType': userType.index,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenExpiration': tokenExpiration?.toIso8601String(),
      'hasSeenWelcome': hasSeenWelcome,
      'totalPlaytime': totalPlaytime,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      displayName: json['displayName'],
      userType: UserType.values[json['userType'] ?? 0],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenExpiration: json['tokenExpiration'] != null ? DateTime.parse(json['tokenExpiration']) : null,
      hasSeenWelcome: json['hasSeenWelcome'] ?? false,
      totalPlaytime: json['totalPlaytime'] ?? 0,
    );
  }
}
