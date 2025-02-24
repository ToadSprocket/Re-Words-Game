// screens/wide_screen.dart
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
import '../logic/game_layout.dart';
import '../components/game_message_component.dart';

class WideScreen extends StatelessWidget {
  final bool showBorders;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;
  final GlobalKey<GameGridComponentState>? gridKey; // Public state
  final GlobalKey<WildcardColumnComponentState>? wildcardKey; // Public state
  final ValueChanged<String>? onMessage; // Add callback
  final String message;
  final Map<String, dynamic> sizes;

  const WideScreen({
    super.key,
    required this.showBorders,
    required this.onSubmit,
    required this.onClear,
    required this.onInstructions,
    required this.onHighScores,
    required this.onLegal,
    this.gridKey,
    this.wildcardKey,
    this.onMessage,
    required this.message,
    required this.sizes,
  });

  @override
  Widget build(BuildContext context) {
    final gridSize = sizes['gridSize'] as double; // Cast here
    final squareSize = sizes['squareSize'] as double;
    final sideSpacing = sizes['sideSpacing'] as double;
    final sideColumnWidth = sizes['wordColumnWidth'] as double;
    final wordColumnWidth = sizes['wordColumnWidth'] as double;
    final wordColumnHeight = sizes['wordColumnHeight'] as double;
    final spelledWordsGridSpacing = sizes['spelledWordsGridSpacing'] as double;
    final gridSpacing = sizes['gridSpacing'] as double;
    const double topSectionHeight = 100.0;

    print("WideScreen");

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameTopBarComponent(
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
                WildcardColumnComponent(
                  key: wildcardKey,
                  width: sideColumnWidth,
                  height: gridSize,
                  showBorders: showBorders,
                  isHorizontal: false,
                  gridSpacing: gridSpacing,
                  sizes: sizes, // Pass here
                ),
              ],
            ),
            SizedBox(width: sideSpacing),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameTitleComponent(width: gridSize, showBorders: showBorders),
                const SizedBox(height: 20.0),
                GameScores(width: gridSize),
                const SizedBox(height: 8.0),
                GameGridComponent(key: gridKey, showBorders: showBorders, onMessage: onMessage, sizes: sizes),
                const SizedBox(height: 5.0),
                GameMessageComponent(message: message),
                const SizedBox(height: 5.0),
                GameButtonsComponent(onSubmit: onSubmit, onClear: onClear),
              ],
            ),
            SizedBox(width: sideSpacing),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: topSectionHeight),
                SpelledWordsColumnComponent(
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
