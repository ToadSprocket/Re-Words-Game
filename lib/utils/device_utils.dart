// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../logic/logging_handler.dart';

/// Utility class for device-specific operations
class DeviceUtils {
  /// Determines if the current device is a tablet based on screen size
  ///
  /// Uses a diagonal screen size threshold of approximately 7 inches
  /// to differentiate between phones and tablets
  static bool isTablet(BuildContext context) {
    // Web is never considered a tablet for our purposes
    if (kIsWeb) return false;

    // Only check for mobile platforms
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Size size = mediaQuery.size;
    final double diagonal = sqrt(size.width * size.width + size.height * size.height);

    // Consider a device with a diagonal > 7 inches (in device pixels) to be a tablet
    // 7 inches ≈ 7 * devicePixelRatio * 160 (pixels per inch)
    final bool isTabletSize = diagonal > (7 * mediaQuery.devicePixelRatio * 160);

    LogService.logInfo(
      "📱 Device diagonal: $diagonal px, devicePixelRatio: ${mediaQuery.devicePixelRatio}, isTablet: $isTabletSize",
    );

    return isTabletSize;
  }

  /// Sets the appropriate orientation settings based on device type
  ///
  /// For phones: Locks to portrait orientation
  /// For tablets: Allows all orientations
  static void setOrientationSettings(BuildContext context) {
    // Only apply orientation settings on mobile platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final bool isDeviceTablet = isTablet(context);

      if (!isDeviceTablet) {
        // Lock phones to portrait orientation
        LogService.logInfo("📱 Setting phone orientation: portrait only");
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      } else {
        // Allow all orientations for tablets
        LogService.logInfo("📱 Setting tablet orientation: all orientations");
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
  }

  /// Determines if the app should use narrow layout based on device type and orientation
  ///
  /// Returns true for:
  /// - Phones (always use narrow layout)
  /// - Tablets in portrait orientation
  /// - Non-mobile devices with width < threshold
  static bool shouldUseNarrowLayout(BuildContext context, double thresholdWidth) {
    // For debugging
    if (kDebugMode && forceNarrowLayout != null) {
      return forceNarrowLayout!;
    }

    // Web uses width-based detection only
    if (kIsWeb) {
      return MediaQuery.of(context).size.width < thresholdWidth;
    }

    // Mobile platforms use device type detection
    if (Platform.isAndroid || Platform.isIOS) {
      final bool isDeviceTablet = isTablet(context);

      if (!isDeviceTablet) {
        // Phones always use narrow layout
        return true;
      } else {
        // Tablets use narrow layout in portrait, wide layout in landscape
        final Orientation orientation = MediaQuery.of(context).orientation;
        return orientation == Orientation.portrait;
      }
    }

    // Desktop platforms use width-based detection
    return MediaQuery.of(context).size.width < thresholdWidth;
  }

  // For debugging purposes only
  static bool? forceNarrowLayout;
}

// Extension to make it easier to check orientation
extension OrientationExtension on MediaQueryData {
  Orientation get orientation => size.width > size.height ? Orientation.landscape : Orientation.portrait;
}
