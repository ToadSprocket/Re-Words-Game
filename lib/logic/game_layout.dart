// File: /lib/logic/game_layout.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../managers/game_layout_manager.dart'; // Import GameLayoutManager

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

class GameLayoutProvider extends StatefulWidget {
  final Widget child;
  final GameLayoutManager gameLayoutManager;

  const GameLayoutProvider({super.key, required this.child, required this.gameLayoutManager});

  @override
  State<GameLayoutProvider> createState() => _GameLayoutProviderState();
}

class _GameLayoutProviderState extends State<GameLayoutProvider> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // We'll calculate sizes in didChangeDependencies instead of here
        return GameLayout(gameLayoutManager: widget.gameLayoutManager, child: widget.child);
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Calculate layout sizes here instead of in the build method
    // This is safe in didChangeDependencies
    widget.gameLayoutManager.calculateLayoutSizes(context);
  }
}
