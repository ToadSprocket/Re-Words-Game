// screens/wide_screen.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/wildcard_column_component.dart';
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../components/game_scores_component.dart';
import '../components/game_grid_component.dart';
import '../components/game_buttons_component.dart';
import '../components/spelled_words_column_component.dart';
import '../components/game_message_component.dart';
import '../logic/spelled_words_handler.dart';
import '../logic/grid_loader.dart'; // Add GridLoader import
import '../managers/gameLayoutManager.dart';
import '../managers/state_manager.dart'; // Add StateManager import
import '../services/api_service.dart';
import '../models/tile.dart'; // Add Tile import
import '../main.dart'; // Import HomeScreen from main.dart
import '../providers/game_state_provider.dart'; // Import GameStateProvider

class WideScreen extends StatelessWidget {
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

  const WideScreen({
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
    const borderWidth = 1.0;
    final screenWidth = gameLayoutManager.screenWidth;
    final screenHeight = gameLayoutManager.screenHeight;

    return SizedBox(
      width: screenWidth,
      height: screenHeight,
      child: Container(
        decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.yellow, width: borderWidth)) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container 1: Top Bar Area
            SizedBox(
              width: screenWidth,
              height: gameLayoutManager.infoBoxHeight - (showBorders ? 2 * borderWidth : 0), // Corrected typo
              child: Container(
                decoration:
                    showBorders ? BoxDecoration(border: Border.all(color: Colors.orange, width: borderWidth)) : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GameTopBarComponent(
                      onInstructions: onInstructions,
                      onHighScores: onHighScores,
                      onLegal: onLegal,
                      showBorders: showBorders,
                      onLogin: onLogin,
                      api: api,
                      spelledWordsLogic: spelledWordsLogic,
                      gameLayoutManager: gameLayoutManager,
                    ),
                    const Divider(height: 1.0, thickness: 1.0, color: Color.fromARGB(237, 94, 94, 94)),
                  ],
                ),
              ),
            ),
            // Container 2: Game Area with Three Columns
            SizedBox(
              width: screenWidth,
              height: gameLayoutManager.gameBoxHeight - (showBorders ? 2 * borderWidth : 0), // Corrected typo
              child: Container(
                decoration:
                    showBorders
                        ? BoxDecoration(
                          border: Border.all(color: const Color.fromARGB(255, 3, 226, 255), width: borderWidth),
                        )
                        : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Wildcards
                    SizedBox(
                      width: gameLayoutManager.wildcardContainerWidth - (showBorders ? 2 * borderWidth : 0),
                      height: gameLayoutManager.wilcardsContainerHeight,
                      child: Container(
                        decoration:
                            showBorders
                                ? BoxDecoration(
                                  border: Border.all(color: const Color.fromARGB(255, 216, 2, 245), width: borderWidth),
                                )
                                : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height:
                                  gameLayoutManager.gameTitleComponentHeight +
                                  gameLayoutManager.gameScoresComponentHeight,
                            ), // Matches title + scores
                            WildcardColumnComponent(
                              key: wildcardKey,
                              width: gameLayoutManager.wildcardContainerWidth - (showBorders ? 2 * borderWidth : 0),
                              height: gameLayoutManager.gridHeightSize,
                              showBorders: showBorders,
                              isHorizontal: false,
                              gridSpacing: gameLayoutManager.gridSpacing,
                              gameLayoutManager: gameLayoutManager,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Center Column: Game Content
                    SizedBox(
                      width: gameLayoutManager.gameContainerWidth - (showBorders ? 2 * borderWidth : 0),
                      height: gameLayoutManager.gameContainerHeight,
                      child: Container(
                        decoration:
                            showBorders
                                ? BoxDecoration(border: Border.all(color: Colors.red, width: borderWidth))
                                : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            ValueListenableBuilder<int>(
                              valueListenable: scoreNotifier,
                              builder: (context, score, child) {
                                return GameScores(
                                  width: gameLayoutManager.gridWidthSize,
                                  height: gameLayoutManager.gameScoresComponentHeight,
                                  score: score,
                                  gameLayoutManager: gameLayoutManager,
                                );
                              },
                            ),
                            GameGridComponent(
                              key: gridKey,
                              showBorders: showBorders,
                              onMessage: onMessage,
                              updateScoresRefresh: updateScoresRefresh,
                              gameLayoutManager: gameLayoutManager,
                              disableSpellCheck: spelledWordsLogic.disableSpellCheck,
                              updateCurrentGameState: updateCurrentGameState,
                            ),
                            ValueListenableBuilder<String>(
                              valueListenable: messageNotifier,
                              builder: (context, message, child) {
                                return GameMessageComponent(
                                  width: gameLayoutManager.gameMessageComponentWidth,
                                  height: gameLayoutManager.gameMessageComponentHeight, // Fixed prop values
                                  message: message,
                                  gameLayoutManager: gameLayoutManager,
                                );
                              },
                            ),
                            GameButtonsComponent(
                              onSubmit: onSubmit,
                              onClear: onClear,
                              gameLayoutManager: gameLayoutManager,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right Column: Spelled Words
                    SizedBox(
                      width: gameLayoutManager.spelledWordsContainerWidth - (showBorders ? 2 * borderWidth : 0),
                      height: gameLayoutManager.gameContainerHeight,
                      child: Container(
                        decoration:
                            showBorders
                                ? BoxDecoration(
                                  border: Border.all(color: const Color.fromARGB(255, 175, 76, 76), width: borderWidth),
                                )
                                : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height:
                                  gameLayoutManager.gameTitleComponentHeight +
                                  gameLayoutManager.gameScoresComponentHeight -
                                  2,
                            ), // Matches title + scores, aligns with wildcards
                            ValueListenableBuilder<List<String>>(
                              valueListenable: spelledWordsNotifier,
                              builder: (context, words, child) {
                                return SpelledWordsColumnComponent(
                                  words: words,
                                  columnWidth: gameLayoutManager.spelledWordsContainerWidth,
                                  columnHeight:
                                      gameLayoutManager.gridHeightSize +
                                      gameLayoutManager.gameMessageComponentHeight +
                                      gameLayoutManager.gameButtonsComponentHeight,
                                  gridSpacing: gameLayoutManager.spelledWordsGridSpacing,
                                  showBorders: showBorders,
                                  wordColumnHeight:
                                      gameLayoutManager.gridHeightSize +
                                      gameLayoutManager.gameMessageComponentHeight +
                                      gameLayoutManager.gameButtonsComponentHeight,
                                  gameLayoutManager: gameLayoutManager,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
