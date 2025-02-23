// components/letter_square.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/tile.dart';
import '../logic/game_layout.dart';

class LetterSquare extends StatelessWidget {
  final Tile tile;

  const LetterSquare({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    final squareTheme = Theme.of(context).extension<SquareTheme>()!;
    final textTheme = Theme.of(context).textTheme;
    final sizes = GameLayout.of(context).sizes;

    Color bgColor;
    Color borderColor;
    Color letterColor;
    Color valueColor;

    switch (tile.state) {
      case 'unused':
        bgColor = squareTheme.normalBackground;
        borderColor = squareTheme.normalBorder;
        letterColor = squareTheme.normalLetter;
        valueColor = squareTheme.normalValue;
        break;
      case 'selected':
        bgColor = squareTheme.selectedBackground;
        borderColor = squareTheme.selectedBorder;
        letterColor = squareTheme.selectedLetter;
        valueColor = squareTheme.selectedValue;
        break;
      case 'used':
        bgColor = tile.useCount > 1 ? squareTheme.usedBackground : squareTheme.usedBackground;
        borderColor = squareTheme.usedBorder;
        letterColor = squareTheme.usedLetter;
        valueColor = squareTheme.usedValue;
        break;
      case 'stacked':
        bgColor = squareTheme.stackedBackground;
        borderColor = squareTheme.stackedBorder;
        letterColor = squareTheme.stackedLetter;
        valueColor = squareTheme.stackedValue;
        break;
      case 'special':
        bgColor = squareTheme.specialBackground;
        borderColor = squareTheme.specialBorder;
        letterColor = squareTheme.specialLetter;
        valueColor = squareTheme.specialValue;
        break;
      case 'disabled':
        bgColor = squareTheme.disabledBackground;
        borderColor = squareTheme.disabledBorder;
        letterColor = squareTheme.disabledLetter;
        valueColor = squareTheme.disabledValue;
        break;
      default:
        bgColor = squareTheme.normalBackground;
        borderColor = squareTheme.normalBorder;
        letterColor = squareTheme.normalLetter;
        valueColor = squareTheme.normalValue;
    }

    int displayValue = tile.isExtra ? tile.value * 2 : tile.value;
    String valueText = tile.isExtra ? '${displayValue}x' : '$displayValue';

    return Container(
      width: sizes['squareSize'],
      height: sizes['squareSize'],
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: AppStyles.squareBorderWidth),
        borderRadius: BorderRadius.circular(AppStyles.squareBorderRadius),
      ),
      child: Stack(
        children: [
          Positioned(
            left: AppStyles.squareValueLeft,
            top: AppStyles.squareValueTop,
            child: Text(
              valueText,
              style: textTheme.labelSmall?.copyWith(fontSize: sizes['squareValueSize'], color: valueColor),
            ),
          ),
          Center(
            child: Text(
              tile.letter.toUpperCase(),
              style: textTheme.labelLarge?.copyWith(fontSize: sizes['squareLetterSize'], color: letterColor),
            ),
          ),
        ],
      ),
    );
  }
}
