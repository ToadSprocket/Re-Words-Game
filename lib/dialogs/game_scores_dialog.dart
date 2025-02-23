// layouts/game_scores.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/spelled_words_handler.dart';

// Displays the score and word count above the grid
class GameScores extends StatelessWidget {
  final double width;

  const GameScores({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    // Raw word count (no padding with zeros or spaces)
    String wordCount = SpelledWordsLogic.spelledWords.length.toString();

    return Container(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score on left, no padding
          Text(
            'Score: ${SpelledWordsLogic.score}',
            style: TextStyle(
              fontSize: AppStyles.spelledWordsTitleFontSize,
              fontWeight: FontWeight.bold,
              color: AppStyles.spelledWordsTitleColor,
            ),
          ),
          // Words Found on right with padding to prevent shifting
          Padding(
            padding: const EdgeInsets.only(right: 24.0), // Fixed space to fit 3 digits
            child: Text(
              'Words Found: $wordCount',
              style: TextStyle(
                fontSize: AppStyles.spelledWordsTitleFontSize,
                fontWeight: FontWeight.bold,
                color: AppStyles.spelledWordsTitleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
