// File: /lib/providers/orientation_provider.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../utils/device_utils.dart';
import '../models/layoutModels.dart';
import '../logic/logging_handler.dart';

class OrientationProvider extends ChangeNotifier {
  Orientation _orientation = Orientation.portrait;
  Size _initialSize = Size.zero;
  Size _currentSize = Size.zero;

  // Add safe screen dimensions
  Size _initialSafeSize = Size.zero;
  Size _currentSafeSize = Size.zero;

  // Add device information
  DeviceLayout? _deviceInfo;

  Orientation get orientation => _orientation;
  Size get initialSize => _initialSize;
  Size get currentSize => _currentSize;

  // Add getters for safe screen dimensions
  Size get initialSafeSize => _initialSafeSize;
  Size get currentSafeSize => _currentSafeSize;

  // Add getter for device information
  DeviceLayout? get deviceInfo => _deviceInfo;

  void initialize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _currentSize = mediaQuery.size;

    // Get device information with safe screen dimensions
    final deviceInfo = DeviceUtils.getDeviceInformation(context);
    _deviceInfo = deviceInfo;
    _currentSafeSize = Size(deviceInfo.safeScreenWidth, deviceInfo.safeScreenHeight);

    // Only set initial size once
    if (_initialSize == Size.zero) {
      _initialSize = mediaQuery.size;
      _initialSafeSize = _currentSafeSize;
      _orientation = mediaQuery.orientation;
      LogService.logInfo(
        "ORIENTATION PROVIDER INITIALIZED: size: $_initialSize, safe size: $_initialSafeSize, orientation: $_orientation",
      );
    }
  }

  void changeOrientation(Orientation newOrientation, Size newSize) {
    bool hasChanged = _orientation != newOrientation || _currentSize != newSize;

    // Only update values and notify if there's an actual change
    if (hasChanged) {
      LogService.logInfo("CHANGE ORIENTATION CALLED: old: $_orientation, new: $newOrientation");
      LogService.logInfo("SIZE CHANGE: old: $_currentSize, new: $newSize");
      _orientation = newOrientation;
      _currentSize = newSize;

      // We need to update the safe size as well, but we need the BuildContext to get it
      // This will be done by the caller using updateSafeSize

      notifyListeners();
    }
  }

  // New method to update safe screen dimensions
  void updateSafeSize(BuildContext context) {
    final deviceInfo = DeviceUtils.getDeviceInformation(context);
    _deviceInfo = deviceInfo;
    _currentSafeSize = Size(deviceInfo.safeScreenWidth, deviceInfo.safeScreenHeight);
    LogService.logInfo("SAFE SIZE UPDATED: $_currentSafeSize");
  }

  // Get the correct dimensions based on current orientation
  Size getCorrectDimensions() {
    // Use safe screen dimensions instead of raw dimensions
    Size baseSize = _initialSafeSize;

    // If we're in portrait but the initial orientation was landscape
    if (_orientation == Orientation.portrait && baseSize.width > baseSize.height) {
      return Size(baseSize.height, baseSize.width);
    }
    // If we're in landscape but the initial orientation was portrait
    else if (_orientation == Orientation.landscape && baseSize.height > baseSize.width) {
      return Size(baseSize.width, baseSize.height);
    }
    // Otherwise use the initial size as is
    return baseSize;
  }
}
