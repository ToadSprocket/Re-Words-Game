// lib/dialogs/delete_account_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../services/api_service.dart';
import '../managers/gameLayoutManager.dart';
import '../logic/logging_handler.dart';

class DeleteAccountDialog {
  static Future<void> show(BuildContext context, ApiService api, GameLayoutManager gameLayoutManager) async {
    bool isConfirmationStep = true;
    final userNameController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage;
    bool isLoading = false;

    void attemptDeleteAccount(StateSetter setState) async {
      if (isLoading) return;

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

        final success = await api.deleteAccount(username, password);
        if (success) {
          // Account deleted successfully
          Navigator.pop(context);

          // Show confirmation snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been deleted successfully.'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          setState(() {
            errorMessage = "Failed to delete account. Please check your credentials and try again.";
            isLoading = false;
          });
        }
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
                    Stack(
                      children: [
                        Center(
                          child: Text(
                            isConfirmationStep ? 'Delete Account' : 'Confirm Deletion',
                            style: gameLayoutManager.dialogTitleStyle,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    if (isConfirmationStep) ...[
                      // Warning message
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
                            const SizedBox(height: 8.0),
                            Text(
                              'Warning: Account Deletion',
                              style: gameLayoutManager.dialogContentStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'This will permanently delete your account and all associated data from our servers. This action cannot be undone.',
                              style: gameLayoutManager.dialogContentStyle,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: gameLayoutManager.dialogMaxWidth * 0.35,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: gameLayoutManager.buttonStyle(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          SizedBox(
                            width: gameLayoutManager.dialogMaxWidth * 0.35,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isConfirmationStep = false;
                                });
                              },
                              style: gameLayoutManager.deleteButtonStyle(context),
                              child: const Text('Continue'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
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
                              onFieldSubmitted: (_) => !isLoading ? attemptDeleteAccount(setState) : null,
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

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: gameLayoutManager.dialogMaxWidth * 0.35,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () {
                                        setState(() {
                                          isConfirmationStep = true;
                                        });
                                      },
                              style: gameLayoutManager.buttonStyle(context),
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          SizedBox(
                            width: gameLayoutManager.dialogMaxWidth * 0.35,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () => attemptDeleteAccount(setState),
                              style: gameLayoutManager.deleteButtonStyle(context),
                              child: const Text('Delete Account'),
                            ),
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
  }
}
