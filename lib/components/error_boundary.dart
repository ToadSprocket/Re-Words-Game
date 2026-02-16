// File: /lib/components/error_boundary.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // Listen for globally reported uncaught errors. ErrorReporting owns global
    // handler lifecycle; this boundary only decides how to render fallback UI.
    ErrorReporting.latestReportedError.addListener(_handleReportedErrorChanged);
  }

  @override
  void dispose() {
    // Remove listener to avoid updating state after this boundary is unmounted.
    ErrorReporting.latestReportedError.removeListener(_handleReportedErrorChanged);
    super.dispose();
  }

  void _handleReportedErrorChanged() {
    final reported = ErrorReporting.latestReportedError.value;
    if (!mounted || reported == null) return;

    // Preserve the first visible error until the user explicitly retries,
    // which avoids replacing the UI while they are reading the fallback.
    if (_error != null) return;

    setState(() {
      _error = reported.error;
      // Ensure custom builders always receive a stack trace, even when the
      // framework source does not provide one for this error signal.
      _stackTrace = reported.stackTrace ?? StackTrace.current;
    });
  }

  /// Reset the error state to show the child widget again
  void resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });

    // Clear the shared latest-error payload so newly mounted boundaries do not
    // immediately re-render the same stale failure after a successful retry.
    ErrorReporting.latestReportedError.value = null;
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

    // No error currently captured, so render the protected subtree.
    return widget.child;
  }
}
