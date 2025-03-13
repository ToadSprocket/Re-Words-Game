// lib/dialogs/password_recovery_dialog.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../styles/app_styles.dart';
import '../logic/api_service.dart';
import 'reset_password_dialog.dart';

class ForgotPasswordDialog {
  static Future<void> show(BuildContext context, ApiService api) async {
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
          ResetPasswordDialog.show(dialogContext, api, email);
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
                width: AppStyles.dialogWidth,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔹 Title & Close Button
                    Stack(
                      children: [
                        Center(child: Text('Password Recovery', style: AppStyles.dialogTitleStyle)),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const FaIcon(FontAwesomeIcons.circleXmark, size: 20.0, color: AppStyles.textColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // 🔹 Email Input Field
                    SizedBox(
                      width: AppStyles.dialogWidth * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enter your email address', style: AppStyles.InputTitleStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: emailController,
                            style: AppStyles.inputContentStyle,
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
                                      style: AppStyles.dialogErrorStyle,
                                      textAlign: TextAlign.center,
                                    )
                                    : successMessage != null
                                    ? Text(
                                      successMessage!,
                                      style: AppStyles.dialogSuccessStyle,
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
                          width: AppStyles.dialogWidth * 0.3,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: AppStyles.buttonStyle(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        SizedBox(
                          width: AppStyles.dialogWidth * 0.3,
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                errorMessage = null;
                                successMessage = null;
                              });
                              await attemptReset(dialogContext, setState); // ✅ Use the correct context
                              setState(() {});
                            },
                            style: AppStyles.buttonStyle(context),
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
