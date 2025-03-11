import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:email_validator/email_validator.dart';
import '../styles/app_styles.dart';
import '../logic/api_service.dart';

class RegisterDialog {
  static Future<void> show(BuildContext context, ApiService api) async {
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
                width: AppStyles.dialogWidth,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔹 Title & Close Button
                    Stack(
                      children: [
                        Center(child: Text('Create Account', style: AppStyles.dialogTitleStyle)),
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

                    // 🔹 Input Fields (Centered)
                    SizedBox(
                      width: AppStyles.dialogWidth * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(userNameController, 'Username', false),
                          _buildInputField(displayNameController, 'Display Name', false),
                          _buildInputField(emailController, 'Email Address', false),
                          _buildInputField(confirmEmailController, 'Confirm Email Address', false),
                          _buildInputField(passwordController, 'Password', true),

                          // 🔹 Error Message Display (Fixed Size)
                          Container(
                            height: 84.0,
                            alignment: Alignment.center,
                            child:
                                errorMessage != null
                                    ? Text(
                                      errorMessage!,
                                      style: AppStyles.dialogErrorStyle,
                                      textAlign: TextAlign.center,
                                    )
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // 🔹 Register & Cancel Buttons
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
                            style: AppStyles.buttonStyle(context),
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
  static Widget _buildInputField(TextEditingController controller, String label, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.InputTitleStyle),
        const SizedBox(height: 4.0),
        TextFormField(
          controller: controller,
          style: AppStyles.inputContentStyle,
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
