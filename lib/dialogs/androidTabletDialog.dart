// File: /lib/dialogs/androidTabletDialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameManager.dart';

class AndroidTabletDialog {
  static Future<void> show(BuildContext context) async {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;

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
            width: layout.dialogMaxWidth,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tablet_android, size: 64, color: AppStyles.iconTabletColor),
                const SizedBox(height: 24),
                Text('Android Tablet Users', style: layout.dialogTitleStyle, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(
                  'For the best experience, set Full Screen aspect ratio:\n'
                  'Settings > Apps > Reword Game > Aspect Ratio > Full Screen',
                  style: layout.dialogContentStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: layout.buttonStyle(context),
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
