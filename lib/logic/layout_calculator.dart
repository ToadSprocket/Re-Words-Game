import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class LayoutCalculator {
  static Map<String, double> calculateSizes(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = MediaQuery.of(context).size.width > 800;

    double squareSize = AppStyles.baseSquareSize;
    double letterFontSize = AppStyles.baseLetterFontSize;
    double valueFontSize = AppStyles.baseValueFontSize;
    double gridSpacing = AppStyles.baseGridSpacing;
    double sideSpacing = AppStyles.baseSideSpacing;
    double sideColumnWidth = AppStyles.baseSideColumnWidth;
    double spelledWordsGridSpacing = AppStyles.basedSpelledWordsGridSpacing;

    if (isWeb) {
      squareSize = screenWidth / 30;
      squareSize = squareSize.clamp(40.0, 100.0);
      gridSpacing = 4.0;
      sideSpacing = 30.0;
      sideColumnWidth = 300.0;
    } else {
      squareSize = screenWidth / 8;
      squareSize = squareSize.clamp(40.0, 80.0);
      gridSpacing = 2.0;
      sideSpacing = 20.0;
      sideColumnWidth = 150.0;
    }

    double gridSize = (squareSize * AppStyles.gridCols) + (gridSpacing * (AppStyles.gridCols - 1));
    letterFontSize = squareSize * 0.5;
    valueFontSize = squareSize * 0.2;

    const double charWidthFactor = 0.4;
    const double wordPadding = 16.0;
    double wordColumnWidth = (AppStyles.spelledWordsFontSize * charWidthFactor * 12) + wordPadding;

    // Word column height: Exact grid height minus header with buffer
    double headerHeight =
        AppStyles.spelledWordsTitleFontSize + // 18.0
        (AppStyles.spelledWordsTitleFontSize * 0.2) + // ~3.6
        gridSpacing + // 2.0 or 4.0
        8.0; // Top padding
    double wordColumnHeight = gridSize - headerHeight - 10.0; // Extra buffer to match visible area

    return {
      'squareSize': squareSize,
      'letterFontSize': letterFontSize,
      'valueFontSize': valueFontSize,
      'gridSize': gridSize,
      'gridSpacing': gridSpacing,
      'sideSpacing': sideSpacing,
      'sideColumnWidth': sideColumnWidth,
      'wordColumnWidth': wordColumnWidth,
      'wordColumnHeight': wordColumnHeight,
      'spelledWordsGridSpacing': spelledWordsGridSpacing,
    };
  }
}
