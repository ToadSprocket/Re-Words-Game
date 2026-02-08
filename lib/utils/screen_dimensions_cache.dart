// File: /lib/utils/screen_dimensions_cache.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../logic/logging_handler.dart';

/// A singleton class that caches the initial screen dimensions for Android devices.
/// This helps prevent layout issues caused by changing screen dimensions on Android tablets.
class ScreenDimensionsCache {
  static final ScreenDimensionsCache _instance = ScreenDimensionsCache._internal();

  factory ScreenDimensionsCache() {
    return _instance;
  }

  ScreenDimensionsCache._internal();

  // Cached dimensions
  Size? _cachedScreenSize;
  bool? _cachedIsNarrowLayout;
  bool _isInitialized = false;
  bool _isAndroidDevice = false;

  // Getters
  Size? get cachedScreenSize => _cachedScreenSize;
  bool? get cachedIsNarrowLayout => _cachedIsNarrowLayout;
  bool get isInitialized => _isInitialized;
  bool get isAndroidDevice => _isAndroidDevice;

  /// Initialize the cache with the initial screen dimensions.
  /// This should be called as early as possible in the app lifecycle.
  void initialize(BuildContext context, bool isNarrowLayout) {
    if (_isInitialized) {
      return;
    }

    // Check if we're on Android
    try {
      _isAndroidDevice = !kIsWeb && Platform.isAndroid;
    } catch (e) {
      _isAndroidDevice = false;
      LogService.logInfo('Platform API not available, assuming non-Android platform');
    }

    // Only cache dimensions for Android devices
    if (_isAndroidDevice) {
      final mediaQuery = MediaQuery.of(context);
      _cachedScreenSize = mediaQuery.size;
      _cachedIsNarrowLayout = isNarrowLayout;

      LogService.logInfo('📱 ScreenDimensionsCache initialized for Android device');
      LogService.logInfo('📱 Cached screen size: $_cachedScreenSize');
      LogService.logInfo('📱 Cached layout mode: ${_cachedIsNarrowLayout! ? 'narrow' : 'wide'}');
    }

    _isInitialized = true;
  }

  /// Get the screen size to use for layout calculations.
  /// For Android devices, this returns the cached size.
  /// For other platforms, it returns the current size from MediaQuery.
  Size getScreenSize(BuildContext context) {
    if (_isAndroidDevice && _cachedScreenSize != null) {
      return _cachedScreenSize!;
    }
    return MediaQuery.of(context).size;
  }

  /// Get the layout mode to use.
  /// For Android devices, this returns the cached layout mode.
  /// For other platforms, it returns null (indicating it should be calculated).
  bool? getLayoutMode() {
    if (_isAndroidDevice && _cachedIsNarrowLayout != null) {
      return _cachedIsNarrowLayout;
    }
    return null;
  }
}
