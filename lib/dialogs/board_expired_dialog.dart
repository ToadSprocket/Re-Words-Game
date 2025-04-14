// lib/dialogs/board_expired_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameLayoutManager.dart';

class BoardExpiredDialog {
  static Future<bool?> show(BuildContext context, GameLayoutManager gameLayoutManager) {
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
            width: gameLayoutManager.dialogMaxWidth, // ✅ Fixed width
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ Dynamic height
                children: [
                  Stack(
                    children: [
                      Center(
                        child: Text(
                          'New Board Available',
                          style: gameLayoutManager.dialogTitleStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Your current board has expired.\n'
                    'Would you like to load a new board?\n',
                    style: gameLayoutManager.dialogContentStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0), // ✅ More space before buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            result = false; // Keep Playing
                            Navigator.of(context).pop(false);
                          }, // Keep Playing
                          style: gameLayoutManager.buttonStyle(context),
                          child: const Text('No'),
                        ),
                      ),
                      const SizedBox(width: 12.0), // ✅ Spacing between buttons
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            result = true; // Load New Board
                            Navigator.of(context).pop(true);
                          },
                          style: gameLayoutManager.buttonStyle(context),
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
