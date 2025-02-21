// layouts/game_grid.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/grid_loader.dart';
import '../components/letter_square.dart';

// Displays the main grid of letter tiles
class GameGrid extends StatelessWidget {
  final double gridSize;
  final double squareSize;
  final double letterFontSize;
  final double valueFontSize;
  final double gridSpacing;
  final bool showBorders;

  const GameGrid({
    super.key,
    required this.gridSize,
    required this.squareSize,
    required this.letterFontSize,
    required this.valueFontSize,
    required this.gridSpacing,
    this.showBorders = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: gridSize,
      height: gridSize,
      decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 2)) : null,
      child: GridView.count(
        crossAxisCount: AppStyles.gridCols,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        children:
            GridLoader.gridTiles.map((tile) {
              return LetterSquare(
                letter: tile['letter'],
                value: tile['value'],
                useCount: 0,
                squareSize: squareSize,
                letterFontSize: letterFontSize,
                valueFontSize: valueFontSize,
              );
            }).toList(),
      ),
    );
  }
}
