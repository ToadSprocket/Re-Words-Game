// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../components/wildcard_column_component.dart';
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../components/game_scores_component.dart';
import '../components/game_grid_component.dart';
import '../components/game_buttons_component.dart';
import '../components/spelled_words_ticker_component.dart';
import '../logic/spelled_words_handler.dart';
import '../components/game_message_component.dart';
import '../logic/logging_handler.dart';

class NarrowScreen extends StatelessWidget {
  final bool showBorders;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;
  final VoidCallback onLogin;
  final GlobalKey<GameGridComponentState>? gridKey;
  final GlobalKey<WildcardColumnComponentState>? wildcardKey;
  final ValueChanged<String>? onMessage;
  final ValueNotifier<String> messageNotifier;
  final ValueNotifier<int> scoreNotifier; // Add this
  final ValueNotifier<List<String>> spelledWordsNotifier; // Add this
  final VoidCallback updateScoresRefresh; // Add this
  final dynamic api; // Add this
  final dynamic gameLayoutManager;
  final SpelledWordsLogic spelledWordsLogic;

  const NarrowScreen({
    super.key,
    required this.showBorders,
    required this.onSubmit,
    required this.onClear,
    required this.onInstructions,
    required this.onHighScores,
    required this.onLegal,
    required this.onLogin,
    required this.api,
    required this.gameLayoutManager,
    required this.spelledWordsLogic,
    this.gridKey,
    this.wildcardKey,
    this.onMessage,
    required this.messageNotifier,
    required this.scoreNotifier,
    required this.spelledWordsNotifier,
    required this.updateScoresRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GameTopBarComponent(
          onInstructions: onInstructions,
          onHighScores: onHighScores,
          onLegal: onLegal,
          onLogin: onLogin,
          api: api,
          spelledWordsLogic: SpelledWordsLogic(), // Pass this
          showBorders: showBorders,
          gameLayoutManager: gameLayoutManager,
        ),
        const Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
        const SizedBox(height: 10.0),
        GameTitleComponent(
          width: 300,
          height: 150, // Pass height here
          showBorders: false,
          gameLayoutManager: gameLayoutManager,
        ), // Const to avoid rebuild
        const SizedBox(height: 20.0),
        ValueListenableBuilder<List<String>>(
          valueListenable: spelledWordsNotifier,
          builder: (context, words, child) {
            LogService.logDebug('SpelledWordsTickerComponent rebuild');
            return SpelledWordsTickerComponent(
              gridSize: gameLayoutManager.gridWidthSize,
              squareSize: gameLayoutManager.gridSquareSize,
              words: words,
              gameLayoutManager: gameLayoutManager,
            );
          },
        ),
        const SizedBox(height: 20.0),
        ValueListenableBuilder<int>(
          valueListenable: scoreNotifier,
          builder: (context, score, child) {
            LogService.logDebug('GameScoresComponent rebuild');
            return GameScores(
              width: gameLayoutManager.gridWidthSize,
              height: 100,
              score: score,
              gameLayoutManager: gameLayoutManager,
            );
          },
        ),
        SizedBox(height: gameLayoutManager.gridSpacing),
        GameGridComponent(
          key: gridKey,
          showBorders: showBorders,
          onMessage: onMessage,
          updateScoresRefresh: updateScoresRefresh, // Pass this
          gameLayoutManager: gameLayoutManager,
        ),
        SizedBox(height: gameLayoutManager.gridSpacing),
        WildcardColumnComponent(
          key: wildcardKey,
          width: gameLayoutManager.gridWidthSize,
          height: gameLayoutManager.gridSquareSize * 2,
          showBorders: showBorders,
          isHorizontal: true,
          gridSpacing: gameLayoutManager.gridSpacing,
          gameLayoutManager: gameLayoutManager,
        ),
        const SizedBox(height: 5.0),
        ValueListenableBuilder<String>(
          valueListenable: messageNotifier,
          builder: (context, message, child) {
            LogService.logDebug('GameMessageComponent rebuild');
            return GameMessageComponent(width: gameLayoutManager.gridWidthSize, height: 100, message: message);
          },
        ),
        const SizedBox(height: 5.0),
        GameButtonsComponent(onSubmit: onSubmit, onClear: onClear, gameLayoutManager: gameLayoutManager),
      ],
    );
  }
}
