// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../dialogs/spelled_words_popup.dart';

class SpelledWordsTickerComponent extends StatelessWidget {
  final double gridSize;
  final double squareSize;
  final List<String> words; // Add this
  final VoidCallback? onTap;

  const SpelledWordsTickerComponent({
    super.key,
    required this.gridSize,
    required this.squareSize,
    required this.words, // Required prop
    this.onTap,
  });

  List<String> _getFittingWords(BuildContext context, double maxWidth) {
    final textStyle = TextStyle(fontSize: AppStyles.tickerFontSize, color: AppStyles.spelledWordsTextColor);
    final List<String> fittingWords = [];
    double currentWidth = 0.0;
    const double widthOffset = 6.0; // Small offset per word

    for (String word in words.reversed) {
      // Use passed words
      final textPainter = TextPainter(
        text: TextSpan(text: '$word ', style: textStyle), // Single space
        textDirection: TextDirection.ltr,
      )..layout();

      double adjustedWidth = textPainter.width + widthOffset; // Add offset
      if (currentWidth + adjustedWidth <= maxWidth) {
        fittingWords.add(word);
        currentWidth += adjustedWidth;
      } else {
        break;
      }
    }

    return fittingWords.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final double tickerWidth = (gridSize + squareSize) * AppStyles.tickerWidthFactor;

    final List<String> visibleWords = _getFittingWords(context, tickerWidth - 16.0); // Padding inset

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Words',
          style: TextStyle(
            fontSize: AppStyles.tickerTitleFontSize,
            color: AppStyles.spelledWordsTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        GestureDetector(
          onTap: onTap ?? () => SpelledWordsPopup.show(context),
          child: Container(
            width: tickerWidth,
            height: AppStyles.tickerHeight - AppStyles.tickerTitleFontSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppStyles.tickerBorderColor.withOpacity(0.5),
                width: AppStyles.tickerBorderWidth,
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              reverse: false,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    visibleWords.isNotEmpty ? visibleWords.join('  ') : 'No words yet',
                    style: TextStyle(fontSize: AppStyles.tickerFontSize, color: AppStyles.spelledWordsTextColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
