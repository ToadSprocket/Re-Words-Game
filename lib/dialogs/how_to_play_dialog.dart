// lib/dialogs/how_to_play_dialog.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../components/letter_square_component.dart';
import '../models/tile.dart';

class HowToPlayDialog {
  static void show(BuildContext context) {
    final sizes = {
      'squareSize': 42.0, // Match GameGridComponent default
      'squareLetterSize': 20.0, // Typical letter size
      'squareValueSize': 12.0, // Smaller for value
    };

    final standardTile = Tile(letter: 'A', value: 1, state: 'unused', isExtra: true);
    final usedTile = Tile(letter: 'B', value: 2, state: 'used', useCount: 1, isExtra: false);
    final wildcardTile = Tile(letter: 'W', value: 2, state: 'unused', isExtra: true);

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
            height: AppStyles.dialogHeight * 1.2,
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Center(child: Text('How to Play Re-Word', style: AppStyles.dialogTitleStyle)),
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
                        Text('Objective', style: AppStyles.dialogTitleStyle.copyWith(fontSize: 18.0)),
                        Text(
                          'Find words in the 7x7 grid and maximize your score by strategically reusing letters.',
                          style: AppStyles.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text('Game Rules', style: AppStyles.dialogTitleStyle.copyWith(fontSize: 18.0)),
                        Text(
                          'Form words using adjacent letters in any direction (horizontal, vertical, diagonal).\n'
                          'A letter used more than once in different words doubles in value every time it’s reused.\n'
                          'You cannot use the same word twice.\n'
                          'Five Wildcards can be placed on unused tiles to multiply the total word score.',
                          style: AppStyles.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Text('Tile Types', style: AppStyles.dialogTitleStyle.copyWith(fontSize: 18.0)),
                        Row(
                          children: [
                            LetterSquareComponent(tile: standardTile, sizes: sizes),
                            const SizedBox(width: 8.0),
                            Text('Standard: Letter tile with a base score.', style: AppStyles.dialogContentStyle),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            LetterSquareComponent(tile: usedTile, sizes: sizes),
                            const SizedBox(width: 8.0),
                            Text('Used: Each reuse doubles its value.', style: AppStyles.dialogContentStyle),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            LetterSquareComponent(tile: wildcardTile, sizes: sizes),
                            const SizedBox(width: 8.0),
                            Text('Wildcard: Multiply the word’s total value.', style: AppStyles.dialogContentStyle),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text('Scoring Strategy', style: AppStyles.dialogTitleStyle.copyWith(fontSize: 18.0)),
                        Text(
                          'Plan ahead! Reuse letters as much as possible to stack multipliers.\n'
                          'Wildcards can dramatically boost your score when used in high-value words.\n'
                          'Longer words = higher points!\n'
                          'Can you maximize the board and achieve the highest possible score?',
                          style: AppStyles.dialogContentStyle,
                        ),
                        const SizedBox(height: 12.0),
                        Center(
                          child: Text(
                            'Re-Think. Strategize. Re-Word!',
                            style: AppStyles.dialogContentStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.dialogButtonPadding - 8.0),
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
