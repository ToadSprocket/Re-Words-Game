import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../styles/app_styles.dart';
import '../services/api_service.dart';
import '../models/apiModels.dart';
import '../logic/spelled_words_handler.dart';
import '../logic/logging_handler.dart';
import '../managers/gameLayoutManager.dart';
import '../providers/game_state_provider.dart';
import 'login_dialog.dart';

class HighScoresDialog {
  static Future<void> show(
    BuildContext context,
    ApiService api,
    SpelledWordsLogic spelledWordsLogic,
    GameLayoutManager gameLayoutManager, {
    GameStateProvider? gameStateProvider,
  }) async {
    // If gameStateProvider is not provided, try to get it from the context
    final provider = gameStateProvider ?? Provider.of<GameStateProvider>(context, listen: false);
    await _loadAndShowDialog(context, api, spelledWordsLogic, gameLayoutManager, provider);
  }

  static Future<void> _loadAndShowDialog(
    BuildContext context,
    ApiService api,
    SpelledWordsLogic spelledWordsLogic,
    GameLayoutManager gameLayoutManager,
    GameStateProvider gameStateProvider,
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
      gameId: '',
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

      // Use the gameId from finalScore to get game-specific high scores
      final response = await api.getGameHighScores(finalScore.gameId);
      highScores = response.highScoreData?.highScores ?? [];
      scoresSubmittedToday = response.highScoreData?.totalScoresToday ?? 0;
      userHasSubmitted = response.highScoreData?.userHasSubmitted ?? false;
      userRank = response.highScoreData?.userRank;

      final rawDate = response.highScoreData?.date ?? 'Today';
      date = rawDate == 'Today' ? 'Today' : DateFormat('MMMM d, yyyy').format(DateTime.parse(rawDate).toUtc());

      // Check if user is already on the board
      bool userIsOnBoard = highScores.any((score) => score.userId == api.userId);

      // Only allow score submission if:
      // 1. User hasn't submitted a score today
      // 2. User is not already on the board
      // No need to check score comparison since we're using userId to determine if they're on the board
      if (!userHasSubmitted && !userIsOnBoard && (highScores.isEmpty || finalScore.score > highScores.last.score)) {
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
            // Calculate responsive dimensions
            double maxHeight = constraints.maxHeight * 0.85; // Increased from 0.8 to 0.85
            double minHeight = 300.0; // Increased from 200.0 to 300.0

            // More generous height calculation - add more space per score
            double calculatedHeight = (50 + (highScores.length * 60)).clamp(minHeight, maxHeight).toDouble();

            // Calculate responsive width
            double dialogWidth =
                constraints.maxWidth > 600
                    ? gameLayoutManager.dialogMaxWidth
                    : constraints.maxWidth * 0.95; // Use 95% of screen width on narrow screens

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
                side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
              ),
              backgroundColor: AppStyles.dialogBackgroundColor,
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0), // Increased bottom padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [Center(child: Text('High Scores - $date', style: gameLayoutManager.dialogTitleStyle))],
                    ),
                    const SizedBox(height: 16.0),
                    // Scores list with improved spacing
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: dialogWidth * 0.9),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (highScores.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          'No high scores available yet.',
                                          style: gameLayoutManager.dialogContentStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  else
                                    ...highScores.map((score) {
                                      bool isUser = score.ranking == userRank;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '${score.ranking}. ',
                                                    style:
                                                        isUser
                                                            ? gameLayoutManager.dialogContentHighLiteStyle
                                                            : gameLayoutManager.dialogContentStyle,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      '${score.displayName.isNotEmpty ? score.displayName : "Unknown Player"}',
                                                      style:
                                                          isUser && score.displayName.isNotEmpty
                                                              ? gameLayoutManager.dialogContentHighLiteStyle
                                                              : gameLayoutManager.dialogContentStyle,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
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
                                                        Icons.face_retouching_off,
                                                        size: 16.0,
                                                        color: AppStyles.dialogIconColor,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8.0),
                                              child: Text(
                                                '${score.score} (${score.wordCount})',
                                                style: gameLayoutManager.dialogContentStyle.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                  // Show user's ranking if not in top scores
                                  if (userHasSubmitted &&
                                      userRank != null &&
                                      !highScores.any((s) => s.ranking == userRank))
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      child: Center(
                                        child: Text(
                                          'Your Ranking: #$userRank out of $scoresSubmittedToday players',
                                          style: gameLayoutManager.dialogContentHighLiteStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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

                    // Add extra space before buttons on small screens
                    const SizedBox(height: 8.0),

                    // Use a more responsive button layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // For narrow screens, use a column layout for buttons
                        if (constraints.maxWidth < 400) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // If logged in and has good score that can be submitted
                              if (loggedIn && hasGoodScore && canSubmitScore)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final scoreSubmitted = await api.submitHighScore(finalScore);
                                        if (scoreSubmitted && context.mounted) {
                                          LogService.logInfo('High score submitted successfully!');

                                          // Mark the game as finished
                                          await gameStateProvider.finishGame();
                                          LogService.logInfo('Game marked as finished after high score submission');

                                          Navigator.of(context).pop();
                                          await Future.delayed(const Duration(milliseconds: 100));
                                          if (context.mounted) {
                                            await show(
                                              context,
                                              api,
                                              spelledWordsLogic,
                                              gameLayoutManager,
                                              gameStateProvider: gameStateProvider,
                                            );
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
                                ),
                              // If not logged in but has good score
                              if (!loggedIn && hasGoodScore)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final loginSuccess = await LoginDialog.show(context, api, gameLayoutManager);
                                      if (loginSuccess && context.mounted) {
                                        Navigator.of(context).pop();
                                        await Future.delayed(const Duration(milliseconds: 100));
                                        if (context.mounted) {
                                          await show(
                                            context,
                                            api,
                                            spelledWordsLogic,
                                            gameLayoutManager,
                                            gameStateProvider: gameStateProvider,
                                          );
                                        }
                                      }
                                    },
                                    style: gameLayoutManager.buttonStyle(context),
                                    child: const Text('Login to Submit'),
                                  ),
                                ),
                              // Close button
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: gameLayoutManager.buttonStyle(context),
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        } else {
                          // For wider screens, use a row layout
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // If logged in and has good score that can be submitted
                              if (loggedIn && hasGoodScore && canSubmitScore)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final scoreSubmitted = await api.submitHighScore(finalScore);
                                        if (scoreSubmitted && context.mounted) {
                                          LogService.logInfo('High score submitted successfully!');

                                          // Mark the game as finished
                                          await gameStateProvider.finishGame();
                                          LogService.logInfo('Game marked as finished after high score submission');

                                          Navigator.of(context).pop();
                                          await Future.delayed(const Duration(milliseconds: 100));
                                          if (context.mounted) {
                                            await show(
                                              context,
                                              api,
                                              spelledWordsLogic,
                                              gameLayoutManager,
                                              gameStateProvider: gameStateProvider,
                                            );
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
                                ),
                              // If not logged in but has good score
                              if (!loggedIn && hasGoodScore)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final loginSuccess = await LoginDialog.show(context, api, gameLayoutManager);
                                      if (loginSuccess && context.mounted) {
                                        Navigator.of(context).pop();
                                        await Future.delayed(const Duration(milliseconds: 100));
                                        if (context.mounted) {
                                          await show(
                                            context,
                                            api,
                                            spelledWordsLogic,
                                            gameLayoutManager,
                                            gameStateProvider: gameStateProvider,
                                          );
                                        }
                                      }
                                    },
                                    style: gameLayoutManager.buttonStyle(context),
                                    child: const Text('Login to Submit'),
                                  ),
                                ),
                              // Close button
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: gameLayoutManager.buttonStyle(context),
                                  child: const Text('Close'),
                                ),
                              ),
                            ],
                          );
                        }
                      },
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
