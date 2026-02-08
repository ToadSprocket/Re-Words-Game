// layouts/game_buttons.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../managers/gameManager.dart';

class GameButtonsComponent extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const GameButtonsComponent({super.key, required this.onSubmit, required this.onClear});

  @override
  Widget build(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;

    return SizedBox(
      height: layout.gameButtonsComponentHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: onSubmit,
                style: layout.buttonStyle(context),
                child: Transform.translate(offset: Offset(0, layout.buttonTextOffset), child: const Text("Submit")),
              ),
              const SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: onClear,
                style: layout.buttonStyle(context),
                child: Transform.translate(offset: Offset(0, layout.buttonTextOffset), child: const Text("Clear")),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
