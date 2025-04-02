// /manager/gameLayoutManager.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import '../constants/layout_constants.dart';
import '../styles/app_styles.dart';
import '../logic/logging_handler.dart';

class GameLayoutManager {
  static final GameLayoutManager _instance = GameLayoutManager._internal();

  factory GameLayoutManager() {
    return _instance;
  }

  DateTime? _lastUpdateTime;
  static const Duration minUpdateInterval = Duration(milliseconds: 100);
  ValueNotifier<List<String>>? spelledWordsNotifier;

  GameLayoutManager._internal() {
    isWeb = kIsWeb;
  }

  // Layout constants
  static const double NARROW_LAYOUT_THRESHOLD = 900.0;

  // Grid constants
  static const int gridRows = 7;
  static const int gridCols = 7;

  // Square style constants
  static const double squareBorderRadius = 8.0;
  static const double squareBorderWidth = 2.0;
  static const double squareValueLeft = 5.0;
  static const double squareValueTop = 0.0;

  // Spacing constants
  static const double baseSpelledWordsGridSpacing = 6.0;

  // Help dialog constants
  static const double helpDialogSquareSize = 44.0;
  static const double helpDialogSquareLetterSize = 26.0;
  static const double helpDialogSquareValueSize = 18.0;

  // Dialog constants
  static const double dialogMaxWidthPercentage = 0.85;
  static const double dialogMaxHeightPercentage = 0.9;
  static const double dialogMinHeightBase = 200.0;
  static const double dialogWidth = 600.0;
  static const double dialogMaxWidthLimit = 600.0;

  // Screen properties
  late double screenWidth;
  late double screenHeight;
  double oldScreenWidth = 0;
  double oldScreenHeight = 0;
  late bool isWeb;

  // Layout properties
  late double infoBoxHeight;
  late double gameBoxHeight;
  late double wilcardsContainerHeight;
  late double wildcardContainerWidth;
  late double gameContainerHeight;
  late double gameContainerWidth;
  late double spelledWordsContainerHeight;
  late double spelledWordsContainerWidth;

  // Grid properties
  late double gridSquareSize;
  late double gridSpacing;
  late double gridWidthSize;
  late double gridHeightSize;
  late double sideSpacing;
  late double squareValueOffsetLeft;
  late double squareValueOffsetTop;

  // Game Container Column Sizes
  late double gameTitleComponentWidth;
  late double gameTitleComponentHeight;
  late double gameScoresComponentWidth;
  late double gameScoresComponentHeight;
  late double gameGridComponentWidth;
  late double gameGridComponentHeight;
  late double gameMessageComponentWidth;
  late double gameMessageComponentHeight;
  late double gameButtonsComponentWidth;
  late double gameButtonsComponentHeight;

  // Spell Words Sizes
  late double spelledWordsGridSpacing;
  late double spelledWordsColumnSpacing;

  // Font Sizes
  late double titleFontSize;
  late double sloganFontSize;
  late double scoreFontSize;
  late double buttonFontSize;
  late double dialogTitleFontSize;
  late double dialogBodyFontSize;
  late double dialogInputTitleSize;
  late double dialogInputFontSize;
  late double spelledWordsFontSize;
  late double squareLetterFontSize;
  late double squareValueFontSize;
  late double spelledWordsTitleFontSize;
  late double gameMessageFontSize;
  late double spelledWordsVerticalPadding;

  // Button properties
  late double buttonVerticalPadding;
  late double buttonHorizontalPadding;
  late double buttonBorderRadius;
  late double buttonBorderThickness;
  late double buttonTextOffset;
  late double buttonHeight;

  // Dialog Layout Properties
  late double dialogMaxWidth;
  late double dialogMaxHeight;
  late double dialogMinHeight;

  // Text styles
  late TextStyle titleStyle;
  late TextStyle messageStyle;
  late TextStyle scoreStyle;
  late TextStyle spelledWordStyle;
  late TextStyle dialogTitleStyle;
  late TextStyle dialogContentStyle;
  late TextStyle dialogInputTitleStyle;
  late TextStyle dialogInputContentStyle;
  late TextStyle dialogContentHighLiteStyle;
  late TextStyle dialogLinkStyle;
  late TextStyle dialogErrorStyle;
  late TextStyle dialogSuccessStyle;

  // Ticker properties
  late double tickerWidthFactor;
  late double tickerHeight;
  late double tickerBorderWidth;
  late double tickerFontSize;
  late double tickerTitleFontSize;
  late double tickerPopupWidth;
  late double tickerPopupHeight;
  late double tickerPopupCrossSpacing;
  late double tickerPopupMainSpacing;

  // Border properties
  late double componentBorderThickness;
  late double componentBorderRadius;

  late int spelledWordsColumnCount = 0;
  late double spelledWordsColumnWidth = 0;
  // Add new values to track desired widths
  double? desiredSpelledWordsWidth;
  double? desiredWildcardWidth;

  ButtonStyle buttonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(61, 79, 185, 69),
      foregroundColor: const Color.fromARGB(255, 236, 232, 232),
      padding: EdgeInsets.symmetric(horizontal: buttonHorizontalPadding, vertical: buttonVerticalPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        side: BorderSide(color: const Color.fromARGB(255, 236, 232, 232), width: buttonBorderThickness),
      ),
      textStyle: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.bold),
      alignment: Alignment(0, buttonTextOffset / buttonVerticalPadding),
    );
  }

  void initializeFontStyles() {
    dialogTitleStyle = TextStyle(
      fontSize: dialogTitleFontSize,
      fontWeight: FontWeight.bold,
      color: Color.fromARGB(255, 255, 255, 255),
    );

    dialogContentStyle = TextStyle(fontSize: dialogBodyFontSize, color: Color.fromARGB(211, 240, 240, 240));
    dialogContentHighLiteStyle = TextStyle(fontSize: dialogBodyFontSize, color: Color.fromARGB(230, 4, 190, 29));
    dialogInputTitleStyle = TextStyle(fontSize: dialogInputFontSize, color: Color.fromARGB(211, 240, 240, 240));
    dialogInputContentStyle = TextStyle(fontSize: dialogInputFontSize, color: Color.fromARGB(211, 240, 240, 240));
    dialogLinkStyle = TextStyle(
      fontSize: dialogBodyFontSize,
      color: Color.fromARGB(255, 93, 174, 240),
      decoration: TextDecoration.underline,
    );
    dialogErrorStyle = TextStyle(fontSize: dialogBodyFontSize, color: Colors.red, fontWeight: FontWeight.bold);
    dialogSuccessStyle = TextStyle(
      fontSize: dialogBodyFontSize,
      color: Color.fromARGB(255, 54, 244, 54),
      fontWeight: FontWeight.bold,
    );
  }

  void calculateLayoutSizes(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    isWeb = kIsWeb;

    if (oldScreenWidth == 0 && oldScreenHeight == 0) {
      oldScreenWidth = screenWidth;
      oldScreenHeight = screenHeight;
    } else if (oldScreenWidth == screenWidth && oldScreenHeight == screenHeight) {
      return;
    }

    // Determine if we should use narrow layout
    bool isNarrowLayout = screenWidth < NARROW_LAYOUT_THRESHOLD;

    // Calculate border properties
    componentBorderThickness = (screenWidth * 0.002).clamp(1.0, 2.0);
    componentBorderRadius = 8.0;

    // Calculate grid size first
    if (isNarrowLayout) {
      gridSquareSize = (screenWidth / 8.5).clamp(40.0, 90.0);
      gridSpacing = 3.0;
    } else {
      // For wide layout, calculate grid size based on both screen dimensions
      // Target the grid to be roughly 50-60% of screen height
      double targetGridHeight = screenHeight * 0.55; // 55% of screen height
      double targetGridWidth = screenWidth * 0.4; // 40% of screen width

      // Calculate potential square sizes based on height and width
      double heightBasedSquare = (targetGridHeight / (GameConstants.gridRows + 1)) * 0.95; // 95% to account for spacing
      double widthBasedSquare = (targetGridWidth / (GameConstants.gridCols + 1)) * 0.95; // 95% to account for spacing

      // Use the smaller of the two to ensure grid fits both dimensions
      gridSquareSize = min(heightBasedSquare, widthBasedSquare).clamp(60.0, 85.0);
      gridSpacing = gridSquareSize * 0.06; // Spacing proportional to square size
    }

    // Calculate grid dimensions
    gridWidthSize = (gridSquareSize * GameConstants.gridCols) + (gridSpacing * (GameConstants.gridCols - 1));
    gridHeightSize = (gridSquareSize * GameConstants.gridRows) + (gridSpacing * (GameConstants.gridRows - 1));

    // Store original grid width for later use
    double originalGridWidth = gridWidthSize;

    // Initialize square value offsets
    squareValueOffsetLeft = squareValueLeft;
    squareValueOffsetTop = squareValueTop;

    // Calculate container sizes - use full width for narrow layout
    gameContainerWidth =
        isNarrowLayout
            ? screenWidth - (GameConstants.baseGridSideSpacing * 2)
            : gridWidthSize + (GameConstants.baseGridSideSpacing * 2);

    // Store original container width for later use
    double originalContainerWidth = gameContainerWidth;

    // Adjust grid size if container is wider in narrow layout
    if (isNarrowLayout && gridWidthSize < gameContainerWidth - (GameConstants.baseGridSideSpacing * 2)) {
      // Recalculate grid square size to better fill the container width
      gridSquareSize = ((gameContainerWidth - (GameConstants.baseGridSideSpacing * 2)) /
              (GameConstants.gridCols + (GameConstants.gridCols - 1) * (gridSpacing / gridSquareSize)))
          .clamp(
            40.0, // Minimum for narrow layout
            120.0, // Maximum for narrow layout
          );
      // Update grid dimensions with new square size
      gridWidthSize = (gridSquareSize * GameConstants.gridCols) + (gridSpacing * (GameConstants.gridCols - 1));
      gridHeightSize = (gridSquareSize * GameConstants.gridRows) + (gridSpacing * (GameConstants.gridRows - 1));
    }

    // Calculate font sizes based on layout mode
    titleFontSize = (screenWidth * (isNarrowLayout ? 0.048 : 0.027)).clamp(24.0, 44.0);

    sloganFontSize = (screenWidth * (isNarrowLayout ? 0.025 : 0.015)).clamp(14.0, 24.0);

    scoreFontSize = (screenWidth * (isNarrowLayout ? 0.032 : 0.0145)).clamp(
      isNarrowLayout ? 15.0 : 12.0, // Minimum values
      isNarrowLayout ? 24.0 : 20.0, // Maximum values
    );

    gameMessageFontSize = (screenWidth * (isNarrowLayout ? 0.031 : 0.018)).clamp(
      isNarrowLayout ? 16.0 : 14.0,
      isNarrowLayout ? 24.0 : 20.0,
    );

    spelledWordsFontSize = (screenWidth * (isNarrowLayout ? 0.025 : 0.014)).clamp(
      isNarrowLayout ? 14.0 : 12.0,
      isNarrowLayout ? 20.0 : 20.0,
    );

    buttonFontSize = (screenWidth * (isNarrowLayout ? 0.028 : 0.018)).clamp(
      isNarrowLayout ? 16.0 : 14.0,
      isNarrowLayout ? 24.0 : 20.0,
    );

    dialogTitleFontSize = (screenWidth * (isNarrowLayout ? 0.035 : 0.022)).clamp(
      isNarrowLayout ? 20.0 : 18.0,
      isNarrowLayout ? 28.0 : 24.0,
    );

    dialogBodyFontSize = (screenWidth * (isNarrowLayout ? 0.025 : 0.016)).clamp(
      isNarrowLayout ? 14.0 : 12.0,
      isNarrowLayout ? 20.0 : 16.0,
    );

    dialogInputFontSize = dialogBodyFontSize;
    dialogInputTitleSize = dialogBodyFontSize;

    squareLetterFontSize = (gridSquareSize * (isNarrowLayout ? 0.45 : 0.42)).clamp(
      isNarrowLayout ? 24.0 : 15.0,
      isNarrowLayout ? 36.0 : 32.0,
    );

    squareValueFontSize = (gridSquareSize * (isNarrowLayout ? 0.25 : 0.21)).clamp(
      isNarrowLayout ? 12.0 : 8.0,
      isNarrowLayout ? 20.0 : 16.0,
    );

    spelledWordsTitleFontSize = (screenWidth * (isNarrowLayout ? 0.025 : 0.016)).clamp(
      isNarrowLayout ? 14.0 : 12.0,
      isNarrowLayout ? 20.0 : 16.0,
    );

    // Calculate component heights based on layout mode
    if (isNarrowLayout) {
      // Narrow layout - more conservative heights
      gameTitleComponentHeight = (screenHeight * 0.08).clamp(50.0, 100.0);
      gameMessageComponentHeight = (screenHeight * 0.06).clamp(40.0, 50.0);
      gameScoresComponentHeight = (screenHeight * 0.06).clamp(40.0, 50.0);
      gameButtonsComponentHeight = (screenHeight * 0.06).clamp(40.0, 50.0);
    } else {
      // Wide layout - calculate based on both dimensions
      // Title can be taller in wide layout
      double baseHeight = min(screenHeight * 0.13, screenWidth * 0.08) + 4;
      gameTitleComponentHeight = baseHeight.clamp(50.0, 120.0);

      // Message area scales with both dimensions but stays compact
      baseHeight = min(screenHeight * 0.07, screenWidth * 0.04);
      gameMessageComponentHeight = baseHeight.clamp(45.0, 70.0);

      // Scores area similar to message
      baseHeight = min(screenHeight * 0.07, screenWidth * 0.04);
      gameScoresComponentHeight = baseHeight.clamp(45.0, 70.0);

      // Buttons area needs enough space for interaction
      baseHeight = min(screenHeight * 0.07, screenWidth * 0.04);
      gameButtonsComponentHeight = baseHeight.clamp(45.0, 70.0);
    }

    infoBoxHeight =
        isNarrowLayout
            ? (screenHeight * 0.06).clamp(40.0, 60.0) // 6% of screen height for narrow layout
            : (screenHeight * 0.057).clamp(35.0, 60.0) + 4;

    // Calculate available height after fixed components
    double totalFixedHeight =
        gameTitleComponentHeight + gameMessageComponentHeight + gameScoresComponentHeight + gameButtonsComponentHeight;

    // Calculate the available height for the main game area
    double availableHeight = screenHeight - infoBoxHeight;

    // Calculate game box height (main game area)
    gameBoxHeight = screenHeight - infoBoxHeight;

    // Calculate spacing values first
    spelledWordsGridSpacing = baseSpelledWordsGridSpacing;
    spelledWordsColumnSpacing = (screenWidth * 0.008).clamp(8.0, 24.0);
    spelledWordsVerticalPadding = (screenWidth * 0.002).clamp(0.5, 4.0);
    sideSpacing = GameConstants.baseGridSideSpacing;

    // Calculate the remaining space after the game container
    double remainingSpace = screenWidth - originalContainerWidth;

    // Calculate side container widths to ensure proper centering
    if (desiredSpelledWordsWidth != null && desiredWildcardWidth != null) {
      // Use the desired widths if they are set
      spelledWordsContainerWidth = desiredSpelledWordsWidth!;
      wildcardContainerWidth = desiredWildcardWidth!;
      // Clear the desired widths after using them
      desiredSpelledWordsWidth = null;
      desiredWildcardWidth = null;
      LogService.logInfo('Using desired widths for containers');
    } else {
      // Normal calculation if no desired widths are set
      wildcardContainerWidth = remainingSpace / 2; // Equal distribution of remaining space
      spelledWordsContainerWidth = remainingSpace / 2; // Equal distribution of remaining space

      // Ensure minimum width for spelled words container
      double minSpelledWordsWidth = spelledWordsFontSize * 7 * 0.65 + (spelledWordsGridSpacing * 2);
      if (spelledWordsContainerWidth < minSpelledWordsWidth) {
        spelledWordsContainerWidth = minSpelledWordsWidth;
        wildcardContainerWidth = remainingSpace - spelledWordsContainerWidth;
      }
    }

    // Distribute remaining height based on layout
    if (isNarrowLayout) {
      wilcardsContainerHeight = (availableHeight * 0.15).clamp(80.0, 120.0);
      spelledWordsContainerHeight = (availableHeight * 0.25).clamp(120.0, 200.0);
      gameContainerHeight = availableHeight - wilcardsContainerHeight - spelledWordsContainerHeight;
      spelledWordsContainerWidth = gameContainerWidth;
    } else {
      // In wide layout, all columns get the exact available height
      gameContainerHeight = availableHeight;
      wilcardsContainerHeight = availableHeight;
      spelledWordsContainerHeight = availableHeight;
    }

    // Set component widths - use original grid width for grid component
    gameTitleComponentWidth = gameContainerWidth;
    gameScoresComponentWidth = gameContainerWidth;
    gameGridComponentWidth = originalGridWidth; // Use original grid width
    gameMessageComponentWidth = gameContainerWidth;
    gameButtonsComponentWidth = gameContainerWidth;

    // Calculate button dimensions
    buttonVerticalPadding = (screenHeight * (isNarrowLayout ? 0.012 : 0.016)).clamp(11.0, 28.0);
    buttonHorizontalPadding = (screenWidth * (isNarrowLayout ? 0.012 : 0.016)).clamp(18.0, 38.0);
    buttonBorderRadius = (buttonFontSize * 1.6).clamp(12.0, 38.0);
    buttonBorderThickness = (screenWidth * 0.002).clamp(1.0, 3.0);
    buttonTextOffset = -(buttonVerticalPadding * 0.070);
    buttonHeight = buttonFontSize + (2 * buttonVerticalPadding) + (2 * buttonBorderThickness);

    // Calculate dialog dimensions
    dialogMaxWidth = min(screenWidth * dialogMaxWidthPercentage, dialogMaxWidthLimit);
    dialogMaxHeight = screenHeight * dialogMaxHeightPercentage;
    dialogMinHeight = dialogMinHeightBase;

    // Calculate ticker dimensions and properties
    tickerWidthFactor = 1.0;
    tickerHeight = (screenHeight * (isNarrowLayout ? 0.056 : 0.06)).clamp(43.0, 60.0);
    tickerBorderWidth = (screenWidth * 0.001).clamp(1.0, 2.0);
    tickerFontSize = (screenWidth * (isNarrowLayout ? 0.024 : 0.016)).clamp(14.0, 20.0);
    tickerTitleFontSize = tickerFontSize;

    // Popup dimensions
    tickerPopupWidth = (screenWidth * 0.8).clamp(400.0, 600.0);
    tickerPopupHeight = (screenHeight * 0.8).clamp(600.0, 800.0);
    tickerPopupCrossSpacing = 0.1;
    tickerPopupMainSpacing = 0.1;

    // Initialize text styles
    initializeFontStyles();

    // Update component text styles
    titleStyle = TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: Colors.white);

    messageStyle = TextStyle(fontSize: sloganFontSize, fontWeight: FontWeight.normal, color: Colors.white);

    scoreStyle = TextStyle(fontSize: scoreFontSize, fontWeight: FontWeight.bold, color: Colors.white);

    spelledWordStyle = TextStyle(fontSize: spelledWordsFontSize, fontWeight: FontWeight.normal, color: Colors.white);

    var gameLayout = isNarrowLayout ? 'Narrow' : 'Wide';

    LogService.logInfo('Screen Width: $screenWidth, Screen Height: $screenHeight, Game Layout: $gameLayout');
  }

  bool calculateSpelledWordsLayout(int totalColumns, double totalWidth) {
    var changed = false;
    LogService.logInfo('Total Columns: $totalColumns, Total Width: $totalWidth');

    // Calculate minimum widths
    double minWildcardWidth = gridSquareSize + 4; // Minimum width for wildcard container
    double minSpelledWordsWidth =
        spelledWordsFontSize * 7 * 0.65 + (spelledWordsGridSpacing * 2); // Minimum width for spelled words

    // Calculate average column width
    double averageColumnWidth = totalWidth / totalColumns;
    double actualWidth = totalWidth + (spelledWordsColumnSpacing * (totalColumns));
    double neededSpace = minSpelledWordsWidth + 10;

    // If we don't have desired widths, set them to the current widths
    if (desiredSpelledWordsWidth == null) {
      desiredSpelledWordsWidth = spelledWordsContainerWidth;
      desiredWildcardWidth = wildcardContainerWidth;
    }

    if (actualWidth + 10 > desiredSpelledWordsWidth! && (desiredWildcardWidth! - neededSpace) > minWildcardWidth) {
      desiredSpelledWordsWidth = desiredSpelledWordsWidth! + neededSpace;
      desiredWildcardWidth = desiredWildcardWidth! - neededSpace;
      changed = true;
    } else if (actualWidth < desiredSpelledWordsWidth! && (desiredWildcardWidth! + neededSpace) < minWildcardWidth) {
      desiredSpelledWordsWidth = desiredSpelledWordsWidth! - neededSpace;
      desiredWildcardWidth = desiredWildcardWidth! + neededSpace;
      changed = true;
    }

    return changed;
  }
}
