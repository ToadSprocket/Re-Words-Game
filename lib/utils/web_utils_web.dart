// File: /lib/utils/web_utils_web.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
// This file is only included in web builds

import 'dart:html' as html;
import '../logic/logging_handler.dart';

/// Web-specific implementation of WebUtils
class WebUtils {
  /// Redirects to the specified URL
  static void redirectToUrl(String url) {
    bool redirectSuccess = false;

    try {
      LogService.logInfo('Web redirecting to: $url');

      // Try multiple redirect methods to ensure it works
      try {
        // Method 1: Using replace (most forceful)
        html.window.location.replace(url);
        redirectSuccess = true;
      } catch (e) {
        LogService.logError('Error with replace redirect: $e');

        try {
          // Method 2: Using href
          html.window.location.href = url;
          redirectSuccess = true;
        } catch (e) {
          LogService.logError('Error with href redirect: $e');

          try {
            // Method 3: Using assign
            html.window.location.assign(url);
            redirectSuccess = true;
          } catch (e) {
            LogService.logError('Error with assign redirect: $e');
          }
        }
      }
    } catch (e) {
      LogService.logError('Error redirecting to $url: $e');
    }

    // If all redirect methods failed, show a message to the user
    if (!redirectSuccess) {
      // Create a dialog element
      final dialogElement =
          html.DivElement()
            ..id = 'redirect-error-dialog'
            ..style.position = 'fixed'
            ..style.top = '50%'
            ..style.left = '50%'
            ..style.transform = 'translate(-50%, -50%)'
            ..style.backgroundColor = '#fff'
            ..style.padding = '20px'
            ..style.borderRadius = '5px'
            ..style.boxShadow = '0 0 10px rgba(0,0,0,0.5)'
            ..style.zIndex = '9999'
            ..style.maxWidth = '80%'
            ..style.textAlign = 'center';

      // Add message
      dialogElement.append(
        html.ParagraphElement()
          ..text = 'Unable to redirect automatically.'
          ..style.margin = '0 0 15px 0'
          ..style.fontWeight = 'bold',
      );

      dialogElement.append(
        html.ParagraphElement()
          ..text = 'Please click the button below or copy the URL manually:'
          ..style.margin = '0 0 15px 0',
      );

      // Add URL display
      final urlDisplay =
          html.InputElement()
            ..type = 'text'
            ..value = url
            ..readOnly = true
            ..style.width = '100%'
            ..style.padding = '8px'
            ..style.marginBottom = '15px'
            ..style.border = '1px solid #ccc'
            ..style.borderRadius = '3px';
      dialogElement.append(urlDisplay);

      // Add redirect button
      final redirectButton =
          html.ButtonElement()
            ..text = 'Go to Website'
            ..style.padding = '8px 16px'
            ..style.backgroundColor = '#4CAF50'
            ..style.color = 'white'
            ..style.border = 'none'
            ..style.borderRadius = '3px'
            ..style.cursor = 'pointer'
            ..onClick.listen((event) {
              html.window.open(url, '_blank');
            });
      dialogElement.append(redirectButton);

      // Add to document body
      html.document.body?.append(dialogElement);

      // Log the fallback
      LogService.logInfo('Showing manual redirect dialog for URL: $url');
    }
  }
}
