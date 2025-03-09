import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../components/wildcard_column_component.dart';
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../components/game_scores_component.dart';
import '../components/game_grid_component.dart';
import '../components/game_buttons_component.dart';
import '../components/spelled_words_ticker_component.dart';
import '../logic/spelled_words_handler.dart';
import '../logic/game_layout.dart';
import '../components/game_message_component.dart';

class NarrowScreen extends StatelessWidget {
  final bool showBorders;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;
  final GlobalKey<GameGridComponentState>? gridKey;
  final GlobalKey<WildcardColumnComponentState>? wildcardKey;
  final ValueChanged<String>? onMessage;
  final ValueNotifier<String> messageNotifier;
  final ValueNotifier<int> scoreNotifier; // Add this
  final ValueNotifier<List<String>> spelledWordsNotifier; // Add this
  final VoidCallback updateScoresRefresh; // Add this
  final Map<String, dynamic> sizes;

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
    this.onMessage,
    required this.messageNotifier,
    required this.scoreNotifier, // Required
    required this.spelledWordsNotifier, // Required
    required this.updateScoresRefresh, // Required
    required this.sizes,
  });

  @override
  Widget build(BuildContext context) {
    final gridSize = sizes['gridSize'] as double;
    final squareSize = sizes['squareSize'] as double;
    final gridSpacing = sizes['gridSpacing'] as double;

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
        const GameTitleComponent(width: 300, showBorders: false), // Const to avoid rebuild
        const SizedBox(height: 20.0),
        ValueListenableBuilder<List<String>>(
          valueListenable: spelledWordsNotifier,
          builder: (context, words, child) {
            print('SpelledWordsTickerComponent build');
            return SpelledWordsTickerComponent(gridSize: gridSize, squareSize: squareSize, words: words);
          },
        ),
        const SizedBox(height: 20.0),
        ValueListenableBuilder<int>(
          valueListenable: scoreNotifier,
          builder: (context, score, child) {
            print('GameScores build');
            return GameScores(width: gridSize, score: score);
          },
        ),
        SizedBox(height: gridSpacing),
        GameGridComponent(
          key: gridKey,
          showBorders: showBorders,
          onMessage: onMessage,
          updateScoresRefresh: updateScoresRefresh, // Pass this
          sizes: sizes,
        ),
        SizedBox(height: gridSpacing),
        WildcardColumnComponent(
          key: wildcardKey,
          width: gridSize,
          height: squareSize * 2,
          showBorders: showBorders,
          isHorizontal: true,
          gridSpacing: gridSpacing,
          sizes: sizes,
        ),
        const SizedBox(height: 5.0),
        ValueListenableBuilder<String>(
          valueListenable: messageNotifier,
          builder: (context, message, child) {
            print('GameMessageComponent build');
            return GameMessageComponent(message: message);
          },
        ),
        const SizedBox(height: 5.0),
        GameButtonsComponent(onSubmit: onSubmit, onClear: onClear),
      ],
    );
  }
}
