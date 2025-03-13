// lib/layouts/high_scores_dialog.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this for date formatting
import '../styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../logic/api_service.dart';
import '../models/api_models.dart';
import '../logic/spelled_words_handler.dart';

class HighScoresDialog {
  static Future<void> show(BuildContext context, ApiService api, SpelledWordsLogic spelledWordsLogic) async {
    List<HighScore> highScores = [];
    String? date = 'Today';
    bool loggedIn = api.loggedIn ?? false; // ✅ Ensure loggedIn is always initialized
    bool canSubmitScore = false;
    bool hasGoodScore = false; // ✅ Track if the player's score is "good"

    // ✅ Ensure finalScore is always initialized
    SubmitScoreRequest finalScore = SubmitScoreRequest(
      userId: '',
      platform: '',
      locale: '',
      timePlayedSeconds: 0,
      wordCount: 0,
      wildcardUses: 0,
      score: 0,
      completionRate: 0,
      longestWordLength: 0,
    );

    try {
      finalScore = await SpelledWordsLogic.getCurrentScore();
      final response = await api.getTodayHighScores();
      highScores = response.highScoreData?.highScores ?? [];
      final rawDate = response.highScoreData?.date ?? 'Today';
      date =
          rawDate == 'Today'
              ? 'Today'
              : DateFormat('MMMM d, yyyy').format(DateTime.parse(rawDate)); // e.g., "March 9, 2025"

      // ✅ Determine if the player qualifies to submit a high score
      if (highScores.isEmpty || finalScore.score > highScores.last.score) {
        canSubmitScore = true; // Allow if empty OR score is higher than the lowest on the board
      }

      // ✅ Determine if the player has a "good" score
      int topScoreThreshold = highScores.isNotEmpty ? highScores.first.score : 1500; // Default high threshold
      hasGoodScore =
          finalScore.score > (topScoreThreshold * 0.5) || finalScore.score >= 1000; // 50% of the best or >1000
    } catch (e) {
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
            height: AppStyles.dialogHeight * 1.35, // Slightly taller for extra message
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

                // ✅ "Submit Score" Button - Only shows if logged in & score qualifies
                if (loggedIn && canSubmitScore)
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await api.submitHighScore(finalScore);
                        Navigator.of(context).pop();
                        print("✅ High score submitted successfully!");
                      } catch (e) {
                        print("🚨 Error submitting high score: $e");
                      }
                    },
                    style: AppStyles.buttonStyle(context),
                    child: const Text('Submit Score'),
                  ),

                // ✅ Encouraging login message if player has a good score but is NOT logged in
                if (!loggedIn && hasGoodScore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    child: Center(
                      child: Text(
                        finalScore.score > 2000
                            ? "🔥 Awesome score! Want to see your name on the leaderboard? Log in to submit your score!"
                            : "Nice work! Log in to track your progress and submit high scores!",
                        style: AppStyles.dialogSuccessStyle,
                        textAlign: TextAlign.center,
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
