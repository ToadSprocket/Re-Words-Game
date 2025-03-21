// lib/dialogs/password_recovery_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/api_service.dart';
import 'reset_password_dialog.dart';
import '../managers/gameLayoutManager.dart';

class ForgotPasswordDialog {
  static Future<void> show(BuildContext context, ApiService api, GameLayoutManager gameLayoutManager) async {
    final emailController = TextEditingController();
    String? errorMessage;
    String? successMessage;

    Future<void> attemptReset(BuildContext dialogContext, void Function(VoidCallback) setState) async {
      String email = emailController.text.trim();
      if (email.isEmpty) {
        setState(() => errorMessage = "Please enter your email address.");
      } else {
        bool success = await api.requestPasswordReset(email);
        if (success) {
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.pop(dialogContext); // ✅ Ensure dialog is still in the tree
          }
          ResetPasswordDialog.show(dialogContext, api, email, gameLayoutManager);
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
                width: gameLayoutManager.dialogMaxWidth,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔹 Title & Close Button
                    Stack(
                      children: [Center(child: Text('Password Recovery', style: gameLayoutManager.dialogTitleStyle))],
                    ),
                    const SizedBox(height: 16.0),

                    // 🔹 Email Input Field
                    SizedBox(
                      width: gameLayoutManager.dialogMaxWidth * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enter your email address', style: gameLayoutManager.dialogInputTitleStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: emailController,
                            style: gameLayoutManager.dialogInputContentStyle,
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
                                    ? Text(
                                      errorMessage!,
                                      style: gameLayoutManager.dialogErrorStyle,
                                      textAlign: TextAlign.center,
                                    )
                                    : successMessage != null
                                    ? Text(
                                      successMessage!,
                                      style: gameLayoutManager.dialogSuccessStyle,
                                      textAlign: TextAlign.center,
                                    )
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // 🔹 Submit & Cancel Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: gameLayoutManager.dialogMaxWidth * 0.3,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: gameLayoutManager.buttonStyle(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        SizedBox(
                          width: gameLayoutManager.dialogMaxWidth * 0.3,
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                errorMessage = null;
                                successMessage = null;
                              });
                              await attemptReset(dialogContext, setState); // ✅ Use the correct context
                              setState(() {});
                            },
                            style: gameLayoutManager.buttonStyle(context),
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
