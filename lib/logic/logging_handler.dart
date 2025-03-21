import 'package:flutter/foundation.dart';

/// Logging levels
enum LogLevel { debug, info, standard, production }

class LogService {
  /// 🔹 Current log level (default to `LogLevel.debug` for dev)
  static LogLevel _currentLevel = LogLevel.debug;

  /// 🔹 Set log level at runtime
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// 🔹 Internal log function to check if logging is allowed
  static void _log(String message, LogLevel level, {String prefix = ""}) {
    if (kDebugMode && level.index >= _currentLevel.index) {
      String timestamp = DateTime.now().toIso8601String(); // ✅ Add timestamp
      debugPrint("[$timestamp] $prefix$message");
    }
  }

  /// 🔹 Debug logs (Only shown in `debug` mode)
  static void logDebug(String message) => _log(message, LogLevel.debug, prefix: "🐞 [DEBUG] ");

  /// 🔹 Info logs (Useful events, minor details)
  static void logInfo(String message) => _log(message, LogLevel.info, prefix: "ℹ️ [INFO] ");

  /// 🔹 Standard logs (Only important messages)
  static void logStandard(String message) => _log(message, LogLevel.standard, prefix: "📌 [STANDARD] ");

  /// 🔹 Errors (Always logs in `debug`, `info`, and `standard` modes)
  static void logError(String message) => _log(message, LogLevel.production, prefix: "🚨 [ERROR] ");
}
