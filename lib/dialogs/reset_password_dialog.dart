import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../styles/app_styles.dart';
import '../logic/api_service.dart';

class ResetPasswordDialog {
  static Future<void> show(BuildContext context, ApiService api, String email) async {
    final codeController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? errorMessage;
    String? successMessage;

    /// **Attempt password reset and return `true` if successful, otherwise `false`.**
    Future<bool> attemptPasswordReset(void Function(VoidCallback) setState) async {
      String code = codeController.text.trim();
      String newPassword = passwordController.text.trim();
      String confirmPassword = confirmPasswordController.text.trim();

      if (code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
        setState(() {
          errorMessage = "All fields are required.";
        });
        return false;
      }

      if (newPassword != confirmPassword) {
        setState(() {
          errorMessage = "Passwords do not match.";
        });
        return false;
      }

      bool success = await api.resetPassword(email, code, newPassword);

      setState(() {
        if (success) {
          successMessage = "✅ Password successfully reset!";
          errorMessage = null;
        } else {
          errorMessage = "🚨 Reset failed. Please check your code and try again.";
          successMessage = null;
        }
      });

      return success;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                        Center(child: Text('Reset Password', style: AppStyles.dialogTitleStyle)),
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

                    // 🔹 Input Fields
                    SizedBox(
                      width: AppStyles.dialogWidth * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enter Reset Code', style: AppStyles.InputTitleStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: codeController,
                            style: AppStyles.inputContentStyle,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                            ),
                          ),
                          const SizedBox(height: 12.0),

                          Text('New Password', style: AppStyles.InputTitleStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            style: AppStyles.inputContentStyle,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                            ),
                          ),
                          const SizedBox(height: 12.0),

                          Text('Confirm Password', style: AppStyles.InputTitleStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: true,
                            style: AppStyles.inputContentStyle,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                            ),
                          ),

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

                              bool success = await attemptPasswordReset(setState);

                              if (success && context.mounted) {
                                await Future.delayed(const Duration(milliseconds: 500)); // Short delay
                                Navigator.pop(context); // ✅ Close only if reset succeeds
                              }
                            },
                            style: AppStyles.buttonStyle(context),
                            child: const Text('Reset'),
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
