// Centralized styles for the app
import 'package:flutter/material.dart';
import '/logic/layout_calculator.dart';

class AppStyles {
  // Wordle-inspired colors
  static const Color backgroundColor = Color(0xFF121213); // Dark gray background
  static const Color appBarColor = Color(0xFF3A3A3C); // Lighter gray for app bar
  static const Color textColor = Color(0xFFFFFFFF); // White text
  static const Color primaryColor = Color(0xFF538D4E); // Green for correct (also primary)

  // Title Styles
  static const double headerFontSize = 36.0; // Example size
  static const Color headerTextColor = Color.fromARGB(255, 3, 240, 23);

  // Square colors
  static const Color usedMultipleColor = Color(0xFF818384); // Gray for 2+ uses
  static const Color normalvalueTextColor = Color.fromARGB(230, 4, 190, 29); // Light gray for values
  static const Color normalletterTextColor = Color.fromARGB(209, 255, 255, 255); // White for letters
  static const Color usedOnceTextColor = Color(0xFFB4B4B6); // Lighter gray for 1 use
  static const Color usedLetterValueTextColor = Color.fromARGB(255, 180, 71, 57); // Gray for used values
  static const Color normalSquareColor = Color(0xFF1F1F21); // Base square color
  static const Color selectedSquareColor = Color(0xFF3A3A3C); // Selected square color
  static const Color usedSquareColor = Color(0xFF818384); // Used square color
  static const Color stackedSquareColor = Color(0xFF3A3A3C); // Stacked square color

  // Grid layout constants
  static const double baseSquareSize = 60.0; // Size of each letter square
  static const double baseGridSpacing = 4.0; // Gap between squares
  static const double baseLetterFontSize = 24.0; // Font size for the letter
  static const double baseValueFontSize = 10.0; // Font size for the value
  static const double baseSideSpacing = 20.0;
  static const double baseSideColumnWidth = 300.0; // Width of side columns
  static const double baseWordColumnWidth = 100.0; // Width of word columns
  static const double baseWordColumnHeight = 480.0; // Height of word columns
  static const double basedSpelledWordsGridSpacing = 6.0; // Spacing between columns
  static const double baseButtonFontSize = 16.0;
  static const double baseButtonVerticalPadding = 18.0;
  static const double baseButtonHorizontalPadding = 24.0;
  static const double baseButtonBorderRadius = 20.0;
  static const double baseButtonBorderThickness = 2.0;

  static const int gridRows = 7; // 7x7 grid
  static const int gridCols = 7;

  // Spelled Words Styles
  static const double spelledWordsTitleFontSize = 15.0; // Title for right column
  static const Color spelledWordsTitleColor = Color(0xFFFFFFFF); // White for title
  static const double spelledWordsFontSize = 15.0; // Size for word list
  static const Color spelledWordsTextColor = Color.fromARGB(255, 251, 251, 255); // Light gray for words
  static const double spelledWordsColumnWidth = 100.0; // Min width per column (was minColumnWidth)
  static const double spelledWordsVerticalPadding = 0.5; // Vertical padding between words
  static const double spelledWordsScoreRightPadding = 16.0; // Right padding for score title
  static const Color spelledWordsOuterBorderColor = Colors.green; // Outer border
  static const Color spelledWordsHeaderBorderColor = Colors.yellow; // Header boxes
  static const Color spelledWordsColumnBorderColor = Colors.cyan; // Word columns
  static const double spelledWordsBorderWidth = .5; // Border thickness

  // Dialog Styles
  static const double dialogWidth = 400.0; // Wider
  static const double dialogHeight = 550.0; // Taller
  static const Color dialogBackgroundColor = backgroundColor; // 0xFF121213
  static const Color dialogBorderColor = Colors.white;
  static const double dialogBorderWidth = 2.0;
  static const double dialogBorderRadius = 8.0;
  static const double dialogPadding = 16.0;
  static const double dialogButtonPadding = 8.0;

  // Button Base Styles

  // Button Styles
  static ButtonStyle buttonStyle(BuildContext context) {
    final sizes = LayoutCalculator.calculateSizes(context);
    return ElevatedButton.styleFrom(
      backgroundColor: normalSquareColor, // 0xFF1F1F21
      foregroundColor: const Color.fromARGB(255, 221, 220, 220), // White text
      padding: EdgeInsets.symmetric(
        horizontal: sizes['buttonHorizontalPadding']!,
        vertical: sizes['buttonVerticalPadding']!,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sizes['buttonBorderRadius']!),
        side: const BorderSide(color: Colors.white, width: 2.5),
      ),
      textStyle: TextStyle(fontSize: sizes['buttonFontSize'], fontWeight: FontWeight.bold),
    );
  }

  static const TextStyle dialogTitleStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: Color.fromARGB(255, 255, 255, 255), // Brighter white
  );
  static const TextStyle dialogContentStyle = TextStyle(
    fontSize: 14.0,
    color: Color.fromARGB(255, 240, 240, 240), // Slightly off-white for contrast
  );
  static const TextStyle dialogCloseStyle = TextStyle(
    fontSize: 14.0,
    color: Color.fromARGB(255, 200, 200, 200), // Light grey for button
  );

  // Define the app theme
  static ThemeData get appTheme => ThemeData(
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: appBarColor,
      titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: textColor, fontSize: 16),
      bodyLarge: TextStyle(color: textColor, fontSize: 20),
    ),
    primaryColor: primaryColor,
  );
}
