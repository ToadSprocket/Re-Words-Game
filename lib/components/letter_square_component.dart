// components/letter_square_component.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../models/tile.dart';
import '../logic/game_layout.dart';

class LetterSquareComponent extends StatelessWidget {
  final Tile tile;

  const LetterSquareComponent({super.key, required this.tile});

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
        valueColor = tile.isExtra ? AppStyles.wildcardValueTextColor : squareTheme.normalValue;
        break;
      case 'selected':
        bgColor = squareTheme.selectedBackground;
        borderColor = squareTheme.selectedBorder;
        letterColor = squareTheme.selectedLetter;
        valueColor = tile.isExtra ? AppStyles.wildcardValueTextColor : squareTheme.selectedValue;
        break;
      case 'used':
        bgColor = squareTheme.usedBackground;
        borderColor = squareTheme.usedBorder;
        letterColor = squareTheme.usedLetter;
        valueColor = tile.isExtra ? AppStyles.wildcardValueTextColor : squareTheme.usedValue;
        break;
      default:
        bgColor = squareTheme.normalBackground;
        borderColor = squareTheme.normalBorder;
        letterColor = squareTheme.normalLetter;
        valueColor = tile.isExtra ? AppStyles.wildcardValueTextColor : squareTheme.normalValue;
    }

    String valueText =
        tile.isExtra
            ? '${tile.value * tile.multiplier.round()}x'
            : tile.useCount > 0 &&
                tile.value >
                    1 // Show "x" only if doubled
            ? '${tile.value}'
            : '${tile.value}';

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
