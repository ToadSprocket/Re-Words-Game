// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../managers/gameLayoutManager.dart';
import '../logic/spelled_words_handler.dart';
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../components/game_scores_component.dart';
import '../components/game_grid_component.dart';
import '../components/game_buttons_component.dart';
import '../components/spelled_words_ticker_component.dart';
import '../components/game_message_component.dart';
import '../logic/logging_handler.dart';
import '../components/wildcard_column_component.dart';

class NarrowScreen extends StatelessWidget {
  final bool showBorders;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;
  final VoidCallback onLogin;
  final ApiService api;
  final GameLayoutManager gameLayoutManager;
  final SpelledWordsLogic spelledWordsLogic;
  final GlobalKey<GameGridComponentState> gridKey;
  final GlobalKey wildcardKey;
  final Function(String) onMessage;
  final ValueNotifier<String> messageNotifier;
  final ValueNotifier<int> scoreNotifier;
  final ValueNotifier<List<String>> spelledWordsNotifier;
  final VoidCallback updateScoresRefresh;
  final VoidCallback updateCurrentGameState;

  const NarrowScreen({
    super.key,
    this.showBorders = false,
    required this.onSubmit,
    required this.onClear,
    required this.onInstructions,
    required this.onHighScores,
    required this.onLegal,
    required this.onLogin,
    required this.api,
    required this.gameLayoutManager,
    required this.spelledWordsLogic,
    required this.gridKey,
    required this.wildcardKey,
    required this.onMessage,
    required this.messageNotifier,
    required this.scoreNotifier,
    required this.spelledWordsNotifier,
    required this.updateScoresRefresh,
    required this.updateCurrentGameState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GameTopBarComponent(
          onInstructions: onInstructions,
          onHighScores: onHighScores,
          onLegal: onLegal,
          onLogin: onLogin,
          api: api,
          spelledWordsLogic: SpelledWordsLogic(),
          showBorders: showBorders,
          gameLayoutManager: gameLayoutManager,
        ),
        const Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
        Container(
          width: gameLayoutManager.gameContainerWidth,
          child: Column(
            children: [
              SizedBox(height: gameLayoutManager.gridSpacing),
              GameTitleComponent(
                width: gameLayoutManager.gameTitleComponentWidth,
                height: gameLayoutManager.gameTitleComponentHeight,
                showBorders: showBorders,
                gameLayoutManager: gameLayoutManager,
              ),
              SizedBox(height: gameLayoutManager.gridSpacing),
              ValueListenableBuilder<List<String>>(
                valueListenable: spelledWordsNotifier,
                builder: (context, words, child) {
                  LogService.logDebug('SpelledWordsTickerComponent rebuild');
                  return SpelledWordsTickerComponent(
                    gridSize: gameLayoutManager.gameContainerWidth,
                    squareSize: gameLayoutManager.gridSquareSize,
                    words: words,
                    gameLayoutManager: gameLayoutManager,
                  );
                },
              ),
              SizedBox(height: gameLayoutManager.gridSpacing),
              ValueListenableBuilder<int>(
                valueListenable: scoreNotifier,
                builder: (context, score, child) {
                  LogService.logDebug('GameScoresComponent rebuild');
                  return GameScores(
                    width: gameLayoutManager.gridWidthSize,
                    height: gameLayoutManager.gameScoresComponentHeight,
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
                updateScoresRefresh: updateScoresRefresh,
                gameLayoutManager: gameLayoutManager,
                disableSpellCheck: spelledWordsLogic.disableSpellCheck,
                updateCurrentGameState: updateCurrentGameState,
              ),
              SizedBox(height: gameLayoutManager.gridSpacing * 0.7), // Reduced spacing by 30%
              ValueListenableBuilder<String>(
                valueListenable: messageNotifier,
                builder: (context, message, child) {
                  LogService.logDebug('GameMessageComponent rebuild');
                  return GameMessageComponent(
                    width: gameLayoutManager.gameMessageComponentWidth,
                    height: gameLayoutManager.gameMessageComponentHeight,
                    message: message,
                    gameLayoutManager: gameLayoutManager,
                  );
                },
              ),

              WildcardColumnComponent(
                key: wildcardKey,
                width: gameLayoutManager.gameContainerWidth,
                height: gameLayoutManager.wilcardsContainerHeight,
                showBorders: showBorders,
                isHorizontal: true,
                gridSpacing: gameLayoutManager.gridSpacing,
                gameLayoutManager: gameLayoutManager,
              ),

              //SizedBox(height: gameLayoutManager.gridSpacing * 0.4), // Reduced spacing by 30%
              GameButtonsComponent(onSubmit: onSubmit, onClear: onClear, gameLayoutManager: gameLayoutManager),
            ],
          ),
        ),
      ],
    );
  }
}
