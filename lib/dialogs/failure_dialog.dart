// lib/dialogs/failure_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemNavigator.pop
import '../styles/app_styles.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import '../managers/gameLayoutManager.dart';

class FailureDialog {
  static Future<void> show(BuildContext context, GameLayoutManager gameLayoutManager) {
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
            width: gameLayoutManager.dialogMaxWidth * 0.8, // ~400px
            height: gameLayoutManager.dialogMaxHeight * 0.5, // ~200px
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
                          child: Text(
                            'Server Error',
                            style: gameLayoutManager.dialogTitleStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36.0),
                    Text(
                      'Failure contacting game server.\nPlease Try Again Later',
                      style: gameLayoutManager.dialogContentStyle,
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
                  style: gameLayoutManager.buttonStyle(context),
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
