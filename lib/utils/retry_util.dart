// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:async';
import '../logic/logging_handler.dart';

/// A utility class that provides retry functionality for asynchronous operations.
///
/// This class allows for retrying operations that might fail due to transient issues
/// such as network connectivity problems or temporary server errors.
class RetryUtil {
  /// Execute a function with retry capability
  ///
  /// Parameters:
  /// - [function]: The async function to execute and potentially retry
  /// - [maxRetries]: Maximum number of retry attempts (default: 3)
  /// - [delay]: Base delay between retries, which increases with each attempt (default: 1 second)
  /// - [retryIf]: Optional function to determine if a specific exception should trigger a retry
  /// - [onRetry]: Optional callback that is called before each retry attempt
  ///
  /// Returns the result of the function if successful, otherwise throws the last exception
  static Future<T> withRetry<T>(
    Future<T> Function() function, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Exception)? retryIf,
    void Function(Exception, int)? onRetry,
  }) async {
    int attempts = 0;

    while (true) {
      try {
        attempts++;
        LogService.logDebug('🔄 Attempt $attempts${maxRetries > 0 ? '/$maxRetries' : ''} for operation');
        return await function();
      } on Exception catch (e) {
        // Check if we should retry based on the exception
        final shouldRetry = retryIf?.call(e) ?? true;

        if (attempts <= maxRetries && shouldRetry) {
          // Calculate exponential backoff delay
          final retryDelay = delay * attempts;

          // Log the retry
          LogService.logInfo('🔄 Retry attempt $attempts/$maxRetries after $retryDelay: ${e.toString()}');

          // Call the onRetry callback if provided
          onRetry?.call(e, attempts);

          // Wait before retrying with exponential backoff
          await Future.delayed(retryDelay);
        } else {
          LogService.logError('❌ All retry attempts failed or max retries reached: ${e.toString()}');
          rethrow;
        }
      } catch (e) {
        // For non-Exception errors, don't retry
        LogService.logError('❌ Non-retryable error: ${e.toString()}');
        rethrow;
      }
    }
  }

  /// Retry a function with a fixed number of attempts
  ///
  /// A simpler version of withRetry that uses a fixed number of attempts
  /// without exponential backoff or conditional retrying.
  static Future<T> simpleRetry<T>(
    Future<T> Function() function, {
    int attempts = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (int i = 0; i < attempts; i++) {
      try {
        if (i > 0) {
          LogService.logInfo('🔄 Simple retry attempt ${i + 1}/$attempts');
        }
        return await function();
      } catch (e) {
        if (i == attempts - 1) {
          // Last attempt failed
          LogService.logError('❌ All simple retry attempts failed: ${e.toString()}');
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);
      }
    }

    // This should never be reached due to the rethrow above
    throw Exception('Unexpected error in retry logic');
  }
}
