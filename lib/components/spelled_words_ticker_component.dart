// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../dialogs/spelled_words_popup.dart';
import '../managers/gameManager.dart';

class SpelledWordsTickerComponent extends StatelessWidget {
  final double gridSize;
  final double squareSize;
  final List<String> words;
  final VoidCallback? onTap;

  const SpelledWordsTickerComponent({
    super.key,
    required this.gridSize,
    required this.squareSize,
    required this.words,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;
    final double tickerWidth = (gridSize + squareSize) * layout.tickerWidthFactor;
    final double contentHeight = layout.tickerHeight - layout.tickerTitleFontSize;

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
          onTap: onTap ?? () => SpelledWordsPopup.show(context),
          child: Container(
            width: tickerWidth,
            height: contentHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppStyles.tickerBorderColor.withOpacity(0.5),
                width: layout.componentBorderThickness,
              ),
              borderRadius: BorderRadius.circular(layout.componentBorderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(layout.componentBorderRadius),
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
                            style: TextStyle(fontSize: layout.tickerFontSize, color: AppStyles.spelledWordsTextColor),
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
                                    fontSize: layout.tickerFontSize * AppStyles.tickerDotSizeFactor,
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
