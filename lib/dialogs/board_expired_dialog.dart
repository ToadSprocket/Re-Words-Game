// lib/dialogs/board_expired_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameManager.dart';

class BoardExpiredDialog {
  static Future<bool?> show(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;
    bool? result;
    return showDialog<bool>(
      context: context,
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
                  Stack(
                    children: [
                      Center(
                        child: Text('New Board Available', style: layout.dialogTitleStyle, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Your current board has expired.\n'
                    'Would you like to load a new board?\n',
                    style: layout.dialogContentStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            result = false;
                            Navigator.of(context).pop(false);
                          },
                          style: layout.buttonStyle(context),
                          child: const Text('No'),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            result = true;
                            Navigator.of(context).pop(true);
                          },
                          style: layout.buttonStyle(context),
                          child: const Text('Yes'),
                        ),
                      ),
                    ],
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
