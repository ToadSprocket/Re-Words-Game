// lib/dialogs/board_expired_dialog.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BoardExpiredDialog {
  static Future<bool?> show(BuildContext context) {
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
            width: AppStyles.dialogWidth, // ✅ Fixed width
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
                          style: AppStyles.dialogTitleStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            result = false; // Close means "Keep Playing"
                            Navigator.of(context).pop();
                          },
                          child: const FaIcon(FontAwesomeIcons.circleXmark, size: 20.0, color: AppStyles.textColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Your current board has expired.\n'
                    'You can keep playing until you have finished this one,\n'
                    'or load a new board.',
                    style: AppStyles.dialogContentStyle,
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
                          style: AppStyles.buttonStyle(context),
                          child: const Text('Keep Playing'),
                        ),
                      ),
                      const SizedBox(width: 12.0), // ✅ Spacing between buttons
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            result = true; // Load New Board
                            Navigator.of(context).pop(true);
                          },
                          style: AppStyles.buttonStyle(context),
                          child: const Text('Load New Board'),
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
