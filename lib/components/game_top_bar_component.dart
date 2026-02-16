// File: /lib/components/game_top_bar_component.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '/styles/app_styles.dart';
import '../managers/gameManager.dart';
import '../config/debugConfig.dart';
import '../dialogs/how_to_play_dialog.dart';
import '../dialogs/high_scores_dialog.dart';
import '../dialogs/legal_dialog.dart';
import '../dialogs/login_dialog.dart';
import '../dialogs/logout_dialog.dart';
import '../dialogs/board_expired_dialog.dart';
import '../dialogs/new_board_loaded_dialog.dart';
import '../config/config.dart';
import '../logic/logging_handler.dart';

class GameTopBarComponent extends StatelessWidget {
  const GameTopBarComponent({super.key});

  /// Handles manual expiration checks when the user taps the expired label.
  /// This gives players an in-session path to load a new board without
  /// requiring an app restart or lifecycle transition.
  Future<void> _handleExpiredTap(BuildContext context, GameManager gm) async {
    // Track manual checks separately so device logs clearly show user-triggered flow.
    LogService.logEvent("LCYCL:ManualExpChk");

    final minutesExpired = await gm.board.minutesBoardIsExpired();
    LogService.logEvent("LCYCL:ManualExpChk:${minutesExpired}m");

    // Safety: if board is no longer expired by the time user taps, do nothing.
    if (minutesExpired == 0) return;

    if (minutesExpired > Config.expiredBoardGracePeriodMinutes) {
      // Past grace period: force-load a new board and show the simple confirmation dialog.
      final success = await gm.loadNewBoard();
      if (success && context.mounted) {
        gm.startCountdownTimer();
        await NewBoardLoadedDialog.show(context);
      } else if (!success) {
        gm.setMessage('Server unavailable — playing with current board');
      }
      return;
    }

    // Inside grace period: let the user decide explicitly.
    final loadNew = await BoardExpiredDialog.show(context);
    if (loadNew == true) {
      final success = await gm.loadNewBoard();
      if (success) {
        gm.startCountdownTimer();
      } else {
        gm.setMessage('Server unavailable — playing with current board');
      }
    } else {
      // Keep-playing choice is persisted so resume checks respect this preference.
      gm.board = gm.board.copyWith(isPlayingExpired: true);
      await gm.board.saveBoardToStorage();
      // Immediately refresh countdown text so "expired" state appears now,
      // instead of waiting for the next timer tick.
      gm.updateCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = context.watch<GameManager>();
    // Read showBorders from centralized debug config
    final showBorders = DebugConfig().showBorders;
    bool isLoggedIn = gm.apiService.loggedIn ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 1)) : null,
          child: SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Countdown timer and display name
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Board countdown timer (e.g., "15h 42m" or "EXPIRED")
                    if (gm.boardCountdown.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          // Only enable tap behavior in expired state.
                          onTap:
                              gm.boardCountdown == 'Board Expired'
                                  ? () async {
                                    await _handleExpiredTap(context, gm);
                                  }
                                  : null,
                          child: Text(
                            gm.boardCountdown == 'Board Expired' ? 'Board Expired (tap for new)' : gm.boardCountdown,
                            style: TextStyle(
                              color:
                                  gm.board.isPlayingExpired
                                      ? AppStyles.boardTimerCountdownAlertColor
                                      : AppStyles.boardTimerCountdownColor,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    // Display name (shown when logged in, after countdown)
                    if (isLoggedIn && gm.apiService.displayName != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(
                          gm.apiService.displayName!,
                          style: TextStyle(color: Colors.green, fontSize: 14.0, fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),

                // Right side - Icons in a Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 20.0, color: AppStyles.infoBarIconColors),
                      padding: const EdgeInsets.all(4.0),
                      constraints: const BoxConstraints(),
                      onPressed: () => HowToPlayDialog.show(context, gm),
                      tooltip: 'How to Play',
                    ),
                    const SizedBox(width: 6.0),
                    IconButton(
                      icon: const Icon(Icons.bar_chart, size: 20.0, color: AppStyles.infoBarIconColors),
                      padding: const EdgeInsets.all(4.0),
                      constraints: const BoxConstraints(),
                      onPressed: () => HighScoresDialog.show(context, gm),
                      tooltip: 'High Scores',
                    ),
                    const SizedBox(width: 6.0),
                    IconButton(
                      icon: const Icon(Icons.gavel, size: 20.0, color: AppStyles.infoBarIconColors),
                      padding: const EdgeInsets.all(4.0),
                      constraints: const BoxConstraints(),
                      onPressed: () => LegalDialog.show(context, gm),
                      tooltip: 'Legal',
                    ),
                    const SizedBox(width: 6.0),
                    IconButton(
                      icon: Icon(
                        gm.apiService.loggedIn ? Icons.account_circle : Icons.login,
                        size: 20.0,
                        color: gm.apiService.loggedIn ? Colors.green : AppStyles.infoBarIconColors,
                      ),
                      padding: const EdgeInsets.all(4.0),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (gm.apiService.loggedIn) {
                          // During alpha testing, prevent web users from logging out
                          if (kIsWeb) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logout disabled during alpha testing on web.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          LogoutDialog.show(context, gm);
                        } else {
                          LoginDialog.show(context, gm);
                        }
                      },
                      tooltip: gm.apiService.loggedIn ? (kIsWeb ? 'Logged In (Alpha)' : 'Logged In') : 'Login',
                    ),
                    const SizedBox(width: 3.0),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 0.5, thickness: 1.0, color: Colors.grey),
      ],
    );
  }
}
