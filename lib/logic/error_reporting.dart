// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../logic/logging_handler.dart';
import '../config/config.dart';

/// A class that handles structured error reporting and analytics.
///
/// This class provides methods to initialize error reporting services,
/// set up global error handlers, and report errors to analytics services.
class ErrorReporting {
  static bool _initialized = false;

  /// Flag to control whether stack traces are logged
  /// Set to false by default to suppress stack traces
  static bool logStackTraces = false;

  /// Toggle stack trace logging on/off
  static void toggleStackTraceLogging(bool enabled) {
    logStackTraces = enabled;
    LogService.logInfo('Stack trace logging ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Initialize error reporting services
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Set up global error handlers
      FlutterError.onError = (FlutterErrorDetails details) {
        _reportError(details.exception, details.stack, 'Flutter Error');
      };

      // Handle errors that occur during async operations
      PlatformDispatcher.instance.onError = (error, stack) {
        _reportError(error, stack, 'Platform Dispatcher Error');
        return true; // Prevent the error from being propagated
      };

      _initialized = true;
      LogService.logInfo('🔍 Error reporting initialized');
    } catch (e) {
      LogService.logError('🚨 Failed to initialize error reporting: $e');
    }
  }

  /// Report an error to the error reporting service
  static void _reportError(dynamic error, StackTrace? stackTrace, String source) {
    try {
      LogService.logError('[$source] $error');
      // Only log stack traces if the flag is enabled
      if (logStackTraces && stackTrace != null) {
        LogService.logError('Stack trace: $stackTrace');
      }

      // In a production app, you would send this to an error reporting service
      // such as Firebase Crashlytics, Sentry, etc.
      //
      // Example implementation for Firebase Crashlytics:
      // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: source);
      //
      // Example implementation for Sentry:
      // Sentry.captureException(error, stackTrace: stackTrace);
    } catch (e) {
      LogService.logError('🚨 Failed to report error: $e');
    }
  }

  /// Report a caught exception
  static void reportException(
    dynamic exception,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    final contextStr = context != null ? '[$context] ' : '';
    _reportError('${contextStr}Caught exception: $exception', stackTrace, 'Manual Report');

    // Log additional data if provided
    if (additionalData != null && logStackTraces) {
      LogService.logError('Additional data: $additionalData');
    }
  }

  /// Report a non-fatal error or warning
  static void reportWarning(String message, {String? context, Map<String, dynamic>? additionalData}) {
    final contextStr = context != null ? '[$context] ' : '';
    LogService.logInfo('⚠️ ${contextStr}Warning: $message');

    // Log additional data if provided
    if (additionalData != null) {
      LogService.logInfo('Additional data: $additionalData');
    }

    // In a production app, you might want to send this to an analytics service
    // for tracking non-fatal issues
  }

  /// Report a user action that led to an error
  static void reportUserActionError(
    String action,
    dynamic error,
    StackTrace stackTrace, {
    BuildContext? context,
    Map<String, dynamic>? additionalData,
  }) {
    LogService.logError('🚨 User action "$action" resulted in error: $error');

    // Report the error
    _reportError(error, stackTrace, 'User Action: $action');

    // Log additional data if provided
    if (additionalData != null && logStackTraces) {
      LogService.logError('Additional data: $additionalData');
    }
  }
}
