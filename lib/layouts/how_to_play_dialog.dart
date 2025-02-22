// layouts/how_to_play_dialog.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../components/letter_square.dart';
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
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0), // Adjusted bottom padding
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
                        child: const FaIcon(
                          FontAwesomeIcons.circleXmark,
                          size: 20.0, // Match other icons
                          color: AppStyles.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  // Pushes content up, button down
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
                          LetterSquare(
                            letter: 'A',
                            value: 1,
                            squareSize: 40.0,
                            letterFontSize: 20.0,
                            valueFontSize: 10.0,
                          ),
                          const SizedBox(width: 4.0),
                          LetterSquare(
                            letter: 'G',
                            value: 2,
                            isWildcard: true,
                            squareSize: 40.0,
                            letterFontSize: 20.0,
                            valueFontSize: 10.0,
                          ),
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
                const SizedBox(height: AppStyles.dialogButtonPadding), // Padding above button
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
