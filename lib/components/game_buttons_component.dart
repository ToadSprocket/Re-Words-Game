// layouts/game_buttons.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../managers/gameLayoutManager.dart';

class GameButtonsComponent extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final GameLayoutManager gameLayoutManager;

  const GameButtonsComponent({
    super.key,
    required this.onSubmit,
    required this.onClear,
    required this.gameLayoutManager,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onSubmit,
          style: gameLayoutManager.buttonStyle(context),
          child: Transform.translate(
            offset: Offset(0, gameLayoutManager.buttonTextOffset), // -4.0 moves up
            child: const Text("Submit"),
          ),
        ),
        const SizedBox(width: 16.0),
        ElevatedButton(
          onPressed: onClear,
          style: gameLayoutManager.buttonStyle(context),
          child: Transform.translate(
            offset: Offset(0, gameLayoutManager.buttonTextOffset), // -4.0 moves up
            child: const Text("Clear"),
          ),
        ),
      ],
    );
  }
}
