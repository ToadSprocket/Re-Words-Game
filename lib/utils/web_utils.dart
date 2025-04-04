// lib/utils/web_utils.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.

// This file uses conditional imports to provide platform-specific implementations
// For web: web_utils_web.dart
// For non-web: web_utils_stub.dart

export 'web_utils_stub.dart' if (dart.library.html) 'web_utils_web.dart';
