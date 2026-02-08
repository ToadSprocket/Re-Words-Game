// File: /lib/screens/narrow_screen.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/gameManager.dart';
import '../components/game_top_bar_component.dart';
import '../components/game_title_component.dart';
import '../components/game_scores_component.dart';
import '../components/game_grid_component.dart';
import '../components/game_buttons_component.dart';
import '../components/spelled_words_ticker_component.dart';
import '../components/game_message_component.dart';
import '../components/wildcard_column_component.dart';

class NarrowScreen extends StatelessWidget {
  const NarrowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get GameManager from Provider - rebuilds when notifyListeners() is called
    final gm = context.watch<GameManager>();
    final layout = gm.layoutManager!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Top Bar - instructions, high scores, legal, login
        GameTopBarComponent(),
        Container(
          width: layout.gameContainerWidth,
          child: Column(
            children: [
              SizedBox(height: layout.gridSpacing),
              // Title with secret reset
              GameTitleComponent(
                width: layout.gameTitleComponentWidth,
                height: layout.gameTitleComponentHeight,
                onSecretReset: () => gm.secretReset(),
              ),
              SizedBox(height: layout.gridSpacing),
              // Spelled words ticker - reads from board
              SpelledWordsTickerComponent(
                gridSize: layout.gameContainerWidth,
                squareSize: layout.gridSquareSize,
                words: gm.board.spelledWords, // Direct from board!
              ),
              SizedBox(height: layout.gridSpacing),
              // Score display - reads from board
              GameScores(
                width: layout.gridWidthSize,
                height: layout.gameScoresComponentHeight,
                score: gm.board.score, // Direct from board!
              ),
              SizedBox(height: layout.gridSpacing),
              // Game grid
              GameGridComponent(key: gm.gridKey),
              SizedBox(height: layout.gridSpacing),
              // Message display
              GameMessageComponent(
                width: layout.gameMessageComponentWidth,
                height: layout.gameMessageComponentHeight,
                message: gm.message, // Direct from GameManager!
              ),
              // Wildcards (horizontal in narrow)
              WildcardColumnComponent(
                key: gm.wildcardKey,
                width: layout.gameContainerWidth,
                height: layout.wilcardsContainerHeight,
                isHorizontal: true,
                gridSpacing: layout.gridSpacing,
              ),
              SizedBox(height: layout.gridSpacing),
              // Buttons
              GameButtonsComponent(onSubmit: () => gm.submitWord(), onClear: () => gm.clearWords()),
            ],
          ),
        ),
      ],
    );
  }
}
