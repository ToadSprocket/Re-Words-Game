// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';

class OrientationProvider extends ChangeNotifier {
  Orientation _orientation = Orientation.portrait;
  Size _initialSize = Size.zero;
  Size _currentSize = Size.zero;

  Orientation get orientation => _orientation;
  Size get initialSize => _initialSize;
  Size get currentSize => _currentSize;

  void initialize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _currentSize = mediaQuery.size;

    // Only set initial size once
    if (_initialSize == Size.zero) {
      _initialSize = mediaQuery.size;
      _orientation = mediaQuery.orientation;
      print("ORIENTATION PROVIDER INITIALIZED: size: $_initialSize, orientation: $_orientation");
    }
  }

  void changeOrientation(Orientation newOrientation, Size newSize) {
    print("CHANGE ORIENTATION CALLED: old: $_orientation, new: $newOrientation");
    print("SIZE CHANGE: old: $_currentSize, new: $newSize");

    bool hasChanged = _orientation != newOrientation || _currentSize != newSize;
    _orientation = newOrientation;
    _currentSize = newSize;

    if (hasChanged) notifyListeners();
  }

  // Get the correct dimensions based on current orientation
  Size getCorrectDimensions() {
    // If we're in portrait but the initial orientation was landscape
    if (_orientation == Orientation.portrait && _initialSize.width > _initialSize.height) {
      return Size(_initialSize.height, _initialSize.width);
    }
    // If we're in landscape but the initial orientation was portrait
    else if (_orientation == Orientation.landscape && _initialSize.height > _initialSize.width) {
      return Size(_initialSize.width, _initialSize.height);
    }
    // Otherwise use the initial size as is
    return _initialSize;
  }
}
