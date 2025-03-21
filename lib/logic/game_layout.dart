// game_layout.dart
import 'package:flutter/material.dart';
import '../managers/gameLayoutManager.dart'; // Import GameLayoutManager

class GameLayout extends InheritedWidget {
  final GameLayoutManager gameLayoutManager;

  const GameLayout({super.key, required this.gameLayoutManager, required super.child});

  // Called when the widget updates (e.g., on hot reload or state change)
  @override
  bool updateShouldNotify(covariant GameLayout oldWidget) {
    // Trigger rebuild if gameLayoutManager changes
    // Since GameLayoutManager is a singleton, compare key properties
    return oldWidget.gameLayoutManager.screenWidth != gameLayoutManager.screenWidth ||
        oldWidget.gameLayoutManager.screenHeight != gameLayoutManager.screenHeight ||
        oldWidget.gameLayoutManager.gridSquareSize != gameLayoutManager.gridSquareSize ||
        oldWidget.gameLayoutManager.gameContainerHeight != gameLayoutManager.gameContainerHeight;
  }

  // Static method to access GameLayoutManager from descendants
  static GameLayoutManager of(BuildContext context) {
    final gameLayout = context.dependOnInheritedWidgetOfExactType<GameLayout>();
    if (gameLayout == null) {
      throw FlutterError('No GameLayout found in context');
    }
    return gameLayout.gameLayoutManager;
  }
}

class GameLayoutProvider extends StatelessWidget {
  final Widget child;
  final GameLayoutManager gameLayoutManager;

  const GameLayoutProvider({super.key, required this.child, required this.gameLayoutManager});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Recalculate sizes whenever the layout constraints change
        gameLayoutManager.calculateLayoutSizes(context);
        return GameLayout(gameLayoutManager: gameLayoutManager, child: child);
      },
    );
  }
}
