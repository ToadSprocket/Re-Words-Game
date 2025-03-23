// lib/dialogs/privacy_policy_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameLayoutManager.dart';

class PrivacyPolicyDialog {
  static void show(BuildContext context, GameLayoutManager gameLayoutManager) {
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
            width: gameLayoutManager.dialogMaxWidth * 0.8,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(children: [Center(child: Text('Privacy Policy', style: gameLayoutManager.dialogTitleStyle))]),
                const SizedBox(height: 16.0),
                Text(
                  'We value your privacy. Your email address will only be used for account recovery purposes and nothing else—no spam, no marketing, just a way to get you back into the game if needed. Your Display Name will appear on high score leaderboards to celebrate your achievements with other players. Rest assured, we\'ll never share your information with anyone, period. Your data stays safe with us so you can focus on enjoying the game.',
                  style: gameLayoutManager.dialogContentStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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
