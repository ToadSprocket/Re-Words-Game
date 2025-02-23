// layouts/wildcard_column.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/grid_loader.dart';
import '../logic/tile.dart'; // Add for Tile
import '../components/letter_square.dart';
import '../logic/game_layout.dart'; // Add for GameLayout

class WildcardColumn extends StatelessWidget {
  final double width;
  final double height;
  final bool showBorders;
  final bool isHorizontal;

  const WildcardColumn({
    super.key,
    required this.width,
    required this.height,
    this.showBorders = false,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = GameLayout.of(context).sizes;
    final gridSpacing = sizes['gridSpacing']!;

    return Container(
      width: width,
      height: height,
      decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.blue, width: 2)) : null,
      child:
          isHorizontal
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    GridLoader.wildcardTiles.map((tileData) {
                      Tile tile = Tile(letter: tileData['letter'], value: tileData['value'], isExtra: true);
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: gridSpacing / 2),
                        child: LetterSquare(tile: tile),
                      );
                    }).toList(),
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children:
                    GridLoader.wildcardTiles.map((tileData) {
                      Tile tile = Tile(letter: tileData['letter'], value: tileData['value'], isExtra: true);
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: gridSpacing / 2),
                        child: LetterSquare(tile: tile),
                      );
                    }).toList(),
              ),
    );
  }
}
