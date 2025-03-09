// lib/dialogs/failure_dialog.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemNavigator.pop
import '../styles/app_styles.dart';
import 'package:window_manager/window_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io'; // For Platform class

class FailureDialog {
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismiss without button
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
            side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
          ),
          backgroundColor: AppStyles.dialogBackgroundColor,
          child: Container(
            width: AppStyles.dialogWidth * 0.8, // ~400px
            height: AppStyles.dialogHeight * 0.5, // ~200px
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: Text('Server Error', style: AppStyles.dialogTitleStyle, textAlign: TextAlign.center),
                        ),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () => SystemNavigator.pop(), // Exit via X
                            child: const FaIcon(FontAwesomeIcons.circleXmark, size: 20.0, color: AppStyles.textColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36.0),
                    const Text(
                      'Failure contacting game server.\nPlease Try Again Later',
                      style: AppStyles.dialogContentStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
                      await windowManager.destroy(); // Force close on desktop
                    } else {
                      SystemNavigator.pop(); // Mobile fallback
                    }
                  },
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
