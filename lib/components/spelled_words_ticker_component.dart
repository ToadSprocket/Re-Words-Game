// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../dialogs/spelled_words_popup.dart';
import '../managers/gameLayoutManager.dart';

class SpelledWordsTickerComponent extends StatelessWidget {
  final double gridSize;
  final double squareSize;
  final List<String> words; // Add this
  final VoidCallback? onTap;
  final GameLayoutManager gameLayoutManager;

  const SpelledWordsTickerComponent({
    super.key,
    required this.gridSize,
    required this.squareSize,
    required this.words, // Required prop
    this.onTap,
    required this.gameLayoutManager,
  });

  List<String> _getFittingWords(BuildContext context, double maxWidth) {
    final textStyle = TextStyle(fontSize: gameLayoutManager.tickerFontSize, color: AppStyles.spelledWordsTextColor);
    final List<String> fittingWords = [];
    double currentWidth = 0.0;
    const double widthOffset = 6.0; // Small offset per word

    for (String word in words.reversed) {
      final textPainter = TextPainter(
        text: TextSpan(text: '$word ', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      double adjustedWidth = textPainter.width + widthOffset;
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
    final double tickerWidth = (gridSize + squareSize) * gameLayoutManager.tickerWidthFactor;
    final double contentHeight = gameLayoutManager.tickerHeight - gameLayoutManager.tickerTitleFontSize;

    // Create a scroll controller to manage automatic scrolling
    final ScrollController scrollController = ScrollController();

    // Use a post-frame callback to scroll to the end after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4.0),
        GestureDetector(
          onTap: onTap ?? () => SpelledWordsPopup.show(context, gameLayoutManager),
          child: Container(
            width: tickerWidth,
            height: contentHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppStyles.tickerBorderColor.withOpacity(0.5),
                width: gameLayoutManager.componentBorderThickness,
              ),
              borderRadius: BorderRadius.circular(gameLayoutManager.componentBorderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(gameLayoutManager.componentBorderRadius),
              child: ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                reverse: false,
                itemCount: words.length,
                padding: const EdgeInsets.only(right: 4.0),
                itemBuilder: (context, index) {
                  final word = words[index];
                  return Container(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 16.0 : 0.0,
                      right: index == words.length - 1 ? 20.0 : 0.0,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            word,
                            style: TextStyle(
                              fontSize: gameLayoutManager.tickerFontSize,
                              color: AppStyles.spelledWordsTextColor,
                            ),
                          ),
                          if (index < words.length - 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              alignment: Alignment.center,
                              child: Transform.translate(
                                offset: const Offset(0, -1),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: gameLayoutManager.tickerFontSize * AppStyles.tickerDotSizeFactor,
                                    height: 1.0,
                                    color: AppStyles.tickerDotsColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
