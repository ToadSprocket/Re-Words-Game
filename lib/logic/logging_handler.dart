import 'package:flutter/foundation.dart';

/// Logging levels
enum LogLevel { debug, info, standard, production }

class LogService {
  /// 🔹 Current log level (default to `LogLevel.production` for production)
  static LogLevel _currentLevel = LogLevel.production;
  static bool _enhancedLoggingEnabled = true;
  static List<String> _logEntries = [];
  static const int MAX_LOG_ENTRIES = 200;

  /// 🔹 Configure logging based on build mode
  static void configureLogging(LogLevel level) {
    _currentLevel = level;
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

  static void logEvent(String message) {
    if (_logEntries.length == MAX_LOG_ENTRIES) {
      _logEntries.removeAt(0);
    }
    _logEntries.add(message + "|");
  }

  static List<String> getLogEvents() {
    return List.from(_logEntries);
  }

  static void clearEvents() {
    _logEntries.clear();
  }
}
