// lib/dialogs/board_expired_dialog.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BoardExpiredDialog {
  static Future<bool?> show(BuildContext context, {required VoidCallback onNewBoard}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
            side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
          ),
          backgroundColor: AppStyles.dialogBackgroundColor,
          child: Container(
            width: AppStyles.dialogWidth, // Smaller: 80% of 500 ≈ 400
            height: AppStyles.dialogHeight * 0.4, // Smaller: 50% of 400 ≈ 200
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        onTap: () => Navigator.of(context).pop(false),
                        child: const FaIcon(FontAwesomeIcons.circleXmark, size: 20.0, color: AppStyles.textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Your current board has expired.\n You can keep playing until you have finished this one,\n or load a new board.',
                  style: AppStyles.dialogContentStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false), // Keep Playing
                      style: AppStyles.buttonStyle(context),
                      child: const Text('Keep Playing'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onNewBoard();
                        Navigator.of(context).pop(true); // Load New Board
                      },
                      style: AppStyles.buttonStyle(context),
                      child: const Text('Load New Board'),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.dialogButtonPadding),
              ],
            ),
          ),
        );
      },
    );
  }
}
