// lib/screens/wide_screen.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../layouts/wildcard_column.dart';
import '../layouts/game_top_bar.dart';
import '../layouts/game_title.dart';
import '../layouts/game_scores.dart';
import '../layouts/game_grid.dart';
import '../layouts/game_buttons.dart';
import '../layouts/spelled_words_column.dart';
import '../logic/spelled_words_handler.dart';

class WideScreen extends StatelessWidget {
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

  const WideScreen({
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
    const double topSectionHeight = 100.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameTopBar(
          onInstructions: onInstructions,
          onHighScores: onHighScores,
          onLegal: onLegal,
          showBorders: showBorders,
        ),
        const Divider(height: 1.0, thickness: 1.0, color: Color.fromARGB(73, 158, 158, 158)),
        const SizedBox(height: 10.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: topSectionHeight), // Adjusted for top bar (40) + divider (1) + spacing (10)
                WildcardColumn(
                  width: sideColumnWidth,
                  height: gridSize,
                  squareSize: squareSize,
                  letterFontSize: letterFontSize,
                  valueFontSize: valueFontSize,
                  gridSpacing: gridSpacing,
                  showBorders: showBorders,
                  isHorizontal: false,
                ),
              ],
            ),
            SizedBox(width: sideSpacing),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameTitle(width: gridSize, showBorders: showBorders),
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
                const SizedBox(height: 20.0),
                GameButtons(onSubmit: onSubmit, onClear: onClear),
              ],
            ),
            SizedBox(width: sideSpacing),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: topSectionHeight),
                SpelledWordsColumn(
                  words: SpelledWordsLogic.spelledWords,
                  columnWidth: sideColumnWidth,
                  columnHeight: gridSize,
                  gridSpacing: spelledWordsGridSpacing,
                  showBorders: showBorders,
                  wordColumnWidth: wordColumnWidth,
                  wordColumnHeight: wordColumnHeight,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
