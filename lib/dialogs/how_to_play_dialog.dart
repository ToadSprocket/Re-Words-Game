// File: /lib/dialogs/how_to_play_dialog.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../components/letter_square_component.dart';
import '../models/tile.dart';
import '../managers/gameManager.dart';

class HowToPlayDialog {
  static void show(BuildContext context, GameManager gm) {
    final layout = gm.layoutManager!;
    final standardTile = Tile(letter: 'A', value: 1, state: 'unused', isExtra: false, isRemoved: false);
    final usedTile = Tile(letter: 'B', value: 2, state: 'used', useCount: 1, isExtra: false, isRemoved: false);
    final wildcardTile = Tile(letter: 'W', value: 2, state: 'unused', isExtra: true, isRemoved: false);

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
            width: layout.dialogMaxWidth,
            constraints: BoxConstraints(
              maxHeight: layout.dialogMaxHeight,
              minHeight: layout.dialogMinHeight,
              minWidth: 280.0,
            ),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(children: [Center(child: Text('How to Play Re-Word', style: layout.dialogTitleStyle))]),
                const SizedBox(height: 16.0),
                Flexible(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Objective', style: layout.dialogTitleStyle.copyWith(fontSize: 18.0)),
                            Text(
                              'Find words in the 7x7 grid and maximize your score by strategically reusing letters.',
                              style: layout.dialogContentStyle,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              'Form words using adjacent letters in any direction (horizontal, vertical, diagonal).\n'
                              'A letter used more than once in different words doubles in value every time it\'s reused.\n'
                              'You can use a letter up to 8 times, after that it\'s value is capped. You cannot use the same word twice.\n\n'
                              'Five Wildcards can be placed on unused tiles to multiply the total word score.',
                              style: layout.dialogContentStyle,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                            const SizedBox(height: 12.0),
                            Row(
                              children: [
                                LetterSquareComponent(tile: standardTile, helpDialog: true),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Basic: Letter tile with a base score.',
                                    style: layout.dialogContentStyle,
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                LetterSquareComponent(tile: usedTile, helpDialog: true),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Used: Each re-use doubles its value.',
                                    style: layout.dialogContentStyle,
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                LetterSquareComponent(tile: wildcardTile, helpDialog: true),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Wildcard: Multiplies word value.',
                                    style: layout.dialogContentStyle,
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              'Plan ahead! Reuse letters as much as possible to stack multipliers.\n'
                              'Wildcards can dramatically boost your score when used in high-value words.\n'
                              'Longer words = higher points!\n'
                              'Can you maximize the board and achieve the highest possible score?',
                              style: layout.dialogContentStyle,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                            const SizedBox(height: 12.0),
                            Center(
                              child: Text(
                                'Re-Think. Strategize. Re-Word!\n',
                                style: layout.dialogContentStyle.copyWith(fontWeight: layout.defaultFontWeight),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
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
                              colors: [
                                AppStyles.dialogBackgroundColor.withValues(alpha: 0),
                                AppStyles.dialogBackgroundColor,
                              ],
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
                  style: layout.buttonStyle(context),
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
