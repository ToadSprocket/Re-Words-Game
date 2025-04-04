import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/security.dart';
import '../config/config.dart';
import '../models/api_models.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../logic/logging_handler.dart';

class ApiService with ChangeNotifier {
  static final ApiService _instance = ApiService._internal(); // ✅ Singleton instance

  factory ApiService() => _instance; // ✅ Always return the same instance

  ApiService._internal();
  String? userId;
  String? accessToken;
  String? refreshToken;
  int? tokenExpiration;
  bool _loggedIn = false;

  bool get loggedIn => _loggedIn; // Getter

  set loggedIn(bool value) {
    if (_loggedIn != value) {
      _loggedIn = value;
      notifyListeners(); // 🔥 Notify UI when login state changes
    }
  }

  void setAuthToken(String token) {
    accessToken = token;
    loggedIn = true;
    notifyListeners();
  }

  /// **Log out user and clear tokens**
  void logout() async {
    loggedIn = false; // 🔥 Trigger UI update
  }

  /// **Check if the token is expiring soon**
  Future<bool> _isTokenExpiringSoon() async {
    if (tokenExpiration == null) {
      final prefs = await SharedPreferences.getInstance();
      tokenExpiration = prefs.getInt('accessTokenExpiration'); // Load as int
    }
    if (tokenExpiration == null) return false; // No expiration set

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    LogService.logDebug(
      "⏳ Checking token expiration - Expiration: $tokenExpiration, Now: $now, Time Left: ${tokenExpiration! - now} sec",
    );

    return tokenExpiration! - now < 30; // Refresh if expiring within 30 seconds
  }

  /// **Update tokens in memory & storage**
  Future<void> _updateTokens(SecurityData security) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', security.userId);
    await prefs.setString('accessToken', security.accessToken ?? "");
    await prefs.setString('refreshToken', security.refreshToken ?? "");
    await prefs.setString('refreshTokenDate', DateTime.now().toIso8601String());

    userId = security.userId;
    accessToken = security.accessToken;
    refreshToken = security.refreshToken;

    if (security.expirationSeconds != null) {
      final expirationInt = int.tryParse(security.expirationSeconds!) ?? 0;
      final expirationTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expirationInt;
      await prefs.setInt('accessTokenExpiration', expirationTimestamp);

      tokenExpiration = expirationTimestamp; // ✅ Now updates immediately
      LogService.logDebug('⏳ Tokens updated - Expires At: $expirationTimestamp');
    }
  }

  Future<void> _getTokens() async {
    if (userId != null) return; // Already loaded
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    accessToken = prefs.getString('accessToken');
    refreshToken = prefs.getString('refreshToken');
    tokenExpiration = prefs.getInt('accessTokenExpiration');
  }

  /// **Refresh token if needed**
  Future<bool> _refreshTokenIfNeeded() async {
    if (userId == null || refreshToken == null) {
      LogService.logError("🚨 No userId or refresh token available. Cannot refresh.");
      return false;
    }

    try {
      final headers = {
        'X-API-Key': Security.generateApiKeyHash(),
        'UserId': userId!,
        'Refresh-Token': refreshToken!,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      final response = await http.post(Uri.parse('${Config.apiUrl}/users/refresh'), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _updateTokens(
          SecurityData(
            userId: data['userId'],
            accessToken: data['access_token'],
            refreshToken: data['refresh_token'],
            expirationSeconds: data['expires_in'].toString(),
          ),
        );
        return true;
      } else if (response.statusCode == 401) {
        LogService.logError("🚨 Refresh token expired or invalid. Logging out user.");
        logout(); // Clear tokens and redirect to login
      }
    } catch (e) {
      print('🚨 Refresh failed: $e');
    }

    return false;
  }

  /// **Register a new user**
  Future<ApiResponse> register(String locale, String platform) async {
    final headers = {'X-API-Key': Security.generateApiKeyHash(), 'Content-Type': 'application/json'};
    final body = jsonEncode({'locale': locale, 'platform': platform});

    final response = await _makeApiRequest(false, '${Config.apiUrl}/users/register', headers, body);

    final apiResponse = _parseResponse(response);
    await _updateTokens(apiResponse.security!);
    return apiResponse;
  }

  /// **Update User Profile**
  Future<ApiResponse> updateProfile({
    required String userName,
    required String displayName,
    required String password,
    String? email,
  }) async {
    await _getTokens(); // Ensure tokens are loaded

    final headers = {
      'X-API-Key': Security.generateApiKeyHash(),
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "userId": userId,
      "userName": userName,
      "displayName": displayName,
      "password": password,
      if (email != null && email.isNotEmpty) "email": email, // Optional email
    });

    try {
      final response = await _makeApiRequest(
        false, // POST request
        '${Config.apiUrl}/users/updateprofile',
        headers,
        body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        {
          loggedIn = true;
        }

        // 🔹 Store new tokens
        await _updateTokens(
          SecurityData(
            userId: data["userId"],
            accessToken: data["access_token"],
            refreshToken: data["refresh_token"],
            expirationSeconds: data["expires_in"].toString(),
          ),
        );

        return ApiResponse(message: data["message"]);
      } else {
        // Handle API errors and return structured messages
        return ApiResponse(message: "An unknown error occurred");
      }
    } catch (e) {
      LogService.logError('🚨 Profile update failed: $e');
      return ApiResponse(message: "Server error. Please try again later.");
    }
  }

  /// **Login User & Refresh Tokens**
  Future<ApiResponse?> login(String username, String password) async {
    final headers = {'X-API-Key': Security.generateApiKeyHash(), 'Content-Type': 'application/json'};
    final body = jsonEncode({'userName': username, 'password': password});

    try {
      final response = await _makeApiRequest(false, '${Config.apiUrl}/users/login', headers, body);

      if (response.statusCode == 200) {
        final apiResponse = _parseResponse(response);

        // 🔄 Store new tokens on successful login
        if (apiResponse.security != null) {
          await _updateTokens(apiResponse.security!);
          loggedIn = true; // 🔥 Set loggedIn = true on successful login
          userId = apiResponse.security!.userId;
          accessToken = apiResponse.security!.accessToken;
          refreshToken = apiResponse.security!.refreshToken;
          return apiResponse;
        }
      }

      // Handle 401 (Unauthorized) - Login failed
      if (response.statusCode == 401) {
        LogService.logError("🚨 Login failed: Invalid credentials");
        return null; // Login failed, return null to UI
      }

      // Handle other errors (e.g., 500, 400)
      LogService.logError("🚨 Unexpected login failure: ${response.body}");
      return null;
    } catch (e) {
      LogService.logError("❌ Login Exception: $e");
      return null;
    }
  }

  /// **Fetch Today's Game**
  Future<ApiResponse> getGameToday(SubmitScoreRequest scoreRequest) async {
    await _getTokens(); // Ensure tokens are loaded

    // ✅ Get the player's timezone
    String localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.initializeTimeZones();
    final location = tz.getLocation(localTimeZone); // e.g., "America/Los_Angeles"

    final headers = {
      'X-API-Key': Security.generateApiKeyHash(),
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      'Time-Zone': location.toString(), // ✅ Send player's timezone to API
    };

    scoreRequest.userId = userId!; // Set userId in request

    final body = jsonEncode(scoreRequest.toJson());

    final response = await _makeApiRequest(false, '${Config.apiUrl}/game/today', headers, body);

    return _parseResponse(response);
  }

  /// **Get Today's High Scores**
  Future<ApiResponse> getTodayHighScores({int limit = 10}) async {
    await _getTokens(); // Ensure tokens are loaded

    final headers = {
      'X-API-Key': Security.generateApiKeyHash(),
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({"userId": userId}); // Send userId in body

    // ✅ Add `limit` as a query parameter
    final response = await _makeApiRequest(false, '${Config.apiUrl}/scores/today?limit=$limit', headers, body);

    return _parseResponse(response);
  }

  /// **Submit High Score**
  Future<bool> requestPasswordReset(String email) async {
    final headers = {'X-API-Key': Security.generateApiKeyHash()};
    final url = Uri.parse('${Config.apiUrl}/recovery/auth/request-reset?email=$email');

    try {
      final response = await http.post(url, headers: headers);
      if (response.statusCode == 204) {
        return true;
      }
    } catch (e) {
      LogService.logError("🚨 Failed to request password reset: $e");
    }
    return false;
  }

  /// **Reset Password**
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    final headers = {'X-API-Key': Security.generateApiKeyHash(), 'Content-Type': 'application/json'};

    final url = Uri.parse(
      '${Config.apiUrl}/recovery/auth/reset-password?email=$email&code=$code&new_password=$newPassword',
    );

    try {
      final response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      LogService.logError("🚨 Failed to reset password: $e");
    }
    return false;
  }

  /// **Submit High Score**
  Future<bool> submitHighScore(SubmitScoreRequest scoreRequest) async {
    await _getTokens(); // Ensure tokens are loaded

    if (userId == null || accessToken == null) {
      return false;
    }

    final headers = {
      'X-API-Key': Security.generateApiKeyHash(),
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    scoreRequest.userId = userId!; // Set userId in request

    final body = jsonEncode(scoreRequest.toJson());

    try {
      final response = await http.post(Uri.parse('${Config.apiUrl}/scores/submit'), headers: headers, body: body);

      if (response.statusCode == 200) {
        return true;
      } else {
        LogService.logError("🚨 Failed to submit high score: ${response.body}");
      }
    } catch (e) {
      LogService.logDebug("❌ Error submitting high score: $e");
    }

    return false;
  }

  /// **Validate Session**
  Future<bool> validateSession(String sanityToken) async {
    await _getTokens(); // Ensure tokens are loaded

    if (userId == null || accessToken == null) {
      LogService.logError("🚨 Cannot validate session - missing userId or accessToken");
      return false;
    }

    final headers = {
      'X-API-Key': Security.generateApiKeyHash(),
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({"userId": userId, "sanityToken": sanityToken});

    try {
      final response = await _makeApiRequest(false, '${Config.apiUrl}/validate-session', headers, body);
      return response.statusCode == 200;
    } catch (e) {
      LogService.logError("🚨 Session validation failed: $e");
      return false;
    }
  }

  /// **Parse API Response into `ApiResponse`**
  ApiResponse _parseResponse(http.Response response) {
    print('📡 API Response - Status: ${response.statusCode}, Body: ${response.body}');

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return ApiResponse(
        security:
            data.containsKey('userId')
                ? SecurityData(
                  userId: data['userId'],
                  accessToken: data['access_token'],
                  refreshToken: data['refresh_token'],
                  expirationSeconds: data['expires_in']?.toString(),
                )
                : null,
        gameData: data.containsKey('grid') ? GameData.fromJson(data) : null,
        highScoreData: data.containsKey('highScores') ? HighScoreData.fromJson(data) : null,
      );
    } else {
      throw ApiException(statusCode: response.statusCode, detail: 'Request failed: ${response.body}');
    }
  }

  /// **Unified API Request Handler**
  Future<http.Response> _makeApiRequest(bool isGet, String url, Map<String, String> headers, String? body) async {
    final prefs = await SharedPreferences.getInstance();

    if (await _isTokenExpiringSoon()) {
      await _refreshTokenIfNeeded();
      headers['Authorization'] = 'Bearer ${prefs.getString('accessToken')}'; // Update token in headers
    }

    var response =
        isGet
            ? await http.get(Uri.parse(url), headers: headers)
            : await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokenIfNeeded();

      if (refreshed) {
        headers['Authorization'] = 'Bearer ${prefs.getString('accessToken')}'; // Update token again

        return isGet
            ? await http.get(Uri.parse(url), headers: headers)
            : await http.post(Uri.parse(url), headers: headers, body: body);
      } else {
        throw ApiException(statusCode: 401, detail: 'Token refresh failed - Please log in again');
      }
    }
    return response;
  }
}
