// styles/app_styles.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppStyles {
  // Core Colors
  static const Color infoBarIconColors = Color.fromRGBO(180, 180, 182, 1);

  // Title Styles
  static const Color headerTextColor = Color.fromARGB(255, 79, 185, 69);

  // Square Styles
  static const Color normalSquareColor = Color(0xFF1F1F21);
  static const Color squareBorderColor = Color.fromARGB(83, 188, 210, 186);
  static const Color selectedSquareColor = Color.fromARGB(209, 44, 110, 38);
  static const Color usedSquareColor = Color.fromARGB(95, 44, 110, 38);

  static const Color normalLetterTextColor = Color.fromARGB(228, 255, 255, 255);

  static const Color normalValueTextColor = Color.fromARGB(230, 4, 190, 29);
  static const Color usedValueTextColor = Color.fromARGB(255, 243, 198, 50);
  static const Color titleSloganTextColor = Color.fromARGB(255, 243, 198, 50);
  static const Color stackedValueTextColor = Color.fromARGB(230, 4, 190, 29);
  static const Color wildcardValueTextColor = Color.fromARGB(255, 233, 133, 3);

  // Spelled Words Styles
  static const Color spelledWordsTitleColor = Color(0xFFFFFFFF);
  static const Color spelledWordsTextColor = Color.fromARGB(255, 251, 251, 255);
  static const Color spelledWordsOuterBorderColor = Colors.green;
  static const Color spelledWordsColumnBorderColor = Colors.cyan;

  // Ticker Styles
  static const double tickerWidthFactor = 1.0;
  static const double tickerHeight = 43.0;
  static const Color tickerBorderColor = Color.fromARGB(54, 255, 255, 255);
  static const Color tickerDotsColor = Color.fromARGB(255, 79, 185, 69);
  static const double tickerDotSizeFactor = 1.4; // Dot size relative to font size
  static const double tickerBorderWidth = 1.0;
  static const double tickerTitleFontSize = 16.0;
  static const double tickerFontSize = 16.0;

  static const double tickerPopupWidth = 600.0;
  static const double tickerPopupHeight = 800.0;
  static const double tickerPopupCrossSpacing = 0.1;
  static const double tickerPopupMainSpacing = 0.1;

  // Dialog Styles
  static const Color dialogBackgroundColor = Color.fromARGB(255, 42, 42, 42);
  static const Color dialogBorderColor = Colors.white;
  static const Color dialogInputFocusColor = Color.fromARGB(158, 79, 185, 69); // Green focus color
  static const Color dialogInputHoverColor = Color.fromARGB(95, 44, 110, 38); // Dark green hover color
  static const double dialogBorderWidth = 2.0;
  static const double dialogBorderRadius = 8.0;
  static const double dialogPadding = 16.0;
  static const double dialogButtonPadding = 8.0;
  static const Color dialogIconColor = Color(0xFFFFFFFF);

  // ThemeData
  static ThemeData get appTheme => ThemeData(
    scaffoldBackgroundColor: const Color.fromARGB(255, 18, 18, 18),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 26, 26, 26),
      titleTextStyle: TextStyle(color: Color.fromARGB(236, 255, 255, 255), fontSize: 20, fontWeight: FontWeight.bold),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color.fromARGB(222, 244, 242, 242), fontSize: 16),
      bodyLarge: TextStyle(color: Color.fromARGB(222, 244, 242, 242), fontSize: 20),
      labelLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: normalLetterTextColor),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: normalValueTextColor),
    ),
    primaryColor: CupertinoColors.activeGreen,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: dialogInputFocusColor,
      selectionColor: dialogInputHoverColor,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: dialogInputFocusColor)),
      focusColor: dialogInputFocusColor,
      hoverColor: dialogInputHoverColor,
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: dialogBorderColor)),
    ),
  );
}
