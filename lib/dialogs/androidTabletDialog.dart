// lib/dialogs/welcome_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameLayoutManager.dart';
import '../components/intro_animation.dart';

class AndroidTabletDialog {
  static Future<void> show(BuildContext context, GameLayoutManager gameLayoutManager) async {
    // Show tablet settings dialog
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
                const Icon(Icons.tablet_android, size: 64, color: AppStyles.iconTabletColor),
                const SizedBox(height: 24),
                Text('Android Tablet Users', style: gameLayoutManager.dialogTitleStyle, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(
                  'For the best experience, set Full Screen aspect ratio:\n'
                  'Settings > Apps > Reword Game > Aspect Ratio > Full Screen',
                  style: gameLayoutManager.dialogContentStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: gameLayoutManager.buttonStyle(context),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
