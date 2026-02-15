// File: /lib/dialogs/new_board_loaded_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameManager.dart';

/// Simple informational dialog shown when a new board is automatically loaded
/// (e.g., when the expired grace period has passed). Has a single OK button.
class NewBoardLoadedDialog {
  static Future<void> show(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap OK
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
            side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
          ),
          backgroundColor: AppStyles.dialogBackgroundColor,
          child: SizedBox(
            width: layout.dialogMaxWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Center(child: Text('New Board Loaded', style: layout.dialogTitleStyle, textAlign: TextAlign.center)),
                  const SizedBox(height: 16.0),
                  // Message
                  Text('Good Luck!', style: layout.dialogContentStyle, textAlign: TextAlign.center),
                  const SizedBox(height: 24.0),
                  // Single OK button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: layout.buttonStyle(context),
                    child: const Text('OK'),
                  ),
                  const SizedBox(height: AppStyles.dialogButtonPadding),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
