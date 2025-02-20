// Calculates layout sizes based on platform and screen size
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class LayoutCalculator {
  // Calculate sizes based on BuildContext
  static Map<String, double> calculateSizes(BuildContext context) {
    // Get screen info
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = MediaQuery.of(context).size.width > 800; // Rough web threshold

    // Base sizes from AppStyles
    double squareSize = AppStyles.baseSquareSize;
    double letterFontSize = AppStyles.baseLetterFontSize;
    double valueFontSize = AppStyles.baseValueFontSize;
    double gridSpacing = AppStyles.baseGridSpacing;

    // Adjust squareSize based on platform and screen width
    if (isWeb) {
      // Web: Larger squares, capped
      squareSize = screenWidth / 30; // Bigger divisor = smaller squares
      squareSize = squareSize.clamp(40.0, 100.0); // Min 60, max 100
      gridSpacing = 4.0; // Consistent spacing for web
    } else {
      // Mobile: Smaller, scaled to screen
      squareSize = screenWidth / 8; // Smaller divisor = larger relative to screen
      squareSize = squareSize.clamp(40.0, 80.0); // Min 40, max 80
      gridSpacing = 2.0; // Tighter spacing for mobile
    }

    // Scale fonts proportionally
    letterFontSize = squareSize * 0.5; // 40% of squareSize (e.g., 24 at 60)
    valueFontSize = squareSize * 0.2; // 20% of squareSize (e.g., 12 at 60)

    // Calculate grid size
    double gridSize = (squareSize * AppStyles.gridCols) + (gridSpacing * (AppStyles.gridCols - 1));

    return {'squareSize': squareSize, 'letterFontSize': letterFontSize, 'valueFontSize': valueFontSize, 'gridSize': gridSize, 'gridSpacing': gridSpacing};
  }
}
