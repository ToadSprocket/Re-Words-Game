import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/spelled_words_handler.dart';

class SpelledWordsColumn extends StatelessWidget {
  final List<String> words;
  final int score;
  final double columnWidth;
  final double columnHeight;
  final double gridSpacing;
  final double wordColumnWidth;
  final double wordColumnHeight;
  final bool showBorders;

  const SpelledWordsColumn({
    super.key,
    required this.words,
    required this.columnWidth,
    required this.columnHeight,
    required this.gridSpacing,
    required this.score,
    required this.wordColumnWidth,
    required this.wordColumnHeight,
    this.showBorders = false,
  });

  @override
  Widget build(BuildContext context) {
    final splitColumns = SpelledWordsLogic.splitWords(
      words: words,
      columnHeight: wordColumnHeight,
      fontSize: AppStyles.spelledWordsFontSize,
      spacing: AppStyles.spelledWordsVerticalPadding * 2,
    );

    return Container(
      width: columnWidth,
      height: columnHeight,
      decoration:
          showBorders
              ? BoxDecoration(
                border: Border.all(
                  color: AppStyles.spelledWordsOuterBorderColor,
                  width: AppStyles.spelledWordsBorderWidth + 1,
                ),
              )
              : null,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 8.0, bottom: gridSpacing),
            child: Row(
              children: [
                Container(
                  width: columnWidth / 2,
                  decoration:
                      showBorders
                          ? BoxDecoration(
                            border: Border.all(
                              color: AppStyles.spelledWordsHeaderBorderColor,
                              width: AppStyles.spelledWordsBorderWidth,
                            ),
                          )
                          : null,
                  child: Text(
                    'Spelled Words: ${words.length}',
                    style: TextStyle(
                      fontSize: AppStyles.spelledWordsTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.spelledWordsTitleColor,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                Container(
                  width: columnWidth / 2,
                  padding: EdgeInsets.only(right: AppStyles.spelledWordsScoreRightPadding),
                  decoration:
                      showBorders
                          ? BoxDecoration(
                            border: Border.all(
                              color: AppStyles.spelledWordsHeaderBorderColor,
                              width: AppStyles.spelledWordsBorderWidth,
                            ),
                          )
                          : null,
                  child: Text(
                    'Score: $score',
                    style: TextStyle(
                      fontSize: AppStyles.spelledWordsTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.spelledWordsTitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // Left-align first column
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRect(
                  // Clip content to height
                  child: Container(
                    width: wordColumnWidth,
                    height: wordColumnHeight,
                    decoration:
                        showBorders
                            ? BoxDecoration(
                              border: Border.all(
                                color: AppStyles.spelledWordsColumnBorderColor,
                                width: AppStyles.spelledWordsBorderWidth,
                              ),
                            )
                            : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          splitColumns[0].map((word) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: AppStyles.spelledWordsVerticalPadding),
                              child: Text(
                                word,
                                style: TextStyle(
                                  fontSize: AppStyles.spelledWordsFontSize,
                                  color: AppStyles.spelledWordsTextColor,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                if (splitColumns[1].isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: gridSpacing),
                    child: ClipRect(
                      child: Container(
                        width: wordColumnWidth,
                        height: wordColumnHeight,
                        decoration:
                            showBorders
                                ? BoxDecoration(
                                  border: Border.all(
                                    color: AppStyles.spelledWordsColumnBorderColor,
                                    width: AppStyles.spelledWordsBorderWidth,
                                  ),
                                )
                                : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              splitColumns[1].map((word) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppStyles.spelledWordsVerticalPadding),
                                  child: Text(
                                    word,
                                    style: TextStyle(
                                      fontSize: AppStyles.spelledWordsFontSize,
                                      color: AppStyles.spelledWordsTextColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                if (splitColumns[2].isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: gridSpacing),
                    child: ClipRect(
                      child: Container(
                        width: wordColumnWidth,
                        height: wordColumnHeight,
                        decoration:
                            showBorders
                                ? BoxDecoration(
                                  border: Border.all(
                                    color: AppStyles.spelledWordsColumnBorderColor,
                                    width: AppStyles.spelledWordsBorderWidth,
                                  ),
                                )
                                : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              splitColumns[2].map((word) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppStyles.spelledWordsVerticalPadding),
                                  child: Text(
                                    word,
                                    style: TextStyle(
                                      fontSize: AppStyles.spelledWordsFontSize,
                                      color: AppStyles.spelledWordsTextColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
