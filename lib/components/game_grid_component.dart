// layouts/game_grid.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/grid_loader.dart';
import '../logic/tile.dart';
import '../logic/game_layout.dart';
import 'letter_square_component.dart';

class GameGrid extends StatelessWidget {
  final bool showBorders;

  const GameGrid({super.key, this.showBorders = false});

  @override
  Widget build(BuildContext context) {
    final sizes = GameLayout.of(context).sizes;
    final gridSize = sizes['gridSize']!;
    final squareSize = sizes['squareSize']!;
    final squareLetterSize = sizes['squareLetterSize']!;
    final squareValueSize = sizes['squareValueSize']!;
    final gridSpacing = sizes['gridSpacing']!;

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
            GridLoader.gridTiles.map((tileData) {
              Tile tile = Tile(letter: tileData['letter'], value: tileData['value'], isExtra: false);
              return LetterSquare(tile: tile);
            }).toList(),
      ),
    );
  }
}
