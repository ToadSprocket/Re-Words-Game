// File: /lib/dialogs/login_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../managers/gameManager.dart';

class LoginDialog {
  /// Temporary auth stub while account flows are moved to platform-linked IDs.
  ///
  /// Returns `false` so existing call sites that expect a login outcome keep
  /// their current control flow without unintended follow-up navigation.
  static Future<bool> show(BuildContext context, GameManager gm) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Sign-in Update', style: gm.layoutManager?.dialogTitleStyle),
          content: Text('Sign-in is being upgraded. Coming soon.', style: gm.layoutManager?.dialogContentStyle),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
        );
      },
    );

    // Keep returning false to preserve existing callers that branch on login
    // result while this temporary stub is active.
    return false;
  }
}
