import 'package:flutter/material.dart';
import 'package:reword_game/logic/logging_handler.dart';
import '../styles/app_styles.dart';
import '../services/api_service.dart';
import '../logic/security.dart';
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
    bool isLoading = false;
    final loginSecurity = LoginSecurity();

    void attemptLogin(StateSetter setState) async {
      if (isLoading) return;

      // First check if login is locked out
      final lockoutStatus = await loginSecurity.checkLockoutStatus();
      if (lockoutStatus['isLocked']) {
        setState(() {
          final remainingTime = LoginSecurity.formatLockoutTime(lockoutStatus['remainingSeconds']);
          errorMessage = "Too many failed attempts. Please try again in $remainingTime.";
          isLoading = false;
        });
        return;
      }

      String username = userNameController.text.trim();
      String password = passwordController.text.trim();

      try {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });

        if (username.isEmpty || password.isEmpty) {
          setState(() {
            errorMessage = "Please enter both username and password.";
            isLoading = false;
          });
          return;
        }

        final response = await api.login(username, password);
        if (response == null) {
          // Record failed login attempt
          final failureResult = await loginSecurity.recordFailedAttempt();

          if (failureResult['isLocked']) {
            // Account is now locked
            final remainingTime = LoginSecurity.formatLockoutTime(failureResult['remainingSeconds']);
            setState(() {
              errorMessage = "Too many failed attempts. Please try again in $remainingTime.";
              isLoading = false;
            });
          } else {
            // Show attempts remaining
            final attemptsRemaining = failureResult['attemptsRemaining'];
            setState(() {
              errorMessage =
                  "Invalid username or password. $attemptsRemaining ${attemptsRemaining == 1 ? 'attempt' : 'attempts'} remaining.";
              isLoading = false;
            });
          }
          return;
        }

        // Login successful - reset attempt counter
        await loginSecurity.resetAttempts();
        loginSuccess = true;
        Navigator.pop(context);
      } catch (e) {
        LogService.logError("Fatal Error Encountered: $e");
        setState(() {
          errorMessage = "An error occurred. Please try again later.";
          isLoading = false;
        });
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
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
                            enabled: !isLoading,
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
                            enabled: !isLoading,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => !isLoading ? attemptLogin(setState) : null,
                          ),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () {
                                        Navigator.pop(context);
                                        ForgotPasswordDialog.show(context, api, gameLayoutManager);
                                      },
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                              child: Text('Forgot Password?', style: gameLayoutManager.dialogLinkStyle),
                            ),
                          ),
                          Container(
                            height: 34.0,
                            alignment: Alignment.center,
                            child:
                                isLoading
                                    ? const CircularProgressIndicator()
                                    : errorMessage != null && errorMessage!.isNotEmpty
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
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
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
                            onPressed: isLoading ? null : () => attemptLogin(setState),
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
                          Text("Don't have an account? ", style: gameLayoutManager.dialogContentStyle),
                          TextButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                      Navigator.pop(context);
                                      RegisterDialog.show(context, api, gameLayoutManager);
                                    },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
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
