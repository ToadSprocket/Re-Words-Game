import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../styles/app_styles.dart';
import '../logic/api_service.dart';
import 'register_dialog.dart';

class LoginDialog {
  static Future<void> show(BuildContext context, ApiService api) async {
    final userNameController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage;

    void attemptLogin() async {
      String username = userNameController.text.trim();
      String password = passwordController.text.trim();

      if (username.isEmpty || password.isEmpty) {
        errorMessage = "Please enter both username and password.";
      } else {
        final response = await api.login(username, password);
        if (response == null) {
          errorMessage = "Invalid username or password. Please try again.";
        } else {
          Navigator.pop(context); // ✅ Close dialog on successful login
          return;
        }
      }
      // 🔥 Force UI to update with error message
      (context as Element).markNeedsBuild();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? errorMessage; // 🚨 Error message state

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
                        Center(child: Text('Reword Login', style: AppStyles.dialogTitleStyle)),
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
                          Text('Username or Email Address', style: AppStyles.InputTitleStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: userNameController,
                            style: AppStyles.inputContentStyle,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                            ),
                          ),
                          const SizedBox(height: 12.0),

                          Text('Password', style: AppStyles.InputTitleStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: passwordController,
                            style: AppStyles.inputContentStyle,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                            ),
                            textInputAction: TextInputAction.done, // ✅ Pressing "Enter" submits
                            onFieldSubmitted: (_) => attemptLogin(), // ✅ Handle Enter key
                          ),

                          // 🔹 Forgot Password Link
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Implement Forgot Password
                              },
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                              child: Text('Forgot Password?', style: AppStyles.dialogLinkStyle),
                            ),
                          ),
                          Container(
                            height: 34.0, // 🔥 Locks the height to prevent jumping
                            alignment: Alignment.center, // 🔥 Keeps text centered vertically
                            child:
                                errorMessage != null && errorMessage!.isNotEmpty
                                    ? Text(
                                      errorMessage!,
                                      style: AppStyles.dialogErrorStyle,
                                      textAlign: TextAlign.center,
                                    )
                                    : const SizedBox.shrink(), // 🔥 Doesn't take up space when empty
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // 🔹 Login & Cancel Buttons
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

                              String username = userNameController.text.trim();
                              String password = passwordController.text.trim();

                              if (username.isEmpty || password.isEmpty) {
                                setState(() => errorMessage = "Please enter both username and password.");
                                return;
                              }

                              final response = await api.login(username, password);

                              if (response == null) {
                                setState(() => errorMessage = "Invalid username or password. Please try again.");
                                return;
                              }

                              Navigator.pop(context); // ✅ Close dialog on success
                            },
                            style: AppStyles.buttonStyle(context),
                            child: const Text('Login'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16.0),

                    // 🔹 "Don't have an account?" Text & Sign Up Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have a login yet?", style: AppStyles.dialogContentStyle),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            RegisterDialog.show(context, api);
                          },
                          child: Text('Sign Up', style: AppStyles.dialogLinkStyle),
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
}
