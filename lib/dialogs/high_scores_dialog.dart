import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../styles/app_styles.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../logic/spelled_words_handler.dart';
import '../logic/logging_handler.dart';
import '../managers/gameLayoutManager.dart';
import 'login_dialog.dart';

class HighScoresDialog {
  static Future<void> show(
    BuildContext context,
    ApiService api,
    SpelledWordsLogic spelledWordsLogic,
    GameLayoutManager gameLayoutManager,
  ) async {
    await _loadAndShowDialog(context, api, spelledWordsLogic, gameLayoutManager);
  }

  static Future<void> _loadAndShowDialog(
    BuildContext context,
    ApiService api,
    SpelledWordsLogic spelledWordsLogic,
    GameLayoutManager gameLayoutManager,
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
      LogService.logError('Failed to fetch high scores: $e');
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
                width: gameLayoutManager.dialogMaxWidth,
                height: calculatedHeight, // ✅ Dynamic height
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [Center(child: Text('High Scores - $date', style: gameLayoutManager.dialogTitleStyle))],
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: SizedBox(
                            width: gameLayoutManager.dialogMaxWidth * 0.8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (highScores.isEmpty)
                                  Text('No high scores available yet.', style: gameLayoutManager.dialogContentStyle)
                                else
                                  ...highScores.map((score) {
                                    bool isUser = score.ranking == userRank;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${score.ranking}. ${score.displayName.isNotEmpty ? score.displayName : "Unknown Player"}',
                                                style:
                                                    isUser && score.displayName.isNotEmpty
                                                        ? gameLayoutManager.dialogContentHighLiteStyle
                                                        : gameLayoutManager.dialogContentStyle,
                                              ),
                                              if (score.displayName.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4.0),
                                                  child: Icon(
                                                    Icons.person_outline,
                                                    size: 16.0,
                                                    color: AppStyles.dialogIconColor,
                                                  ),
                                                )
                                              else
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4.0),
                                                  child: Icon(
                                                    Icons
                                                        .face_retouching_off, // This is similar to a ninja/anonymous face
                                                    size: 16.0,
                                                    color: AppStyles.dialogIconColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Text(
                                            '${score.score} (${score.wordCount} words)',
                                            style: gameLayoutManager.dialogContentStyle.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                // ✅ Show user's ranking if not in top scores
                                if (userHasSubmitted &&
                                    userRank != null &&
                                    !highScores.any((s) => s.ranking == userRank))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Center(
                                      child: Text(
                                        'Your Ranking: #$userRank out of $scoresSubmittedToday players',
                                        style: gameLayoutManager.dialogContentHighLiteStyle,
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

                    // Show encouragement message if user has a good score
                    if (hasGoodScore && !userHasSubmitted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          loggedIn
                              ? "Great score! Submit it to the leaderboard!"
                              : "Great score! Log in to submit to the leaderboard!",
                          style: gameLayoutManager.dialogContentHighLiteStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // If logged in and has good score that can be submitted
                        if (loggedIn && hasGoodScore && canSubmitScore)
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                final scoreSubmitted = await api.submitHighScore(finalScore);
                                if (scoreSubmitted && context.mounted) {
                                  LogService.logInfo('High score submitted successfully!');

                                  // Close this dialog
                                  Navigator.of(context).pop();

                                  // Use a short delay to ensure the dialog is fully closed
                                  await Future.delayed(const Duration(milliseconds: 100));

                                  // Show a new high scores dialog with the updated state
                                  if (context.mounted) {
                                    await show(context, api, spelledWordsLogic, gameLayoutManager);
                                  }
                                  return;
                                } else {
                                  LogService.logError('Failed to submit high score.');
                                }
                              } catch (e) {
                                LogService.logError('Error submitting high score: $e');
                              }
                            },
                            style: gameLayoutManager.buttonStyle(context),
                            child: const Text('Submit Score'),
                          ),
                        // If not logged in but has good score
                        if (!loggedIn && hasGoodScore)
                          ElevatedButton(
                            onPressed: () async {
                              // Show login dialog without closing the high scores dialog
                              final loginSuccess = await LoginDialog.show(context, api, gameLayoutManager);

                              if (loginSuccess && context.mounted) {
                                // If login was successful, close this dialog and show a new one
                                Navigator.of(context).pop();

                                // Use a short delay to ensure the dialog is fully closed
                                await Future.delayed(const Duration(milliseconds: 100));

                                // Show a new high scores dialog with the updated login state
                                if (context.mounted) {
                                  await show(context, api, spelledWordsLogic, gameLayoutManager);
                                }
                              }
                            },
                            style: gameLayoutManager.buttonStyle(context),
                            child: const Text('Login to Submit'),
                          ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: gameLayoutManager.buttonStyle(context),
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
