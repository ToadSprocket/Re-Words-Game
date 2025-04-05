// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/config.dart';
import '../logic/logging_handler.dart';
import '../dialogs/enhanced_error_dialog.dart';

/// A centralized error handling system for the application.
///
/// This class provides methods for tracking, categorizing, and displaying errors
/// in a user-friendly way. It also supports error analytics if enabled.
class ErrorHandler {
  // Error categories
  static const String NETWORK_ERROR = 'network_error';
  static const String AUTH_ERROR = 'auth_error';
  static const String SERVER_ERROR = 'server_error';
  static const String DATA_ERROR = 'data_error';
  static const String UNKNOWN_ERROR = 'unknown_error';

  // Error severity levels
  static const int SEVERITY_LOW = 1; // Minor issues, non-critical
  static const int SEVERITY_MEDIUM = 2; // Important but not blocking
  static const int SEVERITY_HIGH = 3; // Critical errors requiring immediate attention

  /// Track errors for analytics and logging
  static Future<void> trackError(
    String category,
    String message, {
    int severity = SEVERITY_MEDIUM,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    // Log locally
    LogService.logError('[$category] $message');

    if (stackTrace != null) {
      LogService.logError('Stack trace: $stackTrace');
    }

    if (additionalData != null) {
      LogService.logError('Additional data: $additionalData');
    }

    // Send to analytics service if enabled
    // This would be implemented when an analytics service is integrated
    // For now, we just log the error
  }

  /// Handle errors with appropriate UI feedback
  static void handleError(
    BuildContext context,
    String category,
    String message, {
    int severity = SEVERITY_MEDIUM,
    VoidCallback? onRetry,
    bool showDialog = true,
    String? actionButtonText,
  }) {
    // Track the error
    trackError(category, message, severity: severity);

    // Show appropriate UI feedback
    if (showDialog) {
      _showErrorDialog(context, category, message, onRetry: onRetry, actionButtonText: actionButtonText);
    }
  }

  /// Show user-friendly error dialog
  static void _showErrorDialog(
    BuildContext context,
    String category,
    String message, {
    VoidCallback? onRetry,
    String? actionButtonText,
  }) {
    // Get user-friendly message based on error category
    final userMessage = _getUserFriendlyMessage(category, message);

    // Show appropriate dialog
    showDialog(
      context: context,
      builder:
          (context) => EnhancedErrorDialog(
            title: _getTitleForCategory(category),
            message: userMessage,
            onRetry: onRetry,
            actionButtonText: actionButtonText,
          ),
    );
  }

  /// Map technical errors to user-friendly messages
  static String _getUserFriendlyMessage(String category, String technicalMessage) {
    switch (category) {
      case NETWORK_ERROR:
        return 'Unable to connect to the game server. Please check your internet connection and try again.';
      case AUTH_ERROR:
        return 'Your session has expired. Please log in again to continue.';
      case SERVER_ERROR:
        return 'The game server is currently experiencing issues. Our team has been notified and is working on a fix.';
      case DATA_ERROR:
        return 'There was a problem loading your game data. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }

  /// Get appropriate title for error dialog based on category
  static String _getTitleForCategory(String category) {
    switch (category) {
      case NETWORK_ERROR:
        return 'Connection Error';
      case AUTH_ERROR:
        return 'Authentication Error';
      case SERVER_ERROR:
        return 'Server Error';
      case DATA_ERROR:
        return 'Data Error';
      default:
        return 'Error';
    }
  }

  /// Map DioException to error category
  static String categorizeException(dynamic exception) {
    if (exception is DioException) {
      switch (exception.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NETWORK_ERROR;
        case DioExceptionType.badCertificate:
        case DioExceptionType.connectionError:
          return NETWORK_ERROR;
        case DioExceptionType.badResponse:
          final statusCode = exception.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            return AUTH_ERROR;
          } else if (statusCode != null && statusCode >= 500) {
            return SERVER_ERROR;
          }
          return UNKNOWN_ERROR;
        default:
          return NETWORK_ERROR;
      }
    }

    return UNKNOWN_ERROR;
  }

  /// Get detailed error message from exception
  static String getDetailedErrorMessage(dynamic exception) {
    if (exception is DioException) {
      final statusCode = exception.response?.statusCode;
      final responseData = exception.response?.data;

      return 'Status code: ${statusCode ?? "unknown"}, Message: ${exception.message ?? "No message"}, Data: ${responseData ?? "No data"}';
    }

    return exception.toString();
  }
}
