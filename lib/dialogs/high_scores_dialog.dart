// lib/layouts/high_scores_dialog.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this for date formatting
import '../styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../logic/api_service.dart';
import '../models/api_models.dart';

class HighScoresDialog {
  static Future<void> show(BuildContext context, ApiService api) async {
    List<HighScore> highScores;
    String? date;
    try {
      final response = await api.getTodayHighScores();
      highScores = response.highScoreData?.highScores ?? [];
      final rawDate = response.highScoreData?.date ?? 'Today';
      date =
          rawDate == 'Today'
              ? 'Today'
              : DateFormat('MMMM d, yyyy').format(DateTime.parse(rawDate)); // e.g., "March 9, 2025"
    } catch (e) {
      highScores = [];
      date = 'Today';
      print('Failed to fetch high scores: $e');
    }

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
            height: AppStyles.dialogHeight * 1.2,
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Center(child: Text('High Scores - $date', style: AppStyles.dialogTitleStyle)),
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
                  child: SingleChildScrollView(
                    child: Center(
                      // Center the list
                      child: SizedBox(
                        width: AppStyles.dialogWidth * 0.8, // 80% width
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (highScores.isEmpty)
                              Text('No high scores available yet.', style: AppStyles.dialogContentStyle)
                            else
                              ...highScores.asMap().entries.map((entry) {
                                final rank = entry.key + 1;
                                final score = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('$rank. ${score.displayName}', style: AppStyles.dialogContentStyle),
                                      Text(
                                        '${score.score} (${score.wordCount} words)',
                                        style: AppStyles.dialogContentStyle.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
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
