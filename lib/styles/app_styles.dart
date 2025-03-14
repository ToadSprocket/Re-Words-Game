// styles/app_styles.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';

class AppStyles {
  // Core Colors
  static const Color backgroundColor = Color(0xFF121213);
  static const Color appBarColor = Color(0xFF3A3A3C);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color primaryColor = Color(0xFF538D4E);
  static const Color helpIconColor = Color(0xFFB4B4B6);

  // Square Base Sizes
  static const double baseSquareSize = 60.0;
  static const double baseLetterFontSize = 28.0;
  static const double baseValueFontSize = 12.0;

  // Square Styles (New Additions)
  static const double squareBorderRadius = 8.0;
  static const double squareBorderWidth = 2.0;
  static const double squareValueLeft = 5.0;
  static const double squareValueTop = 0.0;

  // Grid Layout Constants
  static const int gridRows = 7;
  static const int gridCols = 7;

  // Base Layout Constants
  static const double baseGridSpacing = 4.0;
  static const double baseSideSpacing = 20.0;
  static const double baseSideColumnWidth = 300.0;
  static const double basedSpelledWordsGridSpacing = 6.0;
  static const double baseButtonFontSize = 16.0;
  static const double baseButtonVerticalPadding = 18.0;
  static const double baseButtonHorizontalPadding = 24.0;
  static const double baseButtonBorderRadius = 20.0;
  static const double baseButtonBorderThickness = 2.0;

  // Button Styles (New Addition)
  static const double buttonTextOffset = -1.4; // Moves text up slightly

  // Title Styles
  static const double headerFontSize = 36.0;
  static const Color headerTextColor = Color.fromARGB(255, 79, 185, 69);

  // Square Styles
  static const Color normalSquareColor = Color(0xFF1F1F21);
  static const Color selectedSquareColor = Color.fromARGB(209, 44, 110, 38);
  static const Color usedSquareColor = Color.fromARGB(120, 44, 110, 38);
  static const Color usedMultipleColor = Color(0xFF818384);
  static const Color stackedSquareColor = Color(0xFF3A3A3C);
  static const Color specialSquareColor = Color(0xFF6A1B9A);
  static const Color disabledSquareColor = Color(0xFF818384);

  static const Color normalBorderColor = Color.fromARGB(209, 255, 255, 255);
  static const Color selectedBorderColor = Color.fromARGB(209, 255, 255, 255);
  static const Color usedBorderColor = Color.fromARGB(209, 255, 255, 255);
  static const Color stackedBorderColor = Color.fromARGB(209, 255, 255, 255);
  static const Color specialBorderColor = Color.fromARGB(255, 255, 255, 255);
  static const Color disabledBorderColor = Color.fromARGB(209, 255, 255, 255);

  static const Color normalLetterTextColor = Color.fromARGB(209, 255, 255, 255);
  static const Color selectedLetterTextColor = Color.fromARGB(209, 255, 255, 255);
  static const Color usedLetterTextColor = Color(0xFFB4B4B6);
  static const Color stackedLetterTextColor = Color.fromARGB(209, 255, 255, 255);
  static const Color specialLetterTextColor = Color.fromARGB(255, 255, 255, 255);
  static const Color disabledLetterTextColor = Color.fromARGB(150, 255, 255, 255);

  static const Color normalValueTextColor = Color.fromARGB(230, 4, 190, 29);
  static const Color selectedValueTextColor = Color.fromARGB(230, 4, 190, 29);
  static const Color usedValueTextColor = Color.fromARGB(255, 243, 198, 50);
  static const Color stackedValueTextColor = Color.fromARGB(230, 4, 190, 29);
  static const Color specialValueTextColor = Color.fromARGB(255, 255, 255, 255);
  static const Color disabledValueTextColor = Color.fromARGB(150, 180, 71, 57);
  static const Color wildcardValueTextColor = Color.fromARGB(255, 233, 133, 3);

  static const double wildcardDisabledOpacity = 0.8;

  // Spelled Words Styles
  static const double spelledWordsTitleFontSize = 15.0;
  static const Color spelledWordsTitleColor = Color(0xFFFFFFFF);
  static const double spelledWordsFontSize = 15.0;
  static const Color spelledWordsTextColor = Color.fromARGB(255, 251, 251, 255);
  static const double spelledWordsVerticalPadding = 0.5;
  static const Color spelledWordsOuterBorderColor = Colors.green;
  static const Color spelledWordsColumnBorderColor = Colors.cyan;
  static const double spelledWordsBorderWidth = 0.5;

  // Ticker Styles
  static const double tickerWidthFactor = 1.0;
  static const double tickerHeight = 43.0;
  static const Color tickerBorderColor = Color.fromARGB(54, 255, 255, 255);
  static const double tickerBorderWidth = 1.0;
  static const double tickerTitleFontSize = 16.0;
  static const double tickerFontSize = 16.0;

  static const double tickerPopupWidth = 600.0;
  static const double tickerPopupHeight = 800.0;
  static const double tickerPopupCrossSpacing = 0.1;
  static const double tickerPopupMainSpacing = 0.1;

  // Dialog Styles
  static const double dialogWidth = 400.0;
  static const double dialogHeight = 550.0;
  static const Color dialogBackgroundColor = backgroundColor;
  static const Color dialogBorderColor = Colors.white;
  static const double dialogBorderWidth = 2.0;
  static const double dialogBorderRadius = 8.0;
  static const double dialogPadding = 16.0;
  static const double dialogButtonPadding = 8.0;

  static const Color loginTextColor = Colors.blueAccent;

  static const TextStyle dialogTitleStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: Color.fromARGB(255, 255, 255, 255),
  );
  static const TextStyle dialogContentStyle = TextStyle(fontSize: 16.0, color: Color.fromARGB(255, 240, 240, 240));
  static const TextStyle InputTitleStyle = TextStyle(
    fontSize: 14.0,
    color: Color.fromARGB(255, 240, 240, 240),
    fontWeight: FontWeight.bold,
  );
  static const TextStyle dialogContentHighLiteStyle = TextStyle(fontSize: 16.0, color: Color.fromARGB(230, 4, 190, 29));
  static const TextStyle inputContentStyle = TextStyle(fontSize: 18.0, color: Color.fromARGB(211, 240, 240, 240));
  static const TextStyle dialogLinkStyle = TextStyle(
    fontSize: 14.0,
    color: Color.fromARGB(255, 93, 174, 240),
    decoration: TextDecoration.underline,
  );
  static const TextStyle dialogErrorStyle = TextStyle(fontSize: 14.0, color: Colors.red, fontWeight: FontWeight.bold);
  static const TextStyle dialogSuccessStyle = TextStyle(
    fontSize: 14.0,
    color: Color.fromARGB(255, 54, 244, 54),
    fontWeight: FontWeight.bold,
  );

  // Button Styles
  static ButtonStyle buttonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(61, 79, 185, 69),
      foregroundColor: const Color.fromARGB(255, 236, 232, 232),
      padding: const EdgeInsets.symmetric(horizontal: baseButtonHorizontalPadding, vertical: baseButtonVerticalPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(baseButtonBorderRadius),
        side: const BorderSide(color: Color.fromARGB(255, 236, 232, 232), width: baseButtonBorderThickness),
      ),
      textStyle: const TextStyle(fontSize: baseButtonFontSize, fontWeight: FontWeight.bold),
      // Apply text offset
      alignment: Alignment(0, buttonTextOffset / baseButtonVerticalPadding), // Normalize offset
    );
  }

  // ThemeData
  static ThemeData get appTheme => ThemeData(
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: appBarColor,
      titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: textColor, fontSize: 16),
      bodyLarge: TextStyle(color: textColor, fontSize: 20),
      labelLarge: TextStyle(fontSize: baseLetterFontSize, fontWeight: FontWeight.bold, color: normalLetterTextColor),
      labelSmall: TextStyle(fontSize: baseValueFontSize, fontWeight: FontWeight.bold, color: normalValueTextColor),
    ),
    primaryColor: primaryColor,
    extensions: const [SquareTheme()],
  );
}

// SquareTheme Extension (Unchanged)
class SquareTheme extends ThemeExtension<SquareTheme> {
  final Color normalBackground;
  final Color selectedBackground;
  final Color usedBackground;
  final Color stackedBackground;
  final Color specialBackground;
  final Color disabledBackground;

  final Color normalBorder;
  final Color selectedBorder;
  final Color usedBorder;
  final Color stackedBorder;
  final Color specialBorder;
  final Color disabledBorder;

  final Color normalLetter;
  final Color selectedLetter;
  final Color usedLetter;
  final Color stackedLetter;
  final Color specialLetter;
  final Color disabledLetter;

  final Color normalValue;
  final Color selectedValue;
  final Color usedValue;
  final Color stackedValue;
  final Color specialValue;
  final Color disabledValue;

  const SquareTheme({
    this.normalBackground = AppStyles.normalSquareColor,
    this.selectedBackground = AppStyles.selectedSquareColor,
    this.usedBackground = AppStyles.usedSquareColor,
    this.stackedBackground = AppStyles.stackedSquareColor,
    this.specialBackground = AppStyles.specialSquareColor,
    this.disabledBackground = AppStyles.disabledSquareColor,
    this.normalBorder = AppStyles.normalBorderColor,
    this.selectedBorder = AppStyles.selectedBorderColor,
    this.usedBorder = AppStyles.usedBorderColor,
    this.stackedBorder = AppStyles.stackedBorderColor,
    this.specialBorder = AppStyles.specialBorderColor,
    this.disabledBorder = AppStyles.disabledBorderColor,
    this.normalLetter = AppStyles.normalLetterTextColor,
    this.selectedLetter = AppStyles.selectedLetterTextColor,
    this.usedLetter = AppStyles.usedLetterTextColor,
    this.stackedLetter = AppStyles.stackedLetterTextColor,
    this.specialLetter = AppStyles.specialLetterTextColor,
    this.disabledLetter = AppStyles.disabledLetterTextColor,
    this.normalValue = AppStyles.normalValueTextColor,
    this.selectedValue = AppStyles.selectedValueTextColor,
    this.usedValue = AppStyles.usedValueTextColor,
    this.stackedValue = AppStyles.stackedValueTextColor,
    this.specialValue = AppStyles.specialValueTextColor,
    this.disabledValue = AppStyles.disabledValueTextColor,
  });

  @override
  SquareTheme copyWith({
    Color? normalBackground,
    Color? selectedBackground,
    Color? usedBackground,
    Color? stackedBackground,
    Color? specialBackground,
    Color? disabledBackground,
    Color? normalBorder,
    Color? selectedBorder,
    Color? usedBorder,
    Color? stackedBorder,
    Color? specialBorder,
    Color? disabledBorder,
    Color? normalLetter,
    Color? selectedLetter,
    Color? usedLetter,
    Color? stackedLetter,
    Color? specialLetter,
    Color? disabledLetter,
    Color? normalValue,
    Color? selectedValue,
    Color? usedValue,
    Color? stackedValue,
    Color? specialValue,
    Color? disabledValue,
  }) {
    return SquareTheme(
      normalBackground: normalBackground ?? this.normalBackground,
      selectedBackground: selectedBackground ?? this.selectedBackground,
      usedBackground: usedBackground ?? this.usedBackground,
      stackedBackground: stackedBackground ?? this.stackedBackground,
      specialBackground: specialBackground ?? this.specialBackground,
      disabledBackground: disabledBackground ?? this.disabledBackground,
      normalBorder: normalBorder ?? this.normalBorder,
      selectedBorder: selectedBorder ?? this.selectedBorder,
      usedBorder: usedBorder ?? this.usedBorder,
      stackedBorder: stackedBorder ?? this.stackedBorder,
      specialBorder: specialBorder ?? this.specialBorder,
      disabledBorder: disabledBorder ?? this.disabledBorder,
      normalLetter: normalLetter ?? this.normalLetter,
      selectedLetter: selectedLetter ?? this.selectedLetter,
      usedLetter: usedLetter ?? this.usedLetter,
      stackedLetter: stackedLetter ?? this.stackedLetter,
      specialLetter: specialLetter ?? this.specialLetter,
      disabledLetter: disabledLetter ?? this.disabledLetter,
      normalValue: normalValue ?? this.normalValue,
      selectedValue: selectedValue ?? this.selectedValue,
      usedValue: usedValue ?? this.usedValue,
      stackedValue: stackedValue ?? this.stackedValue,
      specialValue: specialValue ?? this.specialValue,
      disabledValue: disabledValue ?? this.disabledValue,
    );
  }

  @override
  SquareTheme lerp(ThemeExtension<SquareTheme>? other, double t) {
    if (other is! SquareTheme) return this;
    return SquareTheme(
      normalBackground: Color.lerp(normalBackground, other.normalBackground, t)!,
      selectedBackground: Color.lerp(selectedBackground, other.selectedBackground, t)!,
      usedBackground: Color.lerp(usedBackground, other.usedBackground, t)!,
      stackedBackground: Color.lerp(stackedBackground, other.stackedBackground, t)!,
      specialBackground: Color.lerp(specialBackground, other.specialBackground, t)!,
      disabledBackground: Color.lerp(disabledBackground, other.disabledBackground, t)!,
      normalBorder: Color.lerp(normalBorder, other.normalBorder, t)!,
      selectedBorder: Color.lerp(selectedBorder, other.selectedBorder, t)!,
      usedBorder: Color.lerp(usedBorder, other.usedBorder, t)!,
      stackedBorder: Color.lerp(stackedBorder, other.stackedBorder, t)!,
      specialBorder: Color.lerp(specialBorder, other.specialBorder, t)!,
      disabledBorder: Color.lerp(disabledBorder, other.disabledBorder, t)!,
      normalLetter: Color.lerp(normalLetter, other.normalLetter, t)!,
      selectedLetter: Color.lerp(selectedLetter, other.selectedLetter, t)!,
      usedLetter: Color.lerp(usedLetter, other.usedLetter, t)!,
      stackedLetter: Color.lerp(stackedLetter, other.stackedLetter, t)!,
      specialLetter: Color.lerp(specialLetter, other.specialLetter, t)!,
      disabledLetter: Color.lerp(disabledLetter, other.disabledLetter, t)!,
      normalValue: Color.lerp(normalValue, other.normalValue, t)!,
      selectedValue: Color.lerp(selectedValue, other.selectedValue, t)!,
      usedValue: Color.lerp(usedValue, other.usedValue, t)!,
      stackedValue: Color.lerp(stackedValue, other.stackedValue, t)!,
      specialValue: Color.lerp(specialValue, other.specialValue, t)!,
      disabledValue: Color.lerp(disabledValue, other.disabledValue, t)!,
    );
  }
}
