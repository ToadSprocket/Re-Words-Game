// Centralized styles for the app
import 'package:flutter/material.dart';

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
  static const int gridRows = 7; // 7x7 grid
  static const int gridCols = 7;

  // Define the app theme
  static ThemeData get appTheme => ThemeData(
    // Set the main background color
    scaffoldBackgroundColor: backgroundColor,
    // App bar styling
    appBarTheme: const AppBarTheme(backgroundColor: appBarColor, titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
    // Text styling
    textTheme: const TextTheme(bodyMedium: TextStyle(color: textColor, fontSize: 16), bodyLarge: TextStyle(color: textColor, fontSize: 20)),
    // Primary color for buttons, etc.
    primaryColor: primaryColor,
  );
}
