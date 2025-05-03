// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../managers/gameLayoutManager.dart';
import '../managers/state_manager.dart'; // Add StateManager import
import '../logic/spelled_words_handler.dart';
import '../logic/grid_loader.dart'; // Add GridLoader import
import '../providers/game_state_provider.dart'; // Import GameStateProvider
import '../utils/device_utils.dart'; // Import DeviceUtils
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../components/game_scores_component.dart';
import '../components/game_grid_component.dart';
import '../components/game_buttons_component.dart';
import '../components/spelled_words_ticker_component.dart';
import '../components/game_message_component.dart';
import '../logic/logging_handler.dart';
import '../components/wildcard_column_component.dart';
import '../models/tile.dart'; // Add Tile import
import '../main.dart'; // Import HomeScreen from main.dart

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
                onSecretReset: () {
                  // Show a message that the board is being reset
                  onMessage("Secret reset activated! Loading new board...");

                  // Get the BuildContext from the current widget
                  final context = gridKey.currentContext!;

                  // Schedule the reset after the UI updates
                  Future.delayed(const Duration(milliseconds: 500), () async {
                    // First, reset the state to clear spelled words and wildcards
                    await StateManager.resetState(gridKey);

                    // Explicitly update the spelled words notifier with an empty list
                    SpelledWordsLogic.spelledWords = [];
                    SpelledWordsLogic.score = 0;
                    SpelledWordsLogic.wildCardUses = 0;

                    // Update scores and spelled words notifiers
                    scoreNotifier.value = 0;
                    spelledWordsNotifier.value = [];

                    // Reset the board state to newBoard using GameStateProvider
                    final gameStateProvider = Provider.of<GameStateProvider>(context, listen: false);
                    gameStateProvider.resetState();
                    await gameStateProvider.saveState();

                    // Then load a new board
                    final api = Provider.of<ApiService>(context, listen: false);
                    final score = await SpelledWordsLogic.getCurrentScore();

                    // Clear the existing tiles
                    GridLoader.gridTiles.clear();
                    GridLoader.wildcardTiles.clear();

                    // Load a new board
                    await GridLoader.loadNewBoard(api, score);

                    // Create new Tile objects from the GridLoader data
                    if (gridKey.currentState != null) {
                      final newGridTiles =
                          GridLoader.gridTiles.map((tileData) {
                            return Tile(
                              letter: tileData['letter'],
                              value: tileData['value'],
                              isExtra: false,
                              isRemoved: false,
                            );
                          }).toList();

                      // Set the new tiles in the GameGridComponent
                      gridKey.currentState!.setTiles(newGridTiles);
                    }

                    // Create new wildcard Tile objects
                    if (wildcardKey.currentState != null) {
                      final wildcardState = wildcardKey.currentState as WildcardColumnComponentState;
                      final newWildcardTiles =
                          GridLoader.wildcardTiles.map((tileData) {
                            return Tile(
                              letter: tileData['letter'],
                              value: tileData['value'],
                              isExtra: true,
                              isRemoved: false,
                            );
                          }).toList();

                      // Set the new tiles in the WildcardColumnComponent
                      wildcardState.tiles = newWildcardTiles;
                      wildcardState.setState(() {});
                    }

                    updateScoresRefresh();
                  });
                },
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
              SizedBox(height: gameLayoutManager.gridSpacing),
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
              SizedBox(height: gameLayoutManager.gridSpacing),
              GameButtonsComponent(onSubmit: onSubmit, onClear: onClear, gameLayoutManager: gameLayoutManager),
            ],
          ),
        ),
      ],
    );
  }
}
