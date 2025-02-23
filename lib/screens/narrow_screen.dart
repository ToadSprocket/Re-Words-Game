// screens/narrow_screen.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../components/wildcard_column_component.dart';
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../dialogs/game_scores_dialog.dart';
import '../components/game_grid_component.dart';
import '../components/game_buttons_component.dart';
import '../components/spelled_words_ticker_component.dart';
import '../logic/spelled_words_handler.dart';
import '../logic/game_layout.dart';

class NarrowScreen extends StatelessWidget {
  final bool showBorders;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;
  final GlobalKey<GameGridComponentState>? gridKey; // Add key
  final GlobalKey<WildcardColumnComponentState>? wildcardKey; // Add key

  const NarrowScreen({
    super.key,
    required this.showBorders,
    required this.onSubmit,
    required this.onClear,
    required this.onInstructions,
    required this.onHighScores,
    required this.onLegal,
    this.gridKey,
    this.wildcardKey,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = GameLayout.of(context).sizes;
    final gridSize = sizes['gridSize']!;
    final squareSize = sizes['squareSize']!;
    final gridSpacing = sizes['gridSpacing']!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GameTopBarComponent(
          onInstructions: onInstructions,
          onHighScores: onHighScores,
          onLegal: onLegal,
          showBorders: showBorders,
        ),
        const Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
        const SizedBox(height: 10.0),
        GameTitleComponent(width: gridSize, showBorders: showBorders),
        const SizedBox(height: 20.0),
        SpelledWordsTickerComponent(gridSize: gridSize, squareSize: squareSize),
        const SizedBox(height: 20.0),
        GameScores(width: gridSize),
        SizedBox(height: gridSpacing),
        GameGridComponent(
          key: gridKey, // Pass key
          showBorders: showBorders,
        ),
        SizedBox(height: gridSpacing),
        WildcardColumnComponent(
          key: wildcardKey, // Pass key
          width: gridSize,
          height: squareSize * 2,
          showBorders: showBorders,
          isHorizontal: true,
        ),
        const SizedBox(height: 20.0),
        GameButtonsComponent(onSubmit: onSubmit, onClear: onClear),
      ],
    );
  }
}
