// File: /lib/utils/error_messages.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:dio/dio.dart';

/// A utility class that maps technical error codes and exceptions to user-friendly messages.
///
/// This class provides methods to convert technical error information into messages
/// that are more understandable for end users.
class ErrorMessages {
  // Map error codes or types to user-friendly messages
  static final Map<String, String> _messageMap = {
    // Network errors
    'connection_error': 'Unable to connect to the game server. Please check your internet connection.',
    'timeout_error': 'The connection to the server timed out. Please try again.',

    // Authentication errors
    'invalid_credentials': 'The username or password you entered is incorrect.',
    'session_expired': 'Your session has expired. Please log in again.',
    'unauthorized': 'You are not authorized to perform this action. Please log in again.',

    // Server errors
    'server_error': 'The game server is currently experiencing issues. Please try again later.',
    'maintenance': 'The game is currently undergoing maintenance. Please check back soon.',

    // Data errors
    'invalid_data': 'There was a problem with your game data. Please restart the game.',
    'board_expired': 'This game board has expired. A new board is now available!',
    'data_not_found': 'The requested data could not be found.',

    // Input validation errors
    'invalid_email': 'Please enter a valid email address.',
    'weak_password':
        'Your password is too weak. It should be at least 8 characters long and include numbers and special characters.',
    'username_taken': 'This username is already taken. Please choose another one.',

    // Default error
    'default': 'An unexpected error occurred. Please try again later.',
  };

  /// Get a user-friendly message for an error code
  static String getUserMessage(String errorCode) {
    return _messageMap[errorCode] ?? _messageMap['default']!;
  }

  /// Get a user-friendly message for an exception
  static String getMessageForException(dynamic exception) {
    if (exception is DioException) {
      switch (exception.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return getUserMessage('timeout_error');
        case DioExceptionType.badResponse:
          final statusCode = exception.response?.statusCode;
          if (statusCode == 401) return getUserMessage('session_expired');
          if (statusCode == 403) return getUserMessage('unauthorized');
          if (statusCode == 503) return getUserMessage('maintenance');
          if (statusCode != null && statusCode >= 500) return getUserMessage('server_error');
          if (statusCode == 404) return getUserMessage('data_not_found');
          return getUserMessage('default');
        case DioExceptionType.cancel:
          return 'The request was cancelled.';
        case DioExceptionType.connectionError:
          return getUserMessage('connection_error');
        case DioExceptionType.badCertificate:
          return 'There was a security issue connecting to the server. Please try again later.';
        default:
          return getUserMessage('connection_error');
      }
    }

    // Handle other exception types
    return getUserMessage('default');
  }

  /// Get a user-friendly message for a specific HTTP status code
  static String getMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'The request was invalid. Please try again.';
      case 401:
        return getUserMessage('session_expired');
      case 403:
        return getUserMessage('unauthorized');
      case 404:
        return getUserMessage('data_not_found');
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
      case 502:
      case 503:
      case 504:
        return getUserMessage('server_error');
      default:
        return getUserMessage('default');
    }
  }

  /// Get a user-friendly message for a specific error scenario
  static String getMessageForScenario(String scenario, {Map<String, dynamic>? params}) {
    switch (scenario) {
      case 'login_failed':
        return getUserMessage('invalid_credentials');
      case 'network_disconnected':
        return 'You are currently offline. Some features may not be available.';
      case 'token_refresh_failed':
        return 'Your session could not be renewed. Please log in again.';
      case 'game_data_load_failed':
        return 'Failed to load game data. Please check your connection and try again.';
      case 'high_score_submission_failed':
        return 'Failed to submit your high score. We\'ll try again later.';
      default:
        return getUserMessage('default');
    }
  }
}
