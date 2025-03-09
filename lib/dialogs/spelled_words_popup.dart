// layouts/spelled_words_popup.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/spelled_words_handler.dart';

class SpelledWordsPopup {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppStyles.dialogBackgroundColor,
            child: SizedBox(
              width: AppStyles.tickerPopupWidth,
              height: AppStyles.tickerPopupHeight,
              child: Padding(
                padding: const EdgeInsets.all(AppStyles.dialogPadding),
                child: Column(
                  children: [
                    const Text('Words Found', style: AppStyles.dialogTitleStyle),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: SingleChildScrollView(
                        child: GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppStyles.tickerPopupCrossSpacing, // 0.5
                          mainAxisSpacing: AppStyles.tickerPopupMainSpacing, // 0.5
                          childAspectRatio: 8.0, // Taller, narrower cells
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children:
                              SpelledWordsLogic.spelledWords
                                  .map(
                                    (word) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        // Removed Padding
                                        word,
                                        style: TextStyle(color: AppStyles.spelledWordsTextColor),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: AppStyles.buttonStyle(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
