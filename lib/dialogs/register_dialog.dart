// File: /lib/dialogs/register_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../managers/gameManager.dart';

class RegisterDialog {
  /// Temporary registration stub while account flows move to platform-linked
  /// IDs and in-app account management.
  static Future<void> show(BuildContext context, GameManager gm) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Registration Update', style: gm.layoutManager?.dialogTitleStyle),
          content: Text('Registration is being upgraded. Coming soon.', style: gm.layoutManager?.dialogContentStyle),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
        );
      },
    );
  }
}
