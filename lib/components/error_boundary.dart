// File: /lib/components/error_boundary.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../logic/logging_handler.dart';
import '../logic/error_handler.dart';
import '../logic/error_reporting.dart';
import '../managers/gameLayoutManager.dart';

/// A widget that catches errors in its child widget tree and displays a fallback UI.
///
/// This widget acts as a boundary that prevents errors in one part of the UI from
/// crashing the entire application. When an error occurs in the child widget tree,
/// this widget catches the error and displays a fallback UI that allows the user
/// to retry or continue using the app.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, Object, StackTrace)? errorBuilder;

  const ErrorBoundary({Key? key, required this.child, this.errorBuilder}) : super(key: key);

  @override
  ErrorBoundaryState createState() => ErrorBoundaryState();
}

class ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  /// Reset the error state to show the child widget again
  void resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If there's an error, show the error UI
    if (_error != null) {
      // Use custom error builder if provided
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!, _stackTrace!);
      }

      // Default error widget
      final gameLayoutManager = GameLayoutManager();

      return Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Something went wrong', style: gameLayoutManager.dialogTitleStyle, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                _error.toString(),
                style: gameLayoutManager.dialogContentStyle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: resetError,
                style: gameLayoutManager.buttonStyle(context),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // No error, render the child widget inside an error catcher
    return _ErrorCatcher(onError: _captureError, child: widget.child);
  }

  void _captureError(Object error, StackTrace stackTrace) {
    // Log the error
    LogService.logError('UI Error: $error');

    // Only log stack traces if the flag is enabled
    if (ErrorReporting.logStackTraces) {
      LogService.logError('Stack trace: $stackTrace');
    }

    // Track the error
    ErrorHandler.trackError(
      ErrorHandler.UNKNOWN_ERROR,
      error.toString(),
      severity: ErrorHandler.SEVERITY_HIGH,
      // Only pass stack trace if logging is enabled
      stackTrace: ErrorReporting.logStackTraces ? stackTrace : null,
    );

    // Force a rebuild with the error state
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
  }
}

/// A widget that catches errors in its child widget
class _ErrorCatcher extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  const _ErrorCatcher({Key? key, required this.child, required this.onError}) : super(key: key);

  @override
  _ErrorCatcherState createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<_ErrorCatcher> {
  // Store the previous error handler
  FlutterExceptionHandler? _previousErrorHandler;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    // Store the previous error handler and set our custom one
    // Use a post-frame callback to avoid setting during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousErrorHandler = FlutterError.onError;
      FlutterError.onError = _handleFlutterError;
    });
  }

  @override
  void dispose() {
    // Restore the previous error handler if it exists
    if (_previousErrorHandler != null) {
      FlutterError.onError = _previousErrorHandler;
    } else {
      FlutterError.onError = FlutterError.presentError;
    }
    super.dispose();
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    // Use a post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onError(details.exception, details.stack ?? StackTrace.current);
      }
    });
  }
}
