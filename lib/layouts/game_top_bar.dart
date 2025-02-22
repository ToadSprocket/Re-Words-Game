// layouts/game_top_bar.dart
import 'package:flutter/material.dart';
import '/styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GameTopBar extends StatelessWidget {
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;
  final bool showBorders;

  const GameTopBar({
    super.key,
    required this.onInstructions,
    required this.onHighScores,
    required this.onLegal,
    required this.showBorders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 1.0)) : null,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.circleQuestion, size: 20.0, color: AppStyles.helpIconColor),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: onInstructions,
              tooltip: 'How to Play',
            ),
            const SizedBox(width: 6.0),
            IconButton(
              icon: const Icon(FontAwesomeIcons.chartSimple, size: 20.0, color: AppStyles.helpIconColor),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: onHighScores,
              tooltip: 'High Scores',
            ),
            const SizedBox(width: 6.0),
            IconButton(
              icon: const Icon(FontAwesomeIcons.gavel, size: 20.0, color: AppStyles.helpIconColor),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: onLegal,
              tooltip: 'Legal',
            ),
          ],
        ),
      ),
    );
  }
}
