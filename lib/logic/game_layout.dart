// lib/logic/game_layout.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import 'layout_calculator.dart';

class GameLayout extends InheritedWidget {
  final Map<String, dynamic> sizes; // Changed to dynamic for bool

  const GameLayout({super.key, required this.sizes, required super.child});

  static GameLayout of(BuildContext context) {
    final gameLayout = context.dependOnInheritedWidgetOfExactType<GameLayout>();
    print('GameLayout.of called - context: $context, result: $gameLayout');
    if (gameLayout == null) {
      print('GameLayout.of - WARNING: GameLayout is null!');
    }
    return gameLayout!;
  }

  @override
  bool updateShouldNotify(GameLayout oldWidget) {
    return sizes != oldWidget.sizes;
  }
}

class GameLayoutProvider extends StatelessWidget {
  final Widget child;

  const GameLayoutProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final sizes = LayoutCalculator.calculateSizes(context);
    return GameLayout(sizes: sizes, child: child);
  }
}
