// game_scores_component.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles/app_styles.dart';
import '../logic/spelled_words_handler.dart';
import '../managers/gameLayoutManager.dart';
import '../providers/game_state_provider.dart';
import '../models/boardState.dart';

// Displays the score and word count above the grid
class GameScores extends StatelessWidget {
  final double width;
  final double height;
  final int score;
  final GameLayoutManager gameLayoutManager;

  const GameScores({
    super.key,
    required this.width,
    required this.height,
    required this.score,
    required this.gameLayoutManager,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current board state from the provider
    final gameStateProvider = Provider.of<GameStateProvider>(context);
    final boardState = gameStateProvider.boardState;

    // Raw word count (no padding with zeros or spaces)
    String wordCount = SpelledWordsLogic.spelledWords.length.toString();

    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Score section with icon (left)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 0.9), // Fine-tune icon alignment
                  child: Icon(
                    Icons.stars_rounded,
                    color: AppStyles.spelledWordsTitleColor,
                    size: gameLayoutManager.scoreFontSize * 1.2,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Score: ${SpelledWordsLogic.score}',
                  style: TextStyle(
                    fontSize: gameLayoutManager.scoreFontSize,
                    fontWeight: GameLayoutManager().defaultFontWeight,
                    color: AppStyles.spelledWordsTitleColor,
                  ),
                ),
              ],
            ),

            // Board State Icon (center)
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(color: boardState.color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(boardState.icon, color: boardState.color, size: gameLayoutManager.scoreFontSize * 1.1),
            ),

            // Words Found section with icon (right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 0.5), // Fine-tune icon alignment
                  child: Icon(
                    Icons.format_list_numbered_rounded,
                    color: AppStyles.spelledWordsTitleColor,
                    size: gameLayoutManager.scoreFontSize * 1.2,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Words: $wordCount',
                  style: TextStyle(
                    fontSize: gameLayoutManager.scoreFontSize,
                    fontWeight: GameLayoutManager().defaultFontWeight,
                    color: AppStyles.spelledWordsTitleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
