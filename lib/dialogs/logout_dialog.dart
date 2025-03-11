// lib/dialogs/logout_dialog.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../logic/api_service.dart';

class LogoutDialog {
  static Future<void> show(BuildContext context, ApiService api) {
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
            width: AppStyles.dialogWidth, // ✅ Match width with other dialogs
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
                          style: AppStyles.dialogTitleStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const FaIcon(FontAwesomeIcons.circleXmark, size: 20.0, color: AppStyles.textColor),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0), // ✅ Adjusted spacing
                  // 🔹 Logout Message
                  Text(
                    'Are you sure you want to log out?',
                    style: AppStyles.dialogContentStyle,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24.0), // ✅ Reduce space
                  // 🔹 Buttons (Centered)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔹 Cancel Button
                      SizedBox(
                        width: AppStyles.dialogWidth * 0.35, // ✅ Matching width
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(), // Close dialog
                          style: AppStyles.buttonStyle(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12.0), // ✅ Adjusted spacing
                      // 🔹 Logout Button
                      SizedBox(
                        width: AppStyles.dialogWidth * 0.35, // ✅ Matching width
                        child: ElevatedButton(
                          onPressed: () {
                            api.loggedIn = false; // ✅ Log the user out
                            Navigator.of(context).pop(); // Close dialog
                          },
                          style: AppStyles.buttonStyle(context),
                          child: const Text('Logout'),
                        ),
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
