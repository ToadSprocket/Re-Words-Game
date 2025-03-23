import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../styles/app_styles.dart';
import '../logic/api_service.dart';
import '../managers/gameLayoutManager.dart';
import 'privacy_policy_dialog.dart';

class RegisterDialog {
  static Future<void> show(BuildContext context, ApiService api, GameLayoutManager gameLayoutManager) async {
    final userNameController = TextEditingController();
    final displayNameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final confirmEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? errorMessage; // 🔹 Holds validation errors

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
                    Stack(children: [Center(child: Text('Create Account', style: gameLayoutManager.dialogTitleStyle))]),
                    const SizedBox(height: 16.0),

                    // 🔹 Input Fields (Centered)
                    SizedBox(
                      width: gameLayoutManager.dialogMaxWidth * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(userNameController, 'Username', false, gameLayoutManager),
                          _buildInputField(displayNameController, 'Display Name', false, gameLayoutManager),
                          _buildInputField(emailController, 'Email Address', false, gameLayoutManager),

                          const SizedBox(height: 8.0),
                          _buildInputField(confirmEmailController, 'Confirm Email Address', false, gameLayoutManager),
                          _buildInputField(passwordController, 'Password', true, gameLayoutManager),
                          Center(
                            child: TextButton(
                              onPressed: () => PrivacyPolicyDialog.show(context, gameLayoutManager),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: Text(
                                'By signing up, you agree to our Privacy Policy',
                                style: gameLayoutManager.dialogLinkStyle.copyWith(
                                  fontSize: gameLayoutManager.dialogBodyFontSize * 0.9,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0),

                          // 🔹 Error Message Display (Fixed Size)
                          Container(
                            height: 40.0,
                            alignment: Alignment.center,
                            child:
                                errorMessage != null
                                    ? Text(
                                      errorMessage!,
                                      style: gameLayoutManager.dialogErrorStyle,
                                      textAlign: TextAlign.center,
                                    )
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 3.0),

                    // 🔹 Register & Cancel Buttons
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
                              setState(() => errorMessage = null); // Clear old errors

                              // 🔹 Input Validation Before API Call
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

                              // 🔹 Call API for Registration
                              final response = await api.updateProfile(
                                userName: username,
                                displayName: displayName,
                                password: password,
                                email: email,
                              );

                              if (response.message != null) {
                                print('✅ Registration Successful!');
                                Navigator.pop(context); // ✅ Close dialog on success
                              } else {
                                setState(() => errorMessage = "Registration failed. Please try again.");
                              }
                            },
                            style: gameLayoutManager.buttonStyle(context),
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

  // 🔹 Helper Function to Build Input Fields
  static Widget _buildInputField(
    TextEditingController controller,
    String label,
    bool isPassword,
    GameLayoutManager gameLayoutManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: gameLayoutManager.dialogInputTitleStyle),
        const SizedBox(height: 4.0),
        TextFormField(
          controller: controller,
          style: gameLayoutManager.dialogInputContentStyle,
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
