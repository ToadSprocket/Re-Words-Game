import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../logic/api_service.dart';
import '../models/api_models.dart';
import '../logic/spelled_words_handler.dart';
import '../managers/state_manager.dart';

class HighScoresDialog {
  static Future<void> show(BuildContext context, ApiService api, SpelledWordsLogic spelledWordsLogic) async {
    await _loadAndShowDialog(context, api, spelledWordsLogic);
  }

  static Future<void> _loadAndShowDialog(
    BuildContext context,
    ApiService api,
    SpelledWordsLogic spelledWordsLogic,
  ) async {
    List<HighScore> highScores = [];
    String? date = 'Today';
    bool loggedIn = api.loggedIn ?? false;
    bool canSubmitScore = false;
    bool hasGoodScore = false;
    bool userHasSubmitted = false;
    int scoresSubmittedToday = 0;
    int? userRank;

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
      scoresSubmittedToday = response.highScoreData?.totalScoresToday ?? 0;
      userHasSubmitted = response.highScoreData?.userHasSubmitted ?? false;
      userRank = response.highScoreData?.userRank;

      final rawDate = response.highScoreData?.date ?? 'Today';
      date = rawDate == 'Today' ? 'Today' : DateFormat('MMMM d, yyyy').format(DateTime.parse(rawDate).toUtc());

      if (!userHasSubmitted && (highScores.isEmpty || finalScore.score > highScores.last.score)) {
        canSubmitScore = true;
      }

      int topScoreThreshold = highScores.isNotEmpty ? highScores.first.score : 1500;
      hasGoodScore = finalScore.score > (topScoreThreshold * 0.5) || finalScore.score >= 1000;
    } catch (e) {
      print('Failed to fetch high scores: $e');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double maxHeight = constraints.maxHeight * 0.8; // Limit max height to 80% of screen
            double minHeight = 200.0; // Minimum height
            double calculatedHeight = (15 + (highScores.length * 50)).clamp(minHeight, maxHeight).toDouble(); // Dynamic

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
                side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
              ),
              backgroundColor: AppStyles.dialogBackgroundColor,
              child: Container(
                width: AppStyles.dialogWidth,
                height: calculatedHeight, // ✅ Dynamic height
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(children: [Center(child: Text('High Scores - $date', style: AppStyles.dialogTitleStyle))]),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: SizedBox(
                            width: AppStyles.dialogWidth * 0.8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (highScores.isEmpty)
                                  Text('No high scores available yet.', style: AppStyles.dialogContentStyle)
                                else
                                  ...highScores.map((score) {
                                    bool isUser = score.ranking == userRank;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${score.ranking}. ${score.displayName}',
                                            style:
                                                isUser
                                                    ? AppStyles.dialogContentHighLiteStyle
                                                    : AppStyles.dialogContentStyle,
                                          ),
                                          Text(
                                            '${score.score} (${score.wordCount} words)',
                                            style: AppStyles.dialogContentStyle.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                // ✅ Show user's ranking if not in top scores
                                if (userHasSubmitted &&
                                    userRank != null &&
                                    !highScores.any((s) => s.ranking == userRank))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Center(
                                      child: Text(
                                        'Your Ranking: #$userRank out of $scoresSubmittedToday players',
                                        style: AppStyles.dialogContentHighLiteStyle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppStyles.dialogButtonPadding),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (loggedIn && canSubmitScore)
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                final scoreSubmitted = await api.submitHighScore(finalScore);
                                if (scoreSubmitted) {
                                  print("✅ High score submitted successfully!");
                                  Navigator.of(context).pop(); // Close dialog
                                  await Future.delayed(const Duration(milliseconds: 300)); // Short delay
                                  await _loadAndShowDialog(context, api, spelledWordsLogic); // Reload dialog
                                  return;
                                } else {
                                  print("🚨 Failed to submit high score.");
                                }
                              } catch (e) {
                                print("🚨 Error submitting high score: $e");
                              }
                            },
                            style: AppStyles.buttonStyle(context),
                            child: const Text('Submit Score'),
                          ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: AppStyles.buttonStyle(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppStyles.dialogButtonPadding),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
