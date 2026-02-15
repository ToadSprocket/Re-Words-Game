// File: /lib/components/letter_square_component.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../models/tile.dart';
import '../managers/gameLayoutManager.dart';
import '../managers/gameManager.dart';

class LetterSquareComponent extends StatelessWidget {
  final Tile tile;
  final bool helpDialog;

  const LetterSquareComponent({super.key, required this.tile, required this.helpDialog});

  @override
  Widget build(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;

    Color bgColor;
    Color valueColor;

    switch (tile.state) {
      case 'unused':
        bgColor = AppStyles.normalSquareColor;
        valueColor = tile.isExtra || tile.isHybrid ? AppStyles.wildcardValueTextColor : AppStyles.normalValueTextColor;
        break;
      case 'selected':
        bgColor = AppStyles.selectedSquareColor;
        valueColor = tile.isExtra || tile.isHybrid ? AppStyles.wildcardValueTextColor : AppStyles.normalValueTextColor;
        break;
      case 'used':
        bgColor = AppStyles.usedSquareColor;
        valueColor = tile.isExtra || tile.isHybrid ? AppStyles.wildcardValueTextColor : AppStyles.normalValueTextColor;
        break;
      default:
        bgColor = AppStyles.normalSquareColor;
        valueColor = tile.isExtra || tile.isHybrid ? AppStyles.wildcardValueTextColor : AppStyles.normalValueTextColor;
    }

    if (!tile.isHybrid && tile.useCount > 1) {
      valueColor = AppStyles.usedValueTextColor;
    }

    return Container(
      width: helpDialog ? GameLayoutManager.helpDialogSquareSize : layout.gridSquareSize,
      height: helpDialog ? GameLayoutManager.helpDialogSquareSize : layout.gridSquareSize,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppStyles.squareBorderColor, width: GameLayoutManager.squareBorderWidth),
        borderRadius: BorderRadius.circular(GameLayoutManager.squareBorderRadius),
      ),
      child: Stack(
        children: [
          Positioned(
            left: layout.squareValueOffsetLeft,
            top: layout.squareValueOffsetTop,
            child: Text(
              tile.value.toString(),
              style: TextStyle(
                fontSize: helpDialog ? layout.helpDialogSquareValueSize : layout.squareValueFontSize,
                fontWeight: layout.defaultFontWeight,
                color: valueColor,
              ),
            ),
          ),
          Center(
            child: Text(
              tile.letter.toUpperCase(),
              style: TextStyle(
                fontSize: helpDialog ? layout.helpDialogSquareLetterSize : layout.squareLetterFontSize,
                fontWeight: layout.defaultFontWeight,
                color: AppStyles.normalLetterTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
