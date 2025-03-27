import 'package:flutter/foundation.dart';

/// Logging levels
enum LogLevel { debug, info, standard, production }

class LogService {
  /// 🔹 Current log level (default to `LogLevel.production` for production)
  static LogLevel _currentLevel = LogLevel.production;

  /// 🔹 Set log level at runtime
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// 🔹 Configure logging based on build mode
  static void configureLogging() {
    if (kDebugMode) {
      _currentLevel = LogLevel.debug;
    } else {
      _currentLevel = LogLevel.production;
    }
  }

  /// 🔹 Internal log function to check if logging is allowed
  static void _log(String message, LogLevel level, {String prefix = ""}) {
    // Always log errors in production, respect log level for other types
    if (level == LogLevel.production || (kDebugMode && level.index >= _currentLevel.index)) {
      String timestamp = DateTime.now().toIso8601String();
      debugPrint("[$timestamp] $prefix$message");
    }
  }

  /// 🔹 Debug logs (Only shown in `debug` mode)
  static void logDebug(String message) => _log(message, LogLevel.debug, prefix: "🐞 [DEBUG] ");

  /// 🔹 Info logs (Useful events, minor details)
  static void logInfo(String message) => _log(message, LogLevel.info, prefix: "ℹ️ [INFO] ");

  /// 🔹 Standard logs (Only important messages)
  static void logStandard(String message) => _log(message, LogLevel.standard, prefix: "📌 [STANDARD] ");

  /// 🔹 Errors (Always logs in all modes)
  static void logError(String message) => _log(message, LogLevel.production, prefix: "🚨 [ERROR] ");
}
