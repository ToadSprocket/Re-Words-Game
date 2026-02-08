// File: /lib/dialogs/welcome_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../components/intro_animation.dart';
import '../managers/gameManager.dart';

class WelcomeDialog {
  static Future<void> show(BuildContext context, GameManager gm) async {
    final layout = gm.layoutManager!;

    // Show intro animation first
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (BuildContext context) {
        return Material(
          type: MaterialType.transparency,
          child: IntroAnimation(
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
            width: layout.dialogMaxWidth,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 64, color: AppStyles.iconTrophyColor),
                const SizedBox(height: 24),
                Text('Welcome to Re-Word Game!', style: layout.dialogTitleStyle, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(
                  'Get ready to challenge your vocabulary and have fun!',
                  style: layout.dialogContentStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: layout.buttonStyle(context),
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
