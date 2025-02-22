// lib/screens/narrow_screen.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../layouts/wildcard_column.dart';
import '../layouts/game_top_bar.dart';
import '../layouts/game_title.dart';
import '../layouts/game_scores.dart';
import '../layouts/game_grid.dart';
import '../layouts/game_buttons.dart';
import '../layouts/spelled_words_ticker.dart';
import '../logic/spelled_words_handler.dart';

class NarrowScreen extends StatelessWidget {
  final double squareSize;
  final double letterFontSize;
  final double valueFontSize;
  final double gridSize;
  final double gridSpacing;
  final double sideSpacing;
  final double sideColumnWidth;
  final double wordColumnWidth;
  final double wordColumnHeight;
  final double spelledWordsGridSpacing;
  final bool showBorders;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;

  const NarrowScreen({
    super.key,
    required this.squareSize,
    required this.letterFontSize,
    required this.valueFontSize,
    required this.gridSize,
    required this.gridSpacing,
    required this.sideSpacing,
    required this.sideColumnWidth,
    required this.wordColumnWidth,
    required this.wordColumnHeight,
    required this.spelledWordsGridSpacing,
    required this.showBorders,
    required this.onSubmit,
    required this.onClear,
    required this.onInstructions,
    required this.onHighScores,
    required this.onLegal,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GameTopBar(
          onInstructions: onInstructions,
          onHighScores: onHighScores,
          onLegal: onLegal,
          showBorders: showBorders,
        ),
        const Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
        const SizedBox(height: 10.0),
        GameTitle(width: gridSize, showBorders: showBorders),
        const SizedBox(height: 20.0),
        SpelledWordsTicker(gridSize: gridSize, squareSize: squareSize), // No onTap—uses default popup
        const SizedBox(height: 20.0),
        GameScores(width: gridSize),
        SizedBox(height: gridSpacing),
        GameGrid(
          gridSize: gridSize,
          squareSize: squareSize,
          letterFontSize: letterFontSize,
          valueFontSize: valueFontSize,
          gridSpacing: gridSpacing,
          showBorders: showBorders,
        ),
        SizedBox(height: gridSpacing),
        WildcardColumn(
          width: gridSize,
          height: squareSize * 2,
          squareSize: squareSize,
          letterFontSize: letterFontSize,
          valueFontSize: valueFontSize,
          gridSpacing: gridSpacing,
          showBorders: showBorders,
          isHorizontal: true,
        ),
        const SizedBox(height: 20.0),
        GameButtons(onSubmit: onSubmit, onClear: onClear),
      ],
    );
  }
}
