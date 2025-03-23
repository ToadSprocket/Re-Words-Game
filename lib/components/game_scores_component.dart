// game_scores_component.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/spelled_words_handler.dart';
import '../managers/gameLayoutManager.dart';

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
    // Raw word count (no padding with zeros or spaces)
    String wordCount = SpelledWordsLogic.spelledWords.length.toString();

    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Score section with icon
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
                    fontWeight: FontWeight.bold,
                    color: AppStyles.spelledWordsTitleColor,
                  ),
                ),
              ],
            ),
            // Words Found section with icon
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
                    fontWeight: FontWeight.bold,
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
