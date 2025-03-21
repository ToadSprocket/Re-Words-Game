// components/letter_square_component.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../models/tile.dart';
import '../managers/gameLayoutManager.dart';

class LetterSquareComponent extends StatelessWidget {
  final Tile tile;
  final GameLayoutManager gameLayoutManager;
  final bool helpDialog;

  const LetterSquareComponent({
    super.key,
    required this.tile,
    required this.gameLayoutManager,
    required this.helpDialog,
  });

  @override
  Widget build(BuildContext context) {
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
      width: helpDialog ? gameLayoutManager.gridSquareSize : GameLayoutManager.helpDialogSquareSize,
      height: helpDialog ? gameLayoutManager.gridSquareSize : GameLayoutManager.helpDialogSquareSize,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppStyles.squareBorderColor, width: GameLayoutManager.squareBorderWidth),
        borderRadius: BorderRadius.circular(GameLayoutManager.squareBorderRadius),
      ),
      child: Stack(
        children: [
          Positioned(
            left: gameLayoutManager.squareValueOffsetLeft,
            top: gameLayoutManager.squareValueOffsetTop,
            child: Text(
              tile.value.toString(),
              style: TextStyle(
                fontSize:
                    helpDialog ? GameLayoutManager.helpDialogSquareValueSize : gameLayoutManager.squareValueFontSize,
                color: valueColor, // Directly use the color
              ),
            ),
          ),
          Center(
            child: Text(
              tile.letter.toUpperCase(),
              style: TextStyle(
                fontSize:
                    helpDialog ? GameLayoutManager.helpDialogSquareLetterSize : gameLayoutManager.squareLetterFontSize,
                color: AppStyles.normalLetterTextColor, // Directly use the color
              ),
            ),
          ),
        ],
      ),
    );
  }
}
