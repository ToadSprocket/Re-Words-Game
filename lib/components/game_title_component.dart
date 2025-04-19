// lib/components/game_title_component.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:reword_game/managers/gameLayoutManager.dart';
import '../styles/app_styles.dart';
import 'dart:math' as math;
import 'dart:async';
import '../main.dart'; // Import for debug flags

class GameTitleComponent extends StatefulWidget {
  final double width;
  final double height;
  final bool showBorders;
  final GameLayoutManager gameLayoutManager;
  final VoidCallback? onSecretReset; // New callback for secret reset

  const GameTitleComponent({
    super.key,
    required this.width,
    required this.height,
    this.showBorders = false,
    required this.gameLayoutManager,
    this.onSecretReset, // Add optional callback
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

  @override
  State<GameTitleComponent> createState() => _GameTitleComponentState();
}

class _GameTitleComponentState extends State<GameTitleComponent> {
  late String _slogan;
  int _clickCount = 0;
  Timer? _clickTimer;

  @override
  void initState() {
    super.initState();
    // Generate the slogan once when the widget is initialized
    _slogan = _getRandomSlogan();
  }

  @override
  void dispose() {
    _clickTimer?.cancel();
    super.dispose();
  }

  String _getRandomSlogan() {
    final random = math.Random();
    return GameTitleComponent.slogans[random.nextInt(GameTitleComponent.slogans.length)];
  }

  void _handleTitleTap() {
    // If secret reset is disabled, don't count clicks
    if (debugDisableSecretReset) {
      return;
    }

    _clickCount++;

    // Reset click count after 2 seconds of inactivity
    _clickTimer?.cancel();
    _clickTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _clickCount = 0;
        });
      }
    });

    // If 5 clicks detected, trigger reset
    if (_clickCount >= 5) {
      _clickCount = 0;
      _clickTimer?.cancel();

      // Call the reset callback if provided
      if (widget.onSecretReset != null) {
        widget.onSecretReset!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Re-Word Game';

    return GestureDetector(
      onTap: _handleTitleTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: widget.showBorders ? BoxDecoration(border: Border.all(color: Colors.purple, width: 1)) : null,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: widget.height * 0.001),
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
                          fontSize: widget.gameLayoutManager.titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppStyles.headerTextColor,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 1.0),
            Text(
              _slogan,
              style: TextStyle(
                fontSize: widget.gameLayoutManager.sloganFontSize,
                fontWeight: FontWeight.normal,
                color: AppStyles.titleSloganTextColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
