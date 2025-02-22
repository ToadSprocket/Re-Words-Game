// layouts/wildcard_column.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/grid_loader.dart';
import '../components/letter_square.dart';

class WildcardColumn extends StatelessWidget {
  final double width;
  final double height;
  final double squareSize;
  final double letterFontSize;
  final double valueFontSize;
  final double gridSpacing;
  final bool showBorders;
  final bool isHorizontal; // New flag

  const WildcardColumn({
    super.key,
    required this.width,
    required this.height,
    required this.squareSize,
    required this.letterFontSize,
    required this.valueFontSize,
    required this.gridSpacing,
    this.showBorders = false,
    this.isHorizontal = false, // Default vertical
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.blue, width: 2)) : null,
      child:
          isHorizontal
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    GridLoader.wildcardTiles.map((tile) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: gridSpacing / 2), // Horizontal spacing
                        child: LetterSquare(
                          letter: tile['letter'],
                          value: tile['value'],
                          isWildcard: true,
                          useCount: 0,
                          squareSize: squareSize,
                          letterFontSize: letterFontSize,
                          valueFontSize: valueFontSize,
                        ),
                      );
                    }).toList(),
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children:
                    GridLoader.wildcardTiles.map((tile) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: gridSpacing / 2), // Vertical spacing
                        child: LetterSquare(
                          letter: tile['letter'],
                          value: tile['value'],
                          isWildcard: true,
                          useCount: 0,
                          squareSize: squareSize,
                          letterFontSize: letterFontSize,
                          valueFontSize: valueFontSize,
                        ),
                      );
                    }).toList(),
              ),
    );
  }
}
