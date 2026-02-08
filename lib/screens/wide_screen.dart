// screens/wide_screen.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/gameManager.dart';
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../components/game_scores_component.dart';
import '../components/game_grid_component.dart';
import '../components/game_buttons_component.dart';
import '../components/spelled_words_column_component.dart';
import '../components/game_message_component.dart';
import '../components/wildcard_column_component.dart';

class WideScreen extends StatelessWidget {
  final bool showBorders;

  const WideScreen({super.key, this.showBorders = false});

  @override
  Widget build(BuildContext context) {
    final gm = context.watch<GameManager>();
    final layout = gm.layoutManager!;
    const borderWidth = 1.0;
    final screenWidth = layout.screenWidth;
    final screenHeight = layout.screenHeight;

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
              height: layout.infoBoxHeight - (showBorders ? 2 * borderWidth : 0),
              child: Container(
                decoration:
                    showBorders ? BoxDecoration(border: Border.all(color: Colors.orange, width: borderWidth)) : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [GameTopBarComponent(showBorders: showBorders)],
                ),
              ),
            ),
            // Container 2: Game Area with Three Columns
            SizedBox(
              width: screenWidth,
              height: layout.gameBoxHeight - (showBorders ? 2 * borderWidth : 0),
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
                      width: layout.wildcardContainerWidth - (showBorders ? 2 * borderWidth : 0),
                      height: layout.wilcardsContainerHeight,
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
                              height: layout.gameTitleComponentHeight + layout.gameScoresComponentHeight,
                            ), // Matches title + scores
                            WildcardColumnComponent(
                              key: gm.wildcardKey,
                              width: layout.wildcardContainerWidth - (showBorders ? 2 * borderWidth : 0),
                              height: layout.gridHeightSize,
                              showBorders: showBorders,
                              isHorizontal: false,
                              gridSpacing: layout.gridSpacing,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Center Column: Game Content
                    SizedBox(
                      width: layout.gameContainerWidth - (showBorders ? 2 * borderWidth : 0),
                      height: layout.gameContainerHeight,
                      child: Container(
                        decoration:
                            showBorders
                                ? BoxDecoration(border: Border.all(color: Colors.red, width: borderWidth))
                                : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameTitleComponent(
                              width: layout.gameTitleComponentWidth,
                              height: layout.gameTitleComponentHeight,
                              showBorders: showBorders,
                              onSecretReset: () => gm.secretReset(),
                            ),
                            GameScores(
                              width: layout.gridWidthSize,
                              height: layout.gameScoresComponentHeight,
                              score: gm.board.score,
                            ),
                            GameGridComponent(key: gm.gridKey, showBorders: showBorders),
                            GameMessageComponent(
                              width: layout.gameMessageComponentWidth,
                              height: layout.gameMessageComponentHeight,
                              message: gm.message,
                            ),
                            GameButtonsComponent(onSubmit: () => gm.submitWord(), onClear: () => gm.clearWords()),
                          ],
                        ),
                      ),
                    ),
                    // Right Column: Spelled Words
                    SizedBox(
                      width: layout.spelledWordsContainerWidth - (showBorders ? 2 * borderWidth : 0),
                      height: layout.gameContainerHeight,
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
                              height: layout.gameTitleComponentHeight + layout.gameScoresComponentHeight - 2,
                            ), // Matches title + scores, aligns with wildcards
                            SpelledWordsColumnComponent(
                              words: gm.board.spelledWords,
                              columnWidth: layout.spelledWordsContainerWidth,
                              columnHeight:
                                  layout.gridHeightSize +
                                  layout.gameMessageComponentHeight +
                                  layout.gameButtonsComponentHeight,
                              gridSpacing: layout.spelledWordsGridSpacing,
                              showBorders: showBorders,
                              wordColumnHeight:
                                  layout.gridHeightSize +
                                  layout.gameMessageComponentHeight +
                                  layout.gameButtonsComponentHeight,
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
