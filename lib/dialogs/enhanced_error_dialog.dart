// File: /lib/dialogs/enhanced_error_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameLayoutManager.dart';

/// An enhanced error dialog that provides more context and options than the basic FailureDialog.
///
/// Features:
/// - Customizable title and message
/// - Optional retry functionality
/// - Visual feedback based on error type
class EnhancedErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final String? actionButtonText;

  const EnhancedErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onClose,
    this.actionButtonText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameLayoutManager = GameLayoutManager();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
        side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
      ),
      backgroundColor: AppStyles.dialogBackgroundColor,
      child: Container(
        width: gameLayoutManager.dialogMaxWidth * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),

            // Title
            Text(title, style: gameLayoutManager.dialogTitleStyle, textAlign: TextAlign.center),
            const SizedBox(height: 16),

            // Message
            Text(message, style: gameLayoutManager.dialogContentStyle, textAlign: TextAlign.center),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry!();
                    },
                    style: gameLayoutManager.buttonStyle(context),
                    child: Text(actionButtonText ?? 'Retry'),
                  ),
                  const SizedBox(width: 16),
                ],

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onClose != null) onClose!();
                  },
                  style: gameLayoutManager.buttonStyle(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
