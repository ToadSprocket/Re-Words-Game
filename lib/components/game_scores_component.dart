// File: /lib/components/game_scores_component.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/game_layout_manager.dart';
import '../managers/gameManager.dart';
import '../models/board_state.dart';

// Displays the score and word count above the grid
class GameScores extends StatelessWidget {
  final double width;
  final double height;
  final int score;

  const GameScores({super.key, required this.width, required this.height, required this.score});

  @override
  Widget build(BuildContext context) {
    // Access layout and board from GameManager
    final gm = GameManager();
    final layout = gm.layoutManager!;
    final boardState = gm.board.boardState;
    String wordCount = gm.board.spelledWords.length.toString();

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
                  padding: const EdgeInsets.only(bottom: 0.9),
                  child: Icon(
                    Icons.stars_rounded,
                    color: AppStyles.spelledWordsTitleColor,
                    size: layout.scoreFontSize * 1.2,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Score: $score',
                  style: TextStyle(
                    fontSize: layout.scoreFontSize,
                    fontWeight: GameLayoutManager().defaultFontWeight,
                    color: AppStyles.spelledWordsTitleColor,
                  ),
                ),
              ],
            ),

            // Board State Icon (center)
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(color: boardState.color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(boardState.icon, color: boardState.color, size: layout.scoreFontSize * 1.1),
            ),

            // Words Found section with icon (right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 0.5),
                  child: Icon(
                    Icons.format_list_numbered_rounded,
                    color: AppStyles.spelledWordsTitleColor,
                    size: layout.scoreFontSize * 1.2,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Words: $wordCount',
                  style: TextStyle(
                    fontSize: layout.scoreFontSize,
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
