// screens/wide_screen.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../components/wildcard_column_component.dart';
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../components/game_scores_component.dart';
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
  final GlobalKey<GameGridComponentState>? gridKey;
  final GlobalKey<WildcardColumnComponentState>? wildcardKey;
  final ValueChanged<String>? onMessage;
  final ValueNotifier<String> messageNotifier;
  final ValueNotifier<int> scoreNotifier; // Notifier
  final ValueNotifier<List<String>> spelledWordsNotifier; // Notifier
  final VoidCallback updateScoresRefresh;
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
    required this.messageNotifier,
    required this.scoreNotifier,
    required this.spelledWordsNotifier,
    required this.updateScoresRefresh,
    required this.sizes,
  });

  @override
  Widget build(BuildContext context) {
    final gridSize = sizes['gridSize'] as double;
    final sideSpacing = sizes['sideSpacing'] as double;
    final sideColumnWidth = sizes['sideColumnWidth'] as double;
    final wordColumnWidth = sizes['wordColumnWidth'] as double;
    final wordColumnHeight = sizes['wordColumnHeight'] as double;
    final spelledWordsGridSpacing = sizes['spelledWordsGridSpacing'] as double;
    final gridSpacing = sizes['gridSpacing'] as double;
    const double topSectionHeight = 80.0;

    print("WideScreen build");
    print('Side column width: $sideColumnWidth, Side spacing: $sideSpacing');

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column (Wildcard)
            Container(
              decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.blue, width: 2)) : null,
              child: Column(
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
                    sizes: sizes,
                  ),
                ],
              ),
            ),
            SizedBox(width: sideSpacing),
            // Center Column (Grid and Controls)
            Container(
              decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 2)) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GameTitleComponent(width: 300, showBorders: false), // Const to avoid rebuild
                  const SizedBox(height: 20.0),
                  ValueListenableBuilder<int>(
                    valueListenable: scoreNotifier,
                    builder: (context, score, child) {
                      print('GameScores build');
                      return GameScores(width: gridSize, score: score);
                    },
                  ),
                  const SizedBox(height: 8.0),
                  GameGridComponent(
                    key: gridKey,
                    showBorders: showBorders,
                    onMessage: onMessage,
                    updateScoresRefresh: updateScoresRefresh, // Pass refresh
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
              ),
            ),
            SizedBox(width: sideSpacing),
            // Right Column (Spelled Words)
            Container(
              decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.green, width: 2)) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: topSectionHeight),
                  ValueListenableBuilder<List<String>>(
                    valueListenable: spelledWordsNotifier,
                    builder: (context, words, child) {
                      print('SpelledWordsColumnComponent build');
                      return SpelledWordsColumnComponent(
                        words: words, // Use notifier value
                        columnWidth: sideColumnWidth,
                        columnHeight: gridSize,
                        gridSpacing: spelledWordsGridSpacing,
                        showBorders: showBorders,
                        wordColumnWidth: wordColumnWidth,
                        wordColumnHeight: wordColumnHeight,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
