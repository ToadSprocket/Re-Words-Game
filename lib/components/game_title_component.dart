// File: /lib/components/game_title_component.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:reword_game/managers/gameLayoutManager.dart';
import '../styles/app_styles.dart';
import 'dart:math' as math;
import 'dart:async';
import '../managers/gameManager.dart';
import '../config/debugConfig.dart';

class GameTitleComponent extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback? onSecretReset;

  const GameTitleComponent({super.key, required this.width, required this.height, this.onSecretReset});

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
    if (DebugConfig().disableSecretReset) return;

    _clickCount++;

    _clickTimer?.cancel();
    _clickTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _clickCount = 0;
        });
      }
    });

    if (_clickCount >= 5) {
      _clickCount = 0;
      _clickTimer?.cancel();
      if (widget.onSecretReset != null) {
        widget.onSecretReset!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;
    const title = 'Re-Word Game';

    return GestureDetector(
      onTap: _handleTitleTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration:
            DebugConfig().showBorders ? BoxDecoration(border: Border.all(color: Colors.purple, width: 1)) : null,
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
                          fontSize: layout.titleFontSize,
                          fontWeight: GameLayoutManager().defaultFontWeight,
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
                fontSize: layout.sloganFontSize,
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
