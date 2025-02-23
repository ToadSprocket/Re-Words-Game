// layouts/game_title.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

// Displays the game title
class GameTitleComponent extends StatelessWidget {
  final double width;
  final bool showBorders;

  const GameTitleComponent({super.key, required this.width, this.showBorders = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.purple, width: 2)) : null,
      child: Center(
        child: Text(
          'Re-Word Game',
          style: TextStyle(
            fontSize: AppStyles.headerFontSize,
            fontWeight: FontWeight.bold,
            color: AppStyles.headerTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
