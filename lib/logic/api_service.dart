import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logic/security.dart';
import '../config/config.dart';
import '../models/api_models.dart';

class ApiService {
  String? userId;
  String? accessToken;
  String? refreshToken;

  ApiService({this.userId, this.accessToken, this.refreshToken});

  Future<void> _updateTokens(SecurityData security) async {
    userId = security.userId;
    accessToken = security.accessToken;
    refreshToken = security.refreshToken;
    // TODO: Save to user_storage.dart later
  }

  Future<ApiResponse> register(String locale, String platform) async {
    final headers = {'X-API-Key': Security.generateApiKeyHash(), 'Content-Type': 'application/json'};
    final body = jsonEncode({'locale': locale, 'platform': platform});
    final response = await http.post(Uri.parse('${Config.apiUrl}/users/register'), headers: headers, body: body);
    final apiResponse = await _handleResponse(response, _RetryParams('register', headers, body));
    await _updateTokens(apiResponse.security!);
    return apiResponse;
  }

  Future<ApiResponse> getGameToday(String userId, String accessToken, Map<String, dynamic> stats) async {
    final headers = {
      'X-API-Key': Security.generateApiKeyHash(),
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({'userId': userId, ...stats});
    final response = await http.post(Uri.parse('${Config.apiUrl}/game/today'), headers: headers, body: body);
    return await _handleResponse(response, _RetryParams('getGameToday', headers, body));
  }

  Future<ApiResponse> _doRefreshToken(String userId, String refreshToken, Map<String, String> headers) async {
    final response = await http.post(Uri.parse('${Config.apiUrl}/users/refresh'), headers: headers);
    final apiResponse = await _handleResponse(response, _RetryParams('refreshToken', headers));
    await _updateTokens(apiResponse.security!);
    return apiResponse;
  }

  Future<ApiResponse> _handleResponse(http.Response response, _RetryParams params, {int retryCount = 0}) async {
    const maxRetries = 1;
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ApiResponse(
        security: SecurityData(
          userId: data['userId'],
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        ),
        gameData: data.containsKey('grid') ? GameData.fromJson(data) : null,
      );
    } else if (response.statusCode == 401 && retryCount < maxRetries) {
      final error = jsonDecode(response.body);
      if (error['detail'] == 'Token expired' && userId != null && refreshToken != null) {
        final headers = {
          'X-API-Key': Security.generateApiKeyHash(),
          'Refresh-Token': refreshToken!,
          'UserId': userId!,
          'Content-Type': 'application/json',
        };
        await _doRefreshToken(userId!, refreshToken!, headers);

        // Retry original request with new accessToken
        if (params.method == 'getGameToday') {
          final newHeaders = {...params.headers, 'Authorization': 'Bearer $accessToken'};
          final retryResponse = await http.post(
            Uri.parse('${Config.apiUrl}/game/today'),
            headers: newHeaders,
            body: params.body,
          );
          return _handleResponse(retryResponse, params, retryCount: retryCount + 1);
        } else if (params.method == 'register') {
          final retryResponse = await http.post(
            Uri.parse('${Config.apiUrl}/users/register'),
            headers: params.headers,
            body: params.body,
          );
          return _handleResponse(retryResponse, params, retryCount: retryCount + 1);
        }
        throw ApiException(statusCode: 401, detail: 'Retry not implemented for ${params.method}');
      }
      throw ApiException(statusCode: 401, detail: error['detail'] ?? 'Authentication failed');
    } else {
      throw ApiException(statusCode: response.statusCode, detail: 'Request failed');
    }
  }
}

class _RetryParams {
  final String method;
  final Map<String, String> headers;
  final String? body;

  _RetryParams(this.method, this.headers, [this.body]);
}
