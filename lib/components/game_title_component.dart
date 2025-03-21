// lib/components/game_title_component.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:reword_game/managers/gameLayoutManager.dart';
import '../styles/app_styles.dart';
import 'dart:math' as math;

class GameTitleComponent extends StatelessWidget {
  final double width;
  final double height; // New prop for height
  final bool showBorders;
  final GameLayoutManager gameLayoutManager;

  const GameTitleComponent({
    super.key,
    required this.width,
    required this.height, // Require height
    this.showBorders = false,
    required this.gameLayoutManager,
  });

  static const List<String> slogans = [
    "Re-Think. Re-Use. Re-Word!",
    "Every Letter Counts, Every Play Matters!",
    "Find Words, Stack Scores, Win Big!",
    "Smart Plays. Big Scores. Re-Word!",
    "A Game of Words and Strategy!",
    "Use. Reuse. Dominate!",
    "Think Twice, Score Big!",
    "More Than Just Words—It's Strategy!",
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
      height: height,
      decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.purple, width: 1)) : null,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: height * 0.001),
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
                        fontSize: gameLayoutManager.titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.headerTextColor,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 1.0),
          Text(
            slogan,
            style: TextStyle(
              fontSize: gameLayoutManager.sloganFontSize,
              fontWeight: FontWeight.normal,
              color: AppStyles.titleSloganTextColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
