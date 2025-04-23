// lib/dialogs/welcome_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameLayoutManager.dart';
import '../components/intro_animation.dart';

class WelcomeDialog {
  static Future<void> show(BuildContext context, GameLayoutManager gameLayoutManager) async {
    // Show intro animation first
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      useSafeArea: false, // This allows the dialog to extend into the safe area
      builder: (BuildContext context) {
        return Material(
          type: MaterialType.transparency,
          child: IntroAnimation(
            gameLayoutManager: gameLayoutManager,
            onComplete: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );

    // Add a small delay before showing the welcome dialog
    await Future.delayed(const Duration(milliseconds: 500));

    // Show welcome dialog with animation
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
            side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
          ),
          backgroundColor: AppStyles.dialogBackgroundColor,
          child: Container(
            width: gameLayoutManager.dialogMaxWidth,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 64, color: AppStyles.iconTrophyColor),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Re-Word Game!',
                  style: gameLayoutManager.dialogTitleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Get ready to challenge your vocabulary and have fun!',
                  style: gameLayoutManager.dialogContentStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: gameLayoutManager.buttonStyle(context),
                  child: const Text('Start Playing'),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Add a small delay to create a smooth transition
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
