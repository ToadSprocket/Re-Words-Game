// lib/components/game_title_component.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'dart:math' as math;

class GameTitleComponent extends StatelessWidget {
  final double width;
  final bool showBorders;

  const GameTitleComponent({super.key, required this.width, this.showBorders = false});

  static const List<String> slogans = [
    "Re-Think. Re-Use. Re-Word!",
    "Every Letter Counts, Every Play Matters!",
    "Find Words, Stack Scores, Win Big!",
    "Smart Plays. Big Scores. Re-Word!",
    "A Game of Words and Strategy!",
    "Use. Reuse. Dominate!",
    "Think Twice, Score Big!",
    "More Than Just Words—It’s Strategy!",
    "Rearrange, Reuse, Rule!",
    "Multiply Your Words, Maximize Your Score!",
  ];

  String getRandomSlogan() {
    final random = math.Random();
    return slogans[random.nextInt(slogans.length)];
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Re-Word Game';
    final slogan = getRandomSlogan();

    return Container(
      width: width,
      decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.purple, width: 2)) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                title.split('').asMap().entries.map((entry) {
                  final index = entry.key;
                  final letter = entry.value;
                  final angle = (index % 2 == 0) ? 10 * math.pi / 180 : -10 * math.pi / 180;
                  return Transform.rotate(
                    angle: angle,
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: AppStyles.headerFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.headerTextColor,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 4.0), // Space between title and slogan
          Text(
            slogan,
            style: TextStyle(
              fontSize: AppStyles.headerFontSize * 0.5, // Smaller than title
              fontWeight: FontWeight.normal, // Less bold
              color: AppStyles.usedValueTextColor.withOpacity(0.8), // Slightly faded
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
