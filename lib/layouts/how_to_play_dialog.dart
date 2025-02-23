// layouts/how_to_play_dialog.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../components/letter_square.dart';
import '../logic/tile.dart'; // Add for Tile
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HowToPlayDialog {
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
            height: AppStyles.dialogHeight,
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Center(child: Text('How to Play', style: AppStyles.dialogTitleStyle)),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Form words up to 12 letters using the 7x7 grid.',
                        style: AppStyles.dialogContentStyle,
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LetterSquare(tile: Tile(letter: 'A', value: 1, isExtra: false)),
                          const SizedBox(width: 4.0),
                          LetterSquare(tile: Tile(letter: 'G', value: 2, isExtra: true)),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Wildcards (*) substitute any letter. No repeats!',
                        style: AppStyles.dialogContentStyle,
                      ),
                    ],
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
