// lib/layouts/legal_dialog.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LegalDialog {
  static void show(BuildContext context) {
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
            width: AppStyles.dialogWidth,
            height: AppStyles.dialogHeight * 1.2, // Increased height for more content
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Center(child: Text('Legal', style: AppStyles.dialogTitleStyle)),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Re-Word Game – Copyright Notice',
                          style: AppStyles.dialogTitleStyle.copyWith(fontSize: 18.0),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Re-Word Game is a word puzzle game developed by Riverstone Entertainment.',
                          style: AppStyles.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'All rights reserved. No part of this game may be reproduced, distributed, or transmitted in any form or by any means—including photocopying, recording, or other electronic or mechanical methods—without prior written permission from the publisher.',
                          style: AppStyles.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Re-Word Game is a trademark of Riverstone Entertainment.',
                          style: AppStyles.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'All game assets, including graphics, sounds, and code, are the exclusive property of Riverstone Entertainment.',
                          style: AppStyles.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'This game is intended for personal use and entertainment purposes only.',
                          style: AppStyles.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text('Contact Information', style: AppStyles.dialogTitleStyle.copyWith(fontSize: 18.0)),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.language, size: 16.0, color: AppStyles.textColor),
                            const SizedBox(width: 8.0),
                            Text(
                              'www.rewordgame.net',
                              style: AppStyles.dialogContentStyle.copyWith(decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16.0, color: AppStyles.textColor),
                            const SizedBox(width: 8.0),
                            Text('GameMaster@rewordgame.net', style: AppStyles.dialogContentStyle),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Re-Word Game © 2025 Riverstone Entertainment. All rights reserved.',
                          style: AppStyles.dialogContentStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.dialogButtonPadding),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: AppStyles.buttonStyle(context),
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
