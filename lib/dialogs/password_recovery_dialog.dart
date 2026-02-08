// File: /lib/dialogs/password_recovery_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'reset_password_dialog.dart';
import '../managers/gameManager.dart';

class ForgotPasswordDialog {
  static Future<void> show(BuildContext context, GameManager gm) async {
    final layout = gm.layoutManager!;
    final emailController = TextEditingController();
    String? errorMessage;
    String? successMessage;

    Future<void> attemptReset(BuildContext dialogContext, void Function(VoidCallback) setState) async {
      String email = emailController.text.trim();
      if (email.isEmpty) {
        setState(() => errorMessage = "Please enter your email address.");
      } else {
        bool success = await gm.apiService.requestPasswordReset(email);
        if (success) {
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.pop(dialogContext);
          }
          ResetPasswordDialog.show(dialogContext, gm, email);
        } else {
          setState(() {
            errorMessage = "🚨 Failed to send reset email. Please try again.";
            successMessage = null;
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
                side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
              ),
              backgroundColor: AppStyles.dialogBackgroundColor,
              child: Container(
                width: layout.dialogMaxWidth,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(children: [Center(child: Text('Password Recovery', style: layout.dialogTitleStyle))]),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: layout.dialogMaxWidth * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enter your email address', style: layout.dialogInputTitleStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: emailController,
                            style: layout.dialogInputContentStyle,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          Container(
                            height: 34.0,
                            alignment: Alignment.center,
                            child:
                                errorMessage != null
                                    ? Text(errorMessage!, style: layout.dialogErrorStyle, textAlign: TextAlign.center)
                                    : successMessage != null
                                    ? Text(
                                      successMessage!,
                                      style: layout.dialogSuccessStyle,
                                      textAlign: TextAlign.center,
                                    )
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: layout.dialogMaxWidth * 0.3,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: layout.buttonStyle(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        SizedBox(
                          width: layout.dialogMaxWidth * 0.3,
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                errorMessage = null;
                                successMessage = null;
                              });
                              await attemptReset(dialogContext, setState);
                              setState(() {});
                            },
                            style: layout.buttonStyle(context),
                            child: const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
