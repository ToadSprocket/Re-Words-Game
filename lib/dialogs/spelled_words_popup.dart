// layouts/spelled_words_popup.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameManager.dart';

class SpelledWordsPopup {
  static void show(BuildContext context) {
    final List<String> words = GameManager().board.spelledWords;

    // Find the longest word to determine column width
    double maxWordWidth = 0;
    final textStyle = TextStyle(
      fontSize: GameManager().layoutManager!.tickerFontSize,
      color: AppStyles.spelledWordsTextColor,
    );

    // Calculate max word width
    for (String word in words) {
      final textPainter = TextPainter(text: TextSpan(text: word, style: textStyle), textDirection: TextDirection.ltr)
        ..layout();
      maxWordWidth = maxWordWidth < textPainter.width ? textPainter.width : maxWordWidth;
    }

    // Add padding to max width
    maxWordWidth += 24.0; // Reduced from 32.0 to 24.0 (12px padding on each side)

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameManager().layoutManager!.componentBorderRadius),
            side: BorderSide(
              color: AppStyles.dialogBorderColor,
              width: GameManager().layoutManager!.componentBorderThickness,
            ),
          ),
          backgroundColor: AppStyles.dialogBackgroundColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate number of columns based on available width
              final dialogWidth = constraints.maxWidth * 0.92; // Increased from 0.9 to use more width
              final columnCount = (dialogWidth / maxWordWidth).floor();

              // Calculate rows needed
              final rowCount = (words.length / columnCount).ceil();

              return Container(
                width: GameManager().layoutManager!.dialogMaxWidth,
                constraints: BoxConstraints(
                  maxHeight: GameManager().layoutManager!.dialogMaxHeight,
                  minHeight: GameManager().layoutManager!.dialogMinHeight,
                ),
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Words Found (${words.length})', style: GameManager().layoutManager!.dialogTitleStyle),
                    const SizedBox(height: 16.0),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced from 8.0
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(columnCount, (columnIndex) {
                              return Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(rowCount, (rowIndex) {
                                    final wordIndex = columnIndex + (rowIndex * columnCount);
                                    if (wordIndex >= words.length) return const SizedBox.shrink();

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2.0, // Reduced from 4.0
                                        horizontal: 6.0, // Reduced from 8.0
                                      ),
                                      child: Text(words[wordIndex], style: textStyle),
                                    );
                                  }),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: GameManager().layoutManager!.buttonStyle(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
