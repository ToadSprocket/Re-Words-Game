// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameManager.dart';
import '../config/debugConfig.dart';

class SpelledWordsColumnComponent extends StatelessWidget {
  final List<String> words;
  final double columnWidth;
  final double columnHeight;
  final double gridSpacing;
  final double wordColumnHeight;

  const SpelledWordsColumnComponent({
    super.key,
    required this.words,
    required this.columnWidth,
    required this.columnHeight,
    required this.gridSpacing,
    required this.wordColumnHeight,
  });

  int _calculateWordsPerColumn(double height) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;
    const lineHeightFactor = 1.4;
    const safetyMargin = 0.95;

    final totalItemHeight = (layout.spelledWordsFontSize * lineHeightFactor) + (layout.spelledWordsVerticalPadding * 2);

    final availableHeight = height * safetyMargin;
    int maxWords = (availableHeight / totalItemHeight).floor();
    return maxWords.clamp(1, words.length);
  }

  List<List<String>> _organizeColumns(BuildContext context, BoxConstraints constraints) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;
    var columnsTotal = 0;
    var totalColumnsWidth = 0.0;
    if (words.isEmpty) return [];

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(style: TextStyle(fontSize: layout.spelledWordsFontSize)),
    );

    int wordsPerColumn = _calculateWordsPerColumn(wordColumnHeight);

    List<List<String>> columns = [];
    for (int i = 0; i < words.length; i += wordsPerColumn) {
      columns.add(words.sublist(i, i + wordsPerColumn > words.length ? words.length : i + wordsPerColumn));
    }

    double totalWidth = 0;
    List<double> columnWidths =
        columns.map((columnWords) {
          double maxWidth = 0;
          for (String word in columnWords) {
            textPainter.text = TextSpan(text: word, style: TextStyle(fontSize: layout.spelledWordsFontSize));
            textPainter.layout();
            if (textPainter.width > maxWidth) maxWidth = textPainter.width;
          }
          double columnWidth = maxWidth + (layout.spelledWordsVerticalPadding * 4);
          return columnWidth;
        }).toList();

    totalColumnsWidth =
        columnWidths.fold(0.0, (sum, width) => sum + width) + (layout.spelledWordsColumnSpacing * (columns.length - 1));

    if (totalColumnsWidth > constraints.maxWidth && columns.length > 1) {
      wordsPerColumn = ((words.length / (columns.length - 1)) + 0.5).floor();
      wordsPerColumn = wordsPerColumn.clamp(1, _calculateWordsPerColumn(wordColumnHeight));

      columns.clear();
      for (int i = 0; i < words.length; i += wordsPerColumn) {
        columns.add(words.sublist(i, i + wordsPerColumn > words.length ? words.length : i + wordsPerColumn));
      }
    }

    columnsTotal = columns.length;
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;

    return Container(
      width: columnWidth,
      height: columnHeight,
      decoration:
          DebugConfig().showBorders
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
                      padding: EdgeInsets.only(right: layout.spelledWordsColumnSpacing),
                      child: Container(
                        height: wordColumnHeight,
                        decoration:
                            DebugConfig().showBorders
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
                                    vertical: layout.spelledWordsVerticalPadding,
                                    horizontal: layout.spelledWordsVerticalPadding * 2,
                                  ),
                                  child: Text(
                                    word,
                                    style: TextStyle(
                                      fontSize: layout.spelledWordsFontSize,
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
