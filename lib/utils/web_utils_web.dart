// lib/utils/web_utils_web.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
// This file is only included in web builds

import 'dart:html' as html;
import '../logic/logging_handler.dart';

/// Web-specific implementation of WebUtils
class WebUtils {
  /// Redirects to the specified URL
  static void redirectToUrl(String url) {
    try {
      LogService.logInfo('Web redirecting to: $url');

      // Try multiple redirect methods to ensure it works
      try {
        // Method 1: Using replace (most forceful)
        html.window.location.replace(url);
      } catch (e) {
        LogService.logError('Error with replace redirect: $e');

        try {
          // Method 2: Using href
          html.window.location.href = url;
        } catch (e) {
          LogService.logError('Error with href redirect: $e');

          // Method 3: Using assign
          html.window.location.assign(url);
        }
      }
    } catch (e) {
      LogService.logError('Error redirecting to $url: $e');
    }
  }
}
