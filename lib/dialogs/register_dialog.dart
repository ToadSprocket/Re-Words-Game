// File: /lib/dialogs/register_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../styles/app_styles.dart';
import '../managers/gameManager.dart';
import 'privacy_policy_dialog.dart';

class RegisterDialog {
  static String? _validatePasswordStrength(String password) {
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Password must contain at least one special character (e.g., !@#\$%^&*)';
    }
    return null;
  }

  static Future<void> show(BuildContext context, GameManager gm) async {
    final layout = gm.layoutManager!;
    final userNameController = TextEditingController();
    final displayNameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final confirmEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? errorMessage;

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
                    Stack(children: [Center(child: Text('Create Account', style: layout.dialogTitleStyle))]),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: layout.dialogMaxWidth * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(userNameController, 'Username', false, layout),
                          _buildInputField(displayNameController, 'Display Name', false, layout),
                          _buildInputField(emailController, 'Email Address', false, layout),
                          const SizedBox(height: 8.0),
                          _buildInputField(confirmEmailController, 'Confirm Email Address', false, layout),
                          _buildInputField(passwordController, 'Password', true, layout),
                          Center(
                            child: TextButton(
                              onPressed: () => PrivacyPolicyDialog.show(context),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: Text(
                                'By signing up, you agree to our Privacy Policy',
                                style: layout.dialogLinkStyle.copyWith(fontSize: layout.dialogBodyFontSize * 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Container(
                            height: 40.0,
                            alignment: Alignment.center,
                            child:
                                errorMessage != null
                                    ? Text(errorMessage!, style: layout.dialogErrorStyle, textAlign: TextAlign.center)
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3.0),
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
                              setState(() => errorMessage = null);

                              String username = userNameController.text.trim();
                              String displayName = displayNameController.text.trim();
                              String email = emailController.text.trim();
                              String confirmEmail = confirmEmailController.text.trim();
                              String password = passwordController.text.trim();

                              if (username.isEmpty ||
                                  displayName.isEmpty ||
                                  email.isEmpty ||
                                  confirmEmail.isEmpty ||
                                  password.isEmpty) {
                                setState(() => errorMessage = "All fields are required.");
                                return;
                              }
                              if (username.length > 24 || displayName.length > 24) {
                                setState(
                                  () => errorMessage = "Username and Display Name must be 24 characters or less.",
                                );
                                return;
                              }
                              if (!EmailValidator.validate(email)) {
                                setState(() => errorMessage = "Invalid email format.");
                                return;
                              }
                              if (email != confirmEmail) {
                                setState(() => errorMessage = "Emails do not match.");
                                return;
                              }

                              String? passwordError = _validatePasswordStrength(password);
                              if (passwordError != null) {
                                setState(() => errorMessage = passwordError);
                                return;
                              }

                              final response = await gm.apiService.updateProfile(
                                userName: username,
                                displayName: displayName,
                                password: password,
                                email: email,
                              );

                              if (response.message != null) {
                                Navigator.pop(context);
                              } else {
                                setState(() => errorMessage = "Registration failed. Please try again.");
                              }
                            },
                            style: layout.buttonStyle(context),
                            child: const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper Function to Build Input Fields
  static Widget _buildInputField(TextEditingController controller, String label, bool isPassword, dynamic layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: layout.dialogInputTitleStyle),
        const SizedBox(height: 4.0),
        TextFormField(
          controller: controller,
          style: layout.dialogInputContentStyle,
          obscureText: isPassword,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
          ),
        ),
        const SizedBox(height: 12.0),
      ],
    );
  }
}
