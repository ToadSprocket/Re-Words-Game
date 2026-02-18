// File: /lib/models/layout_models.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/widgets.dart';

class DeviceLayout {
  final double screenWidth;
  final double screenHeight;
  final double safeScreenWidth;
  final double safeScreenHeight;
  final double aspectRatio;
  final bool isPhone;
  final bool isTablet;
  final bool isHybrid;
  final bool isWide;
  final bool isTall;
  final Orientation orientation;

  DeviceLayout({
    required this.screenWidth,
    required this.screenHeight,
    required this.safeScreenWidth,
    required this.safeScreenHeight,
    required this.aspectRatio,
    required this.isPhone,
    required this.isTablet,
    required this.isHybrid,
    required this.isWide,
    required this.isTall,
    required this.orientation,
  });
}
