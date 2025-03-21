// /manager/gameLayoutManager.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../constants/layout_constants.dart';
import '../logic/logging_handler.dart';

class GameLayoutManager {
  static final GameLayoutManager _instance = GameLayoutManager._internal();

  factory GameLayoutManager() {
    return _instance;
  }

  DateTime? _lastUpdateTime;
  static const Duration minUpdateInterval = Duration(milliseconds: 100);

  GameLayoutManager._internal();

  // Screen size properties
  late double screenWidth;
  late double screenHeight;

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

  // Spell Words  Sizes
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
  late double spelledWordsVerticalPadding;

  late double buttonVerticalPadding;
  late double buttonHorizontalPadding;
  late double buttonBorderRadius;
  late double buttonBorderThickness;
  late double buttonTextOffset;
  late double buttonHeight;

  // Dialog Layout Properties
  late double dialogMaxHeight;
  late double dialogMinHeight;
  late double dialogMaxWidth;

  // flags
  late bool isWeb = false;

  // Square Styles
  static const int gridRows = 7;
  static const int gridCols = 7;
  static const double squareBorderRadius = 8.0;
  static const double squareBorderWidth = 2.0;
  static const double squareValueLeft = 5.0;
  static const double squareValueTop = 0.0;

  static const double baseSpelledWordsGridSpacing = 6.0;

  // Help Dialog Square Sizes
  static const double helpDialogSquareSize = 49.0; // Match GameGridComponent default
  static const double helpDialogSquareLetterSize = 20.0; // Typical letter size
  static const double helpDialogSquareValueSize = 10.0;

  static const double dialogMaxHeightPercentage = 0.8; // 80% of screen height
  static const double dialogMinHeightBase = 200.0;
  static const double dialogWidth = 500.0;

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
      // Apply text offset
      alignment: Alignment(0, buttonTextOffset / buttonVerticalPadding), // Normalize offset
    );
  }

  late TextStyle dialogTitleStyle;
  late TextStyle dialogContentStyle;
  late TextStyle dialogInputTitleStyle;
  late TextStyle dialogInputContentStyle;
  late TextStyle dialogContentHighLiteStyle;
  late TextStyle dialogLinkStyle;
  late TextStyle dialogErrorStyle;
  late TextStyle dialogSuccessStyle;

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
    final now = DateTime.now();

    // Only throttle in release mode
    bool shouldUpdate = true;
    assert(() {
      shouldUpdate = true;
      return true;
    }());

    if (!shouldUpdate && _lastUpdateTime != null && now.difference(_lastUpdateTime!) < minUpdateInterval) {
      return; // Skip if it's too soon (only in release mode)
    }
    _lastUpdateTime = now;

    // Get screen size from device and enforce minimum dimensions
    final mediaQuery = MediaQuery.of(context);
    isWeb = mediaQuery.size.width > 800;

    // Apply minimum dimensions based on platform
    double minWidth = isWeb ? GameConstants.minWindowWidth : GameConstants.minMobileWidth;
    double minHeight = isWeb ? GameConstants.minWindowHeight : GameConstants.minMobileHeight;

    screenWidth = mediaQuery.size.width.clamp(minWidth, double.infinity);
    screenHeight = mediaQuery.size.height.clamp(minHeight, double.infinity);

    // Calculate layout rows based on screen size
    infoBoxHeight = (screenHeight * GameConstants.infoBoxHeightPercentage).clamp(GameConstants.minInfoBoxHeight, 80.0);
    gameBoxHeight = screenHeight - infoBoxHeight;

    // Calculate the grid size based on the screen size
    double squareSizeFactor = isWeb ? 30 : 8;
    gridSquareSize = (screenWidth / squareSizeFactor).clamp(
      GameConstants.minGridSquareSize,
      GameConstants.maxGridSquareSize,
    );

    gridSpacing = isWeb ? GameConstants.baseGridGridSpacing : 2.0;
    gridWidthSize = (gridSquareSize * GameConstants.gridCols) + (gridSpacing * (GameConstants.gridCols - 1));
    gridHeightSize = (gridSquareSize * GameConstants.gridRows) + (gridSpacing * (GameConstants.gridRows - 1));

    // Initialize square value offsets
    squareValueOffsetLeft = squareValueLeft;
    squareValueOffsetTop = squareValueTop;

    // Calculate container sizes with minimum constraints
    gameContainerWidth = (gridWidthSize + (GameConstants.baseGridSideSpacing * 2)).clamp(
      gridWidthSize + GameConstants.minSideColumnWidth,
      double.infinity,
    );

    // Calculate the maximum allowed height for containers based on available space
    double maxContainerHeight = gameBoxHeight.clamp(GameConstants.minGameContainerHeight, double.infinity);

    // Calculate the minimum required height for the game container
    double minRequiredGameHeight =
        gridHeightSize +
        GameConstants.minTitleComponentHeight +
        GameConstants.minScoresComponentHeight +
        GameConstants.minMessageComponentHeight +
        GameConstants.minGameButtonsHeigth;

    // Set game container height to minimum required or available space, whichever is smaller
    gameContainerHeight = minRequiredGameHeight.clamp(GameConstants.minGameContainerHeight, maxContainerHeight);

    // Calculate side column widths with minimum constraints
    wildcardContainerWidth = ((screenWidth - gameContainerWidth) / 2).clamp(
      GameConstants.minSideColumnWidth,
      double.infinity,
    );
    spelledWordsContainerWidth = wildcardContainerWidth;

    // Set side column heights to match game container height
    wilcardsContainerHeight = gameContainerHeight;
    spelledWordsContainerHeight = gameContainerHeight;

    // Set spacing values
    spelledWordsGridSpacing = baseSpelledWordsGridSpacing;
    spelledWordsColumnSpacing = (screenWidth * 0.008).clamp(8.0, 24.0);
    sideSpacing = GameConstants.baseGridSideSpacing;

    // Calculate component heights with minimum constraints
    gameGridComponentHeight = gridHeightSize;
    gameGridComponentWidth = gridWidthSize;

    // Calculate remaining height after grid
    double remainingHeight = (gameContainerHeight - gameGridComponentHeight).clamp(0, double.infinity);

    // Calculate minimum total height needed for other components
    double minRequiredHeight =
        GameConstants.minTitleComponentHeight +
        GameConstants.minScoresComponentHeight +
        GameConstants.minMessageComponentHeight +
        GameConstants.minGameButtonsHeigth;

    // If remaining height is less than minimum required, adjust grid height
    if (remainingHeight < minRequiredHeight) {
      double deficit = minRequiredHeight - remainingHeight;
      gameGridComponentHeight = (gameContainerHeight - minRequiredHeight).clamp(
        GameConstants.minGridSquareSize * GameConstants.gridRows,
        double.infinity,
      );
      remainingHeight = gameContainerHeight - gameGridComponentHeight;
    }

    // Distribute remaining height to components
    double heightForFlexibleComponents = remainingHeight;

    // Title gets 15% of remaining space but not less than minimum
    gameTitleComponentHeight = (heightForFlexibleComponents * GameConstants.gameTitleComponentHeightPercentage).clamp(
      GameConstants.minTitleComponentHeight,
      double.infinity,
    );
    heightForFlexibleComponents -= gameTitleComponentHeight;

    // Scores gets 8% of original remaining space but not less than minimum
    gameScoresComponentHeight = (remainingHeight * GameConstants.gameScoresComponentHeightPercentage).clamp(
      GameConstants.minScoresComponentHeight,
      double.infinity,
    );
    heightForFlexibleComponents -= gameScoresComponentHeight;

    // Message matches scores height but not less than minimum
    gameMessageComponentHeight = gameScoresComponentHeight.clamp(
      GameConstants.minMessageComponentHeight,
      double.infinity,
    );
    heightForFlexibleComponents -= gameMessageComponentHeight;

    // Buttons get what's left, clamped between min and max
    gameButtonsComponentHeight = heightForFlexibleComponents.clamp(
      GameConstants.minGameButtonsHeigth,
      GameConstants.maxGameButtonsHeight,
    );

    // Verify total height
    double totalHeight =
        gameGridComponentHeight +
        gameTitleComponentHeight +
        gameScoresComponentHeight +
        gameMessageComponentHeight +
        gameButtonsComponentHeight;

    // If still over height, reduce proportionally
    if (totalHeight > gameContainerHeight) {
      double excess = totalHeight - gameContainerHeight;
      double reductionFactor = gameContainerHeight / totalHeight;

      // Reduce all components except grid
      gameTitleComponentHeight *= reductionFactor;
      gameScoresComponentHeight *= reductionFactor;
      gameMessageComponentHeight *= reductionFactor;
      gameButtonsComponentHeight *= reductionFactor;
    }

    // Set component widths
    gameTitleComponentWidth = gameContainerWidth;
    gameScoresComponentWidth = gameContainerWidth;
    gameGridComponentWidth = gameContainerWidth;
    gameMessageComponentWidth = gameContainerWidth;
    gameButtonsComponentWidth = gameContainerWidth;

    // Calculate font sizes based on container dimensions
    titleFontSize = (gameContainerWidth * 0.0255).clamp(24.0, 56.0);
    sloganFontSize = (gameContainerWidth * 0.013).clamp(16.0, 28.0);
    scoreFontSize = (gameContainerWidth * 0.0106).clamp(14.0, 28.0);
    spelledWordsFontSize = (gameContainerWidth * 0.01059).clamp(12.0, 24.0);
    squareLetterFontSize = (gridSquareSize * 0.42).clamp(12.0, 56.0);
    squareValueFontSize = (gridSquareSize * 0.25).clamp(8.0, 38.0);
    spelledWordsTitleFontSize = (gameContainerWidth * 0.01059).clamp(12.0, 24.0);
    spelledWordsVerticalPadding = (screenWidth * 0.0006).clamp(0.5, 4.0);

    // Calculate dialog font sizes
    dialogTitleFontSize = (gameContainerWidth * 0.020).clamp(18.0, 32.0);
    dialogBodyFontSize = (gameContainerWidth * 0.016).clamp(14.0, 24.0);
    dialogInputTitleSize = dialogBodyFontSize;
    dialogInputFontSize = dialogBodyFontSize;

    // Calculate button styles
    buttonFontSize = (gameContainerWidth * 0.0108).clamp(16.0, 32.0);
    buttonVerticalPadding = (screenHeight * 0.019).clamp(12.0, 28.0);
    buttonHorizontalPadding = (gameContainerWidth * 0.015).clamp(18.0, 36.0);
    buttonBorderRadius = (buttonFontSize * 1.6).clamp(12.0, 38.0);
    buttonBorderThickness = (gameContainerWidth * 0.002).clamp(1.0, 3.0);
    buttonTextOffset = -(buttonVerticalPadding * 0.070);
    buttonHeight = buttonFontSize + (2 * buttonVerticalPadding) + (2 * buttonBorderThickness);

    // Calculate dialog dimensions
    dialogMaxHeight = screenHeight * dialogMaxHeightPercentage;
    dialogMinHeight = dialogMinHeightBase.clamp(dialogMinHeightBase, dialogMaxHeight);
    dialogMaxWidth = dialogWidth;

    // Initialize font styles
    initializeFontStyles();

    LogService.logInfo('Screen Resolution: $screenWidth x $screenHeight, isWeb: $isWeb');
    LogService.logInfo('Grid Size: $gridWidthSize w x $gridHeightSize h');
    LogService.logInfo(
      'Game Column Heights: Title: $gameTitleComponentHeight, Scores: $gameScoresComponentHeight, Grid: $gameGridComponentHeight, Buttons: $gameButtonsComponentHeight',
    );
  }
}
