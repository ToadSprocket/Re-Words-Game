// lib/logic/game_layout.dart
import 'package:flutter/material.dart';
import 'layout_calculator.dart';

class GameLayout extends InheritedWidget {
  final Map<String, double> sizes;

  const GameLayout({super.key, required this.sizes, required super.child});

  static GameLayout of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GameLayout>()!;
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
