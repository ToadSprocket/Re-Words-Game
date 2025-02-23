// logic/layout_calculator.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class LayoutCalculator {
  static Map<String, dynamic> calculateSizes(BuildContext context) {
    // Changed to dynamic for bool
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

    print('Screen width: $screenWidth');
    print('isWeb: $isWeb');

    double squareSize = AppStyles.baseSquareSize;
    double squareLetterSize = AppStyles.baseLetterFontSize;
    double squareValueSize = AppStyles.baseValueFontSize;
    double gridSpacing = AppStyles.baseGridSpacing;
    double sideSpacing = AppStyles.baseSideSpacing;
    double sideColumnWidth = AppStyles.baseSideColumnWidth;
    double spelledWordsGridSpacing = AppStyles.basedSpelledWordsGridSpacing;
    double buttonFontSize = AppStyles.baseButtonFontSize;
    double buttonVerticalPadding = AppStyles.baseButtonVerticalPadding;
    double buttonHorizontalPadding = AppStyles.baseButtonHorizontalPadding;
    double buttonBorderRadius = AppStyles.baseButtonBorderRadius;
    double buttonBorderThickness = AppStyles.baseButtonBorderThickness;

    if (isWeb) {
      squareSize = screenWidth / 30;
      squareSize = squareSize.clamp(40.0, 100.0);
      gridSpacing = 4.0;
      sideSpacing = 30.0;
      sideColumnWidth = 350.0;
    } else {
      squareSize = screenWidth / 8;
      squareSize = squareSize.clamp(40.0, 80.0);
      gridSpacing = 2.0;
      sideSpacing = 20.0;
      sideColumnWidth = 155.0;
      buttonFontSize = 16.0;
      buttonVerticalPadding = 14.0;
      buttonHorizontalPadding = 20.0;
      buttonBorderRadius = 16.0;
    }

    double gridSize = (squareSize * AppStyles.gridCols) + (gridSpacing * (AppStyles.gridCols - 1));
    squareLetterSize = squareSize * 0.49;
    squareValueSize = squareSize * 0.22;

    const double charWidthFactor = 0.48;
    const double wordPadding = 16.0;
    double wordColumnWidth = (AppStyles.spelledWordsFontSize * charWidthFactor * 13.2) + wordPadding;
    double wordColumnHeight = gridSize;

    return {
      'squareSize': squareSize,
      'squareLetterSize': squareLetterSize,
      'squareValueSize': squareValueSize,
      'gridSize': gridSize,
      'gridSpacing': gridSpacing,
      'sideSpacing': sideSpacing,
      'sideColumnWidth': sideColumnWidth,
      'wordColumnWidth': wordColumnWidth,
      'wordColumnHeight': wordColumnHeight,
      'spelledWordsGridSpacing': spelledWordsGridSpacing,
      'buttonFontSize': buttonFontSize,
      'buttonVerticalPadding': buttonVerticalPadding,
      'buttonHorizontalPadding': buttonHorizontalPadding,
      'buttonBorderRadius': buttonBorderRadius,
      'buttonBorderThickness': buttonBorderThickness,
      'isWeb': isWeb, // Added
    };
  }
}
