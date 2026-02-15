// File: /lib/dialogs/legal_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../styles/app_styles.dart';
import '../dialogs/delete_account_dialog.dart';
import '../main.dart' show VERSION_STRING;
import '../logic/logging_handler.dart';
import '../managers/gameManager.dart';

class LegalDialog {
  static void show(BuildContext context, GameManager gm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
            side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
          ),
          backgroundColor: AppStyles.dialogBackgroundColor,
          child: Container(
            width: gm.layoutManager!.dialogMaxWidth,
            constraints: BoxConstraints(
              maxHeight: gm.layoutManager!.dialogMaxHeight,
              minHeight: gm.layoutManager!.dialogMinHeight,
            ),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(children: [Center(child: Text('Legal Information', style: gm.layoutManager!.dialogTitleStyle))]),
                const SizedBox(height: 16.0),
                Flexible(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Re-Word Game – Copyright Notice',
                              style: gm.layoutManager!.dialogTitleStyle.copyWith(fontSize: 18.0),
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              'Re-Word Game, a word puzzle game, is developed and owned by Digital Relics using Flutter.\n\nAll rights reserved.\n\nNo part of this game—including its graphics, sounds, code, or other assets—may be reproduced, distributed, or transmitted in any form (electronic, mechanical, or otherwise) without prior written permission from Digital Relics.\n\nRe-Word Game is a trademark of Digital Relics.\n\nThis game is for personal entertainment only; unauthorized commercial use is prohibited. We respect your privacy: your email is used solely for account recovery, and your Display Name may appear on high score leaderboards.\n\nWe will never share your information with third parties.\n\nFor inquiries, visit',
                              style: gm.layoutManager!.dialogContentStyle,
                            ),
                            GestureDetector(
                              onTap: () async {
                                final Uri url = Uri.parse('https://www.rewordgame.net');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              child: Text(
                                'www.rewordgame.net',
                                style: gm.layoutManager!.dialogContentStyle.copyWith(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(' or contact ', style: gm.layoutManager!.dialogContentStyle),
                            GestureDetector(
                              onTap: () async {
                                final Uri emailLaunchUri = Uri(scheme: 'mailto', path: 'GameMaster@rewordgame.net');
                                if (await canLaunchUrl(emailLaunchUri)) {
                                  await launchUrl(emailLaunchUri);
                                }
                              },
                              child: Text(
                                'GameMaster@rewordgame.net',
                                style: gm.layoutManager!.dialogContentStyle.copyWith(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text('© Digital Relics.', style: gm.layoutManager!.dialogContentStyle),

                            // Add account deletion section only for logged-in users
                            const SizedBox(height: 16.0),
                            Divider(color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 16.0),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        'If you wish to permanently delete all your Reword Game data, including scores, stats, and account details, tap ',
                                    style: gm.layoutManager!.dialogContentStyle,
                                  ),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context); // Close legal dialog
                                        DeleteAccountDialog.show(context, gm);
                                      },
                                      child: Text('account deletion dialog', style: gm.layoutManager!.dialogLinkStyle),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '. Please note: This action is irreversible and will erase all your progress.',
                                    style: gm.layoutManager!.dialogContentStyle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FlutterLogo(size: 32, style: FlutterLogoStyle.markOnly),
                                const SizedBox(width: 16),
                                Image.asset('assets/images/DR_TRANSPARENT.png', width: 32),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Display version information
                            Center(
                              child: Text(
                                VERSION_STRING,
                                style: gm.layoutManager!.dialogContentStyle.copyWith(
                                  fontSize: 12,
                                  color: const Color.fromARGB(255, 201, 199, 199),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Add debug logs section
                            ...[
                              const SizedBox(height: 16.0),
                              Divider(color: Colors.grey.withOpacity(0.5), thickness: 1),
                              const SizedBox(height: 16.0),

                              // Logs section header with a button to clear logs
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Debug Logs',
                                    style: gm.layoutManager!.dialogTitleStyle.copyWith(fontSize: 18.0),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Clear logs and rebuild dialog
                                      LogService.clearEvents();
                                      Navigator.of(context).pop();
                                      LegalDialog.show(context, gm);
                                    },
                                    child: Text('Clear Logs', style: TextStyle(color: Colors.blue)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12.0),

                              // Container for logs with a different background to distinguish it
                              Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // If no logs, show a message
                                    if (LogService.getLogEvents().isEmpty)
                                      Text('No logs recorded yet.', style: gm.layoutManager!.dialogContentStyle),

                                    // Otherwise, show all logs
                                    ...LogService.getLogEvents().map((log) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          log,
                                          style: gm.layoutManager!.dialogContentStyle.copyWith(
                                            fontSize: 12.0,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24.0),
                            ],
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppStyles.dialogBackgroundColor.withOpacity(0), AppStyles.dialogBackgroundColor],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.dialogButtonPadding),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: gm.layoutManager!.buttonStyle(context),
                  child: const Text('Close'),
                ),
                const SizedBox(height: AppStyles.dialogButtonPadding),
              ],
            ),
          ),
        );
      },
    );
  }
}
