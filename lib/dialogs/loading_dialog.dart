// File: /lib/dialogs/loading_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameManager.dart';

class LoadingDialog {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> show(BuildContext context, {String message = "Loading..."}) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
              side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
            ),
            backgroundColor: AppStyles.dialogBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppStyles.dialogBorderColor)),
                  const SizedBox(height: 16),
                  Text(message, style: layout.dialogTitleStyle, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void dismiss(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
