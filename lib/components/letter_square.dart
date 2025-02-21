import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class LetterSquare extends StatelessWidget {
  final String letter;
  final int value;
  final bool isWildcard;
  final int useCount;
  final double squareSize;
  final double letterFontSize;
  final double valueFontSize;

  const LetterSquare({super.key, required this.letter, required this.value, this.isWildcard = false, this.useCount = 0, required this.squareSize, required this.letterFontSize, required this.valueFontSize});

  @override
  Widget build(BuildContext context) {
    // Background color based on usage
    Color bgColor;
    switch (useCount) {
      case 0:
        bgColor = AppStyles.normalSquareColor; // Normal dark gray
        break;
      case 1:
        bgColor = AppStyles.usedSquareColor; // Used once (gray)
        break;
      default:
        bgColor = AppStyles.usedMultipleColor; // 2+ uses (same gray)
    }

    int displayValue = isWildcard ? value * 2 : value;
    String valueText = isWildcard ? '${displayValue}x' : '$displayValue';

    return Container(
      width: squareSize,
      height: squareSize,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppStyles.normalletterTextColor), // White border
      ),
      child: Stack(
        children: [
          // Value in upper-left
          Positioned(
            left: 4,
            top: 2,
            child: Text(
              valueText,
              style: TextStyle(
                fontSize: valueFontSize,
                color: AppStyles.normalvalueTextColor, // Light gray
              ),
            ),
          ),
          // Main letter in center
          Center(
            child: Text(
              letter.toUpperCase(),
              style: TextStyle(
                fontSize: letterFontSize,
                fontWeight: FontWeight.bold,
                color: AppStyles.normalletterTextColor, // White
              ),
            ),
          ),
        ],
      ),
    );
  }
}
