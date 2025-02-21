// layouts/game_top_bar.dart
import 'package:flutter/material.dart';

class GameTopBar extends StatelessWidget {
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;

  const GameTopBar({super.key, required this.onInstructions, required this.onHighScores, required this.onLegal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.help_outline), // Circled question mark
            onPressed: onInstructions,
            tooltip: 'How to Play',
          ),
          const SizedBox(width: 16.0),
          IconButton(
            icon: const Icon(Icons.emoji_events), // Trophy for high scores
            onPressed: onHighScores,
            tooltip: 'High Scores',
          ),
          const SizedBox(width: 16.0),
          IconButton(
            icon: const Icon(Icons.copyright), // Copyright symbol
            onPressed: onLegal,
            tooltip: 'Legal',
          ),
        ],
      ),
    );
  }
}
