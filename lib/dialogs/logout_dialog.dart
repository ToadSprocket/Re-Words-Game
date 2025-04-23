// lib/dialogs/logout_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../services/api_service.dart';
import '../managers/gameLayoutManager.dart';

class LogoutDialog {
  static Future<void> show(BuildContext context, ApiService api, GameLayoutManager gameLayoutManager) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allow dismiss by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
            side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
          ),
          backgroundColor: AppStyles.dialogBackgroundColor,
          child: SizedBox(
            width: gameLayoutManager.dialogMaxWidth, // ✅ Match width with other dialogs
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // ✅ Tighter padding
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ Prevent excessive height
                children: [
                  // 🔹 Title & Close Button
                  Stack(
                    children: [
                      Center(
                        child: Text(
                          'Logout Confirmation',
                          style: gameLayoutManager.dialogTitleStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0), // ✅ Adjusted spacing
                  // 🔹 Logout Message
                  Text(
                    'Are you sure you want to log out?',
                    style: gameLayoutManager.dialogContentStyle,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24.0), // ✅ Reduce space
                  // 🔹 Buttons (Centered)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔹 Cancel Button
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(), // Close dialog
                        style: gameLayoutManager.buttonStyle(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12.0), // ✅ Adjusted spacing
                      // 🔹 Logout Button
                      ElevatedButton(
                        onPressed: () {
                          api.loggedIn = false; // ✅ Log the user out
                          Navigator.of(context).pop(); // Close dialog
                        },
                        style: gameLayoutManager.buttonStyle(context),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0), // ✅ Ensure minimal space at bottom
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
