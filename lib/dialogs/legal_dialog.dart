// lib/layouts/legal_dialog.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Re-Word Game – Copyright Notice',
                          style: gameLayoutManager.dialogTitleStyle.copyWith(fontSize: 18.0),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Re-Word Game is a word puzzle game developed by Digital Relics.',
                          style: gameLayoutManager.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'All rights reserved. No part of this game may be reproduced, distributed, or transmitted in any form or by any means—including photocopying, recording, or other electronic or mechanical methods—without prior written permission from the publisher.',
                          style: gameLayoutManager.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Re-Word Game is a trademark of Digital Relics.',
                          style: gameLayoutManager.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'All game assets, including graphics, sounds, and code, are the exclusive property of Digital Relics.',
                          style: gameLayoutManager.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'This game is intended for personal use and entertainment purposes only.',
                          style: gameLayoutManager.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text('Contact Information', style: gameLayoutManager.dialogTitleStyle.copyWith(fontSize: 18.0)),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.language, size: 16.0, color: AppStyles.dialogIconColor),
                            const SizedBox(width: 8.0),
                            Text(
                              'www.rewordgame.net',
                              style: gameLayoutManager.dialogContentStyle.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16.0, color: AppStyles.dialogIconColor),
                            const SizedBox(width: 8.0),
                            Text('GameMaster@rewordgame.net', style: gameLayoutManager.dialogContentStyle),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Re-Word Game © 2025 Digital Relics. All rights reserved.',
                          style: gameLayoutManager.dialogContentStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
