// lib/utils/web_utils_stub.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
// This file is only included in non-web builds

import '../logic/logging_handler.dart';

/// Stub implementation of WebUtils for non-web platforms
class WebUtils {
  /// Redirects to the specified URL (no-op on non-web platforms)
  static void redirectToUrl(String url) {
    LogService.logInfo('WebUtils.redirectToUrl called on non-web platform: $url');
    // No-op on non-web platforms
  }
}
