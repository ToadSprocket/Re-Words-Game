// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameLayoutManager.dart';

class SpelledWordsColumnComponent extends StatelessWidget {
  final List<String> words;
  final double columnWidth;
  final double columnHeight;
  final double gridSpacing;
  final double wordColumnHeight;
  final bool showBorders;
  final GameLayoutManager gameLayoutManager;

  const SpelledWordsColumnComponent({
    super.key,
    required this.words,
    required this.columnWidth,
    required this.columnHeight,
    required this.gridSpacing,
    required this.wordColumnHeight,
    required this.gameLayoutManager,
    this.showBorders = false,
  });

  int _calculateWordsPerColumn(double height) {
    const lineHeightFactor = 1.4;
    const safetyMargin = 0.95; // Add 5% safety margin to prevent overflow

    final totalItemHeight =
        (gameLayoutManager.spelledWordsFontSize * lineHeightFactor) +
        (gameLayoutManager.spelledWordsVerticalPadding * 2);

    // Calculate available height with safety margin
    final availableHeight = height * safetyMargin;

    // Calculate max words that can fit
    int maxWords = (availableHeight / totalItemHeight).floor();

    // Ensure at least one word fits
    return maxWords.clamp(1, words.length);
  }

  List<List<String>> _organizeColumns(BuildContext context, BoxConstraints constraints) {
    var columnsTotal = 0;
    var totalColumnsWidth = 0.0;
    if (words.isEmpty) return [];

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(style: TextStyle(fontSize: gameLayoutManager.spelledWordsFontSize)),
    );

    // Calculate initial words per column
    int wordsPerColumn = _calculateWordsPerColumn(wordColumnHeight);

    // Initial column distribution
    List<List<String>> columns = [];
    for (int i = 0; i < words.length; i += wordsPerColumn) {
      columns.add(words.sublist(i, i + wordsPerColumn > words.length ? words.length : i + wordsPerColumn));
    }

    // Calculate total width needed
    double totalWidth = 0;
    List<double> columnWidths =
        columns.map((columnWords) {
          double maxWidth = 0;
          for (String word in columnWords) {
            textPainter.text = TextSpan(text: word, style: TextStyle(fontSize: gameLayoutManager.spelledWordsFontSize));
            textPainter.layout();
            if (textPainter.width > maxWidth) maxWidth = textPainter.width;
          }
          double columnWidth = maxWidth + (gameLayoutManager.spelledWordsVerticalPadding * 4);
          return columnWidth;
        }).toList();

    // Calculate total width including spacing between columns
    totalColumnsWidth =
        columnWidths.fold(0.0, (sum, width) => sum + width) +
        (gameLayoutManager.spelledWordsColumnSpacing * (columns.length - 1));

    // If columns don't fit in available width, try to optimize distribution
    if (totalColumnsWidth > constraints.maxWidth && columns.length > 1) {
      // Recalculate with more words per column
      wordsPerColumn = ((words.length / (columns.length - 1)) + 0.5).floor();
      wordsPerColumn = wordsPerColumn.clamp(1, _calculateWordsPerColumn(wordColumnHeight));

      columns.clear();
      for (int i = 0; i < words.length; i += wordsPerColumn) {
        columns.add(words.sublist(i, i + wordsPerColumn > words.length ? words.length : i + wordsPerColumn));
      }
    }

    // Update GameLayoutManager with the final values
    columnsTotal = columns.length;

    return columns;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: columnWidth,
      height: columnHeight,
      decoration:
          showBorders
              ? BoxDecoration(border: Border.all(color: AppStyles.spelledWordsOuterBorderColor, width: 1))
              : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = _organizeColumns(context, constraints);

          if (columns.isEmpty) {
            return const SizedBox.shrink();
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  columns.map((columnWords) {
                    return Padding(
                      padding: EdgeInsets.only(right: gameLayoutManager.spelledWordsColumnSpacing),
                      child: Container(
                        height: wordColumnHeight,
                        decoration:
                            showBorders
                                ? BoxDecoration(
                                  border: Border.all(color: AppStyles.spelledWordsColumnBorderColor, width: 1),
                                )
                                : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              columnWords.map((word) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: gameLayoutManager.spelledWordsVerticalPadding,
                                    horizontal: gameLayoutManager.spelledWordsVerticalPadding * 2,
                                  ),
                                  child: Text(
                                    word,
                                    style: TextStyle(
                                      fontSize: gameLayoutManager.spelledWordsFontSize,
                                      color: AppStyles.spelledWordsTextColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }
}
