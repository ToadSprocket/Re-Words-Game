// components/letter_square_component.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../models/tile.dart';

class LetterSquareComponent extends StatelessWidget {
  final Tile tile;
  final Map<String, dynamic> sizes; // Add sizes parameter

  const LetterSquareComponent({super.key, required this.tile, required this.sizes});

  @override
  Widget build(BuildContext context) {
    final squareTheme = Theme.of(context).extension<SquareTheme>()!;
    final textTheme = Theme.of(context).textTheme;

    Color bgColor;
    Color borderColor;
    Color letterColor;
    Color valueColor;

    switch (tile.state) {
      case 'unused':
        bgColor = squareTheme.normalBackground;
        borderColor = squareTheme.normalBorder;
        letterColor = squareTheme.normalLetter;
        valueColor = tile.isExtra || tile.isHybrid ? AppStyles.wildcardValueTextColor : squareTheme.normalValue;
        break;
      case 'selected':
        bgColor = squareTheme.selectedBackground;
        borderColor = squareTheme.selectedBorder;
        letterColor = squareTheme.selectedLetter;
        valueColor = tile.isExtra || tile.isHybrid ? AppStyles.wildcardValueTextColor : squareTheme.normalValue;
        break;
      case 'used':
        bgColor = squareTheme.usedBackground;
        borderColor = squareTheme.usedBorder;
        letterColor = squareTheme.usedLetter;
        valueColor = tile.isExtra || tile.isHybrid ? AppStyles.wildcardValueTextColor : squareTheme.normalValue;
        break;
      default:
        bgColor = squareTheme.normalBackground;
        borderColor = squareTheme.normalBorder;
        letterColor = squareTheme.normalLetter;
        valueColor = tile.isExtra || tile.isHybrid ? AppStyles.wildcardValueTextColor : squareTheme.normalValue;
    }

    if (!tile.isHybrid && tile.useCount > 1) {
      valueColor = AppStyles.usedValueTextColor;
    }

    String valueText =
        tile.isExtra || tile.isHybrid
            ? '${tile.value}x' // Add "x" for wildcards/hybrids
            : tile.useCount > 0 && tile.value > 1
            ? '${tile.value}'
            : '${tile.value}';

    return Container(
      width: sizes['squareSize'] as double,
      height: sizes['squareSize'] as double,
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
              style: textTheme.labelSmall?.copyWith(fontSize: sizes['squareValueSize'] as double, color: valueColor),
            ),
          ),
          Center(
            child: Text(
              tile.letter.toUpperCase(),
              style: textTheme.labelLarge?.copyWith(fontSize: sizes['squareLetterSize'] as double, color: letterColor),
            ),
          ),
        ],
      ),
    );
  }
}
