// lib/layouts/legal_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../styles/app_styles.dart';
import '../managers/gameLayoutManager.dart';

class LegalDialog {
  static void show(BuildContext context, GameLayoutManager gameLayoutManager) {
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
            width: gameLayoutManager.dialogMaxWidth,
            constraints: BoxConstraints(
              maxHeight: gameLayoutManager.dialogMaxHeight,
              minHeight: gameLayoutManager.dialogMinHeight,
            ),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(children: [Center(child: Text('Legal Information', style: gameLayoutManager.dialogTitleStyle))]),
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
                              style: gameLayoutManager.dialogTitleStyle.copyWith(fontSize: 18.0),
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              'Re-Word Game, a word puzzle game, is developed and owned by Digital Relics using Flutter.\n\nAll rights reserved.\n\nNo part of this game—including its graphics, sounds, code, or other assets—may be reproduced, distributed, or transmitted in any form (electronic, mechanical, or otherwise) without prior written permission from Digital Relics.\n\nRe-Word Game is a trademark of Digital Relics.\n\nThis game is for personal entertainment only; unauthorized commercial use is prohibited. We respect your privacy: your email is used solely for account recovery, and your Display Name may appear on high score leaderboards.\n\nWe will never share your information with third parties.\n\nFor inquiries, visit',
                              style: gameLayoutManager.dialogContentStyle,
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
                                style: gameLayoutManager.dialogContentStyle.copyWith(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(' or contact ', style: gameLayoutManager.dialogContentStyle),
                            GestureDetector(
                              onTap: () async {
                                final Uri emailLaunchUri = Uri(scheme: 'mailto', path: 'GameMaster@rewordgame.net');
                                if (await canLaunchUrl(emailLaunchUri)) {
                                  await launchUrl(emailLaunchUri);
                                }
                              },
                              child: Text(
                                'GameMaster@rewordgame.net',
                                style: gameLayoutManager.dialogContentStyle.copyWith(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text('© Digital Relics.', style: gameLayoutManager.dialogContentStyle),
                            const SizedBox(height: 24.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FlutterLogo(size: 32, style: FlutterLogoStyle.markOnly),
                                const SizedBox(width: 16),
                                Image.asset('assets/images/DR_TRANSPARENT.png', width: 32),
                              ],
                            ),
                            Text(' ', style: gameLayoutManager.dialogContentStyle),
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
                  style: gameLayoutManager.buttonStyle(context),
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
