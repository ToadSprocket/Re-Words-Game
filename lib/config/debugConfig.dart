// File: /lib/config/debugConfig.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.

import '../logic/logging_handler.dart';

/// Centralized debug configuration for the Re-Word game.
/// All debug flags live here. Currently set in main.dart,
/// designed for future Firebase Remote Config integration.
class DebugConfig {
  static final DebugConfig _instance = DebugConfig._internal();
  factory DebugConfig() => _instance;
  DebugConfig._internal(); // No params needed

  // Fields with default values — mutable for runtime/Firebase changes
  bool showBorders = false;
  bool forceIsNarrow = false;
  bool disableSpellCheck = false;
  bool forceExpiredBoard = false;
  bool forceValidBoard = false;
  bool clearPrefs = true;
  bool forceIntroAnimation = false;
  bool disableSecretReset = false;
  bool showLayoutMeasurements = false;
  LogLevel logLevel = LogLevel.debug;
  bool logStackTraces = false;
}
