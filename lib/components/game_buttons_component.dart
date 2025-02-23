// layouts/game_buttons.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class GameButtons extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const GameButtons({super.key, required this.onSubmit, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onSubmit,
          style: AppStyles.buttonStyle(context),
          child: Transform.translate(
            offset: Offset(0, AppStyles.buttonTextOffset), // -4.0 moves up
            child: const Text("Submit"),
          ),
        ),
        const SizedBox(width: 16.0),
        ElevatedButton(
          onPressed: onClear,
          style: AppStyles.buttonStyle(context),
          child: Transform.translate(
            offset: Offset(0, AppStyles.buttonTextOffset), // -4.0 moves up
            child: const Text("Clear"),
          ),
        ),
      ],
    );
  }
}
