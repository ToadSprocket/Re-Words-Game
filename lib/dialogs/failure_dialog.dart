// lib/dialogs/failure_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemNavigator.pop
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import '../dialogs/enhanced_error_dialog.dart';
import '../logic/error_handler.dart';
import '../logic/error_reporting.dart';
import '../utils/connectivity_monitor.dart';

class FailureDialog {
  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool isNetworkError = false,
  }) {
    // Check if this is a network error
    if (isNetworkError) {
      // Report the error
      ErrorReporting.reportWarning('Network error detected when showing failure dialog', context: 'FailureDialog.show');

      // Show the enhanced error dialog with network error message
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return EnhancedErrorDialog(
            title: title ?? 'Connection Error',
            message:
                message ?? 'Unable to connect to the game server. Please check your internet connection and try again.',
            onRetry: onRetry,
            onClose: () async {
              Navigator.of(context).pop();
              if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
                await windowManager.destroy(); // Force close on desktop
              } else {
                SystemNavigator.pop(); // Mobile fallback
              }
            },
            actionButtonText: onRetry != null ? 'Retry' : null,
          );
        },
      );
    }

    // Check connectivity
    ConnectivityMonitor().checkConnection().then((isConnected) {
      if (!isConnected) {
        ErrorReporting.reportWarning(
          'No network connection detected when showing failure dialog',
          context: 'FailureDialog.show',
        );
      }
    });

    // Default server error dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EnhancedErrorDialog(
          title: title ?? 'Server Error',
          message: message ?? 'Failure contacting game server.\nPlease Try Again Later',
          onRetry: onRetry,
          onClose: () async {
            Navigator.of(context).pop();
            if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
              await windowManager.destroy();
            } else {
              SystemNavigator.pop();
            }
          },
          actionButtonText: onRetry != null ? 'Retry' : null,
        );
      },
    );
  }

  /// Show a specific error dialog based on error type
  static Future<void> showError(BuildContext context, dynamic error, {VoidCallback? onRetry}) {
    // Determine error category and message
    String category = ErrorHandler.UNKNOWN_ERROR;
    String title = 'Error';
    String message = 'An unexpected error occurred. Please try again later.';

    // Categorize the error
    if (error is Exception) {
      category = ErrorHandler.categorizeException(error);

      switch (category) {
        case ErrorHandler.NETWORK_ERROR:
          title = 'Connection Error';
          message = 'Unable to connect to the game server. Please check your internet connection and try again.';
          break;
        case ErrorHandler.AUTH_ERROR:
          title = 'Authentication Error';
          message = 'Your session has expired. Please log in again to continue.';
          break;
        case ErrorHandler.SERVER_ERROR:
          title = 'Server Error';
          message =
              'The game server is currently experiencing issues. Our team has been notified and is working on a fix.';
          break;
        case ErrorHandler.DATA_ERROR:
          title = 'Data Error';
          message = 'There was a problem loading your game data. Please try again.';
          break;
        default:
          title = 'Error';
          message = 'An unexpected error occurred. Please try again later.';
      }

      ErrorReporting.reportException(error, StackTrace.current, context: 'FailureDialog.showError');
    } else {
      message = error.toString();
      ErrorReporting.reportWarning('Non-exception error: $error', context: 'FailureDialog.showError');
    }

    // Show the appropriate dialog
    return show(
      context,
      title: title,
      message: message,
      onRetry: onRetry,
      isNetworkError: category == ErrorHandler.NETWORK_ERROR,
    );
  }
}
