// layouts/legal_dialog.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class LegalDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
            side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
          ),
          backgroundColor: AppStyles.dialogBackgroundColor,
          child: Container(
            width: AppStyles.dialogWidth,
            height: AppStyles.dialogHeight,
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0), // Adjusted bottom padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Center(child: Text('Legal', style: AppStyles.dialogTitleStyle)),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text('[x]', style: TextStyle(fontSize: 16.0, color: AppStyles.textColor)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  // Pushes content up, button down
                  child: const Text(
                    'Re-Word Game © 2025 [Your Name]. All rights reserved. For entertainment purposes only.',
                    style: AppStyles.dialogContentStyle,
                  ),
                ),
                const SizedBox(height: AppStyles.dialogButtonPadding), // Padding above button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: AppStyles.buttonStyle(context),
                  child: const Text('Close'),
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
