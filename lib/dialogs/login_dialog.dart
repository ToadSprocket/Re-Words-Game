import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/api_service.dart';
import 'register_dialog.dart';
import 'password_recovery_dialog.dart';
import '../managers/gameLayoutManager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginDialog {
  static Future<bool> show(BuildContext context, ApiService api, GameLayoutManager gameLayoutManager) async {
    final userNameController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage;
    bool loginSuccess = false;

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
          loginSuccess = true;
          Navigator.pop(context); // Close dialog on successful login
          return;
        }
      }
      // Force UI to update with error message
      (context as Element).markNeedsBuild();
    }

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        String? errorMessage; // Error message state

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
                    // Title & Close Button
                    Stack(children: [Center(child: Text('Reword Login', style: gameLayoutManager.dialogTitleStyle))]),
                    const SizedBox(height: 16.0),

                    // Input Fields (Centered)
                    SizedBox(
                      width: gameLayoutManager.dialogMaxWidth * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username or Email Address', style: gameLayoutManager.dialogInputContentStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: userNameController,
                            style: gameLayoutManager.dialogInputContentStyle,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                            ),
                          ),
                          const SizedBox(height: 12.0),

                          Text('Password', style: gameLayoutManager.dialogInputTitleStyle),
                          const SizedBox(height: 4.0),
                          TextFormField(
                            controller: passwordController,
                            style: gameLayoutManager.dialogInputContentStyle,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => attemptLogin(),
                          ),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close login dialog first
                                ForgotPasswordDialog.show(
                                  context,
                                  api,
                                  gameLayoutManager,
                                ); // Open forgot password dialog
                              },
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                              child: Text('Forgot Password?', style: gameLayoutManager.dialogLinkStyle),
                            ),
                          ),
                          Container(
                            height: 34.0,
                            alignment: Alignment.center,
                            child:
                                errorMessage != null && errorMessage!.isNotEmpty
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

                    const SizedBox(height: 16.0),

                    // Login & Cancel Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: gameLayoutManager.dialogMaxWidth * 0.3,
                          child: ElevatedButton(
                            onPressed: () {
                              loginSuccess = false;
                              Navigator.pop(context);
                            },
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

                              loginSuccess = true;
                              Navigator.pop(context); // Close dialog on success
                            },
                            style: gameLayoutManager.buttonStyle(context),
                            child: const Text('Login'),
                          ),
                        ),
                      ],
                    ),

                    // Only show signup option for non-web users
                    if (!kIsWeb) ...[
                      const SizedBox(height: 16.0),
                      // "Don't have an account?" Text & Sign Up Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have a login yet?", style: gameLayoutManager.dialogContentStyle),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              RegisterDialog.show(context, api, gameLayoutManager);
                            },
                            child: Text('Sign Up', style: gameLayoutManager.dialogLinkStyle),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return loginSuccess;
  }
}
