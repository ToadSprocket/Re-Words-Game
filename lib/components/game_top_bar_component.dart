// layouts/game_top_bar.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '/styles/app_styles.dart';
import '../logic/api_service.dart';
import '../dialogs/logout_dialog.dart';
import '../logic/spelled_words_handler.dart';
import '../logic/logging_handler.dart';
import '../managers/gameLayoutManager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GameTopBarComponent extends StatefulWidget {
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;
  final VoidCallback onLogin;
  final ApiService api;
  final SpelledWordsLogic spelledWordsLogic;
  final bool showBorders;
  final GameLayoutManager gameLayoutManager;

  const GameTopBarComponent({
    super.key,
    required this.onInstructions,
    required this.onHighScores,
    required this.onLegal,
    required this.showBorders,
    required this.onLogin,
    required this.api,
    required this.spelledWordsLogic,
    required this.gameLayoutManager,
  });

  @override
  _GameTopBarComponentState createState() => _GameTopBarComponentState();
}

class _GameTopBarComponentState extends State<GameTopBarComponent> {
  @override
  void initState() {
    super.initState();
    widget.api.addListener(_updateState); // 🔥 Listen for login state changes
  }

  @override
  void dispose() {
    widget.api.removeListener(_updateState); // Cleanup
    super.dispose();
  }

  void _updateState() {
    LogService.logInfo('GameTopBarComponent: Login state changed');
    setState(() {}); // 🔄 Rebuild when login state changes
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = widget.api.loggedIn ?? false;

    return Container(
      decoration: widget.showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 1)) : null,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.help_outline, size: 20.0, color: AppStyles.infoBarIconColors),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: widget.onInstructions,
              tooltip: 'How to Play',
            ),
            const SizedBox(width: 6.0),
            IconButton(
              icon: const Icon(Icons.bar_chart, size: 20.0, color: AppStyles.infoBarIconColors),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: widget.onHighScores,
              tooltip: 'High Scores',
            ),
            const SizedBox(width: 6.0),
            IconButton(
              icon: const Icon(Icons.gavel, size: 20.0, color: AppStyles.infoBarIconColors),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: widget.onLegal,
              tooltip: 'Legal',
            ),
            const SizedBox(width: 6.0),
            IconButton(
              icon: Icon(
                widget.api.loggedIn ? Icons.account_circle : Icons.login,
                size: 20.0,
                color: widget.api.loggedIn ? Colors.green : AppStyles.infoBarIconColors,
              ),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: () {
                if (widget.api.loggedIn) {
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
                  LogoutDialog.show(context, widget.api, widget.gameLayoutManager);
                } else {
                  widget.onLogin();
                }
              },
              tooltip: widget.api.loggedIn ? (kIsWeb ? 'Logged In (Alpha)' : 'Logged In') : 'Login',
            ),
            const SizedBox(width: 6.0),
          ],
        ),
      ),
    );
  }
}
