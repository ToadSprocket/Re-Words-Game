// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../logic/logging_handler.dart';
import '../models/layoutModels.dart';

/// Utility class for device-specific operations
class DeviceUtils {
  /// Sets the appropriate orientation settings based on device type
  ///
  /// For phones: Locks to portrait orientation
  /// For tablets: Allows all orientations
  static void setOrientationSettings(BuildContext context) {
    // Only apply orientation settings on mobile platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Check for phone form factor
      if (mediaQuery.isPhone) {
        LogService.logInfo("📱 Setting phone orientation: portrait only");
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        return;
      }

      // Check for tablet form factor
      if (mediaQuery.isTablet) {
        if (Platform.isIOS) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          return;
        }

        if (mediaQuery.isTallAspectRatio) {
          LogService.logInfo("📱 Tablet portrait detected, setting orientation: portrait only");
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        } else {
          LogService.logInfo("📱 Tablet landscape detected, setting orientation: landscape");
          SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
        }
        return;
      }

      // Check for hybrid form factor
      if (mediaQuery.isHybrid) {
        if (mediaQuery.isTallAspectRatio) {
          LogService.logInfo("📱 Hybrid portrait detected, setting orientation: portrait only");
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        } else {
          LogService.logInfo("📱 Hybrid landscape detected, setting orientation: landscape");
          SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
        }
        return;
      }
    }
  }

  static DeviceLayout getDeviceInformation(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // For web or non-mobile platforms
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return DeviceLayout(
        screenWidth: mediaQuery.size.width,
        screenHeight: mediaQuery.size.height,
        // Correct way to get the proper height and size.
        safeScreenWidth: mediaQuery.size.width - mediaQuery.padding.left - mediaQuery.padding.right,
        safeScreenHeight: mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom,
        aspectRatio: mediaQuery.aspectRatio,
        isPhone: false,
        isTablet: false,
        isHybrid: false,
        isWide: mediaQuery.isWideAspectRatio,
        isTall: mediaQuery.isTallAspectRatio,
        orientation: mediaQuery.orientation,
      );
    }

    return DeviceLayout(
      screenWidth: mediaQuery.size.width,
      screenHeight: mediaQuery.size.height,
      safeScreenWidth: mediaQuery.size.width - mediaQuery.padding.left - mediaQuery.padding.right,
      safeScreenHeight: mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom,
      aspectRatio: mediaQuery.aspectRatio,
      isPhone: mediaQuery.isPhone,
      isTablet: mediaQuery.isTablet,
      isHybrid: mediaQuery.isHybrid,
      isWide: mediaQuery.isWideAspectRatio,
      isTall: mediaQuery.isTallAspectRatio,
      orientation: mediaQuery.orientation,
    );
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

    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Web uses width-based detection only
    if (kIsWeb) {
      return mediaQuery.size.width < thresholdWidth;
    }

    // Mobile platforms use device type detection
    if (Platform.isAndroid || Platform.isIOS) {
      if (mediaQuery.isPhone) {
        return true;
      } else {
        if (mediaQuery.isTallAspectRatio) {
          return true;
        }
        return false;
      }
    }

    // Desktop platforms use width-based detection
    return MediaQuery.of(context).size.width < thresholdWidth;
  }

  // For debugging purposes only
  static bool? forceNarrowLayout;
}

// Extension to make it easier to check orientation
// Extension to make it easier to check orientation and aspect ratio
extension OrientationExtension on MediaQueryData {
  // Standard orientation check based on width vs height
  Orientation get orientation => size.width > size.height ? Orientation.landscape : Orientation.portrait;

  // Diagonal ratio
  double get diagonal => sqrt(size.width * size.width + size.height * size.height);

  // Screen inches
  double get inches => diagonal / devicePixelRatio / 160;

  // Calculate aspect ratio (width:height)
  double get aspectRatio => size.width / size.height;

  // landscape phones/tablets/monitors
  bool get isWideAspectRatio => aspectRatio >= 1.6;

  // portrait phones, tablets
  bool get isTallAspectRatio => aspectRatio <= 0.75;

  // Phone detection: tall and skinny (aspect ratio <= 0.667, e.g., 16:9 or taller)
  bool get isPhone => aspectRatio < 0.6;

  // Tablet detection: squarer (aspect ratio between 1.3 and 1.6, e.g., 4:3 or 16:10)
  bool get isTablet => aspectRatio > 0.6 && aspectRatio <= 1.6;

  // Optional: Hybrid check (large phones or small tablets, e.g., 6.5–8" with phone-like aspect ratio)
  bool get isHybrid => inches > 6.5 && inches <= 8.0 && aspectRatio <= 0.667;
}
