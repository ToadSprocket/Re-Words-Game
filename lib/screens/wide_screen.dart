// lib/screens/wide_screen.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../components/wildcard_column_component.dart';
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../dialogs/game_scores_dialog.dart';
import '../components/game_grid_component.dart';
import '../components/game_buttons_component.dart';
import '../components/spelled_words_column_component.dart';
import '../logic/spelled_words_handler.dart';
import '../logic/game_layout.dart'; // Add for GameLayout

class WideScreen extends StatelessWidget {
  final bool showBorders;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;

  const WideScreen({
    super.key,
    required this.showBorders,
    required this.onSubmit,
    required this.onClear,
    required this.onInstructions,
    required this.onHighScores,
    required this.onLegal,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = GameLayout.of(context).sizes;
    final gridSize = sizes['gridSize']!;
    final squareSize = sizes['squareSize']!;
    final sideSpacing = sizes['sideSpacing']!;
    final sideColumnWidth = sizes['sideColumnWidth']!;
    final wordColumnWidth = sizes['wordColumnWidth']!;
    final wordColumnHeight = sizes['wordColumnHeight']!;
    final spelledWordsGridSpacing = sizes['spelledWordsGridSpacing']!;
    const double topSectionHeight = 100.0;

    print("WideScreen");

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
                const SizedBox(height: topSectionHeight),
                WildcardColumn(width: sideColumnWidth, height: gridSize, showBorders: showBorders, isHorizontal: false),
              ],
            ),
            SizedBox(width: sideSpacing),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameTitle(width: gridSize, showBorders: showBorders),
                const SizedBox(height: 20.0),
                GameScores(width: gridSize),
                const SizedBox(height: 8.0), // Static—could use gridSpacing if dynamic
                GameGrid(showBorders: showBorders),
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
