// layouts/game_top_bar.dart
// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import '/styles/app_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../logic/api_service.dart';
import '../dialogs/logout_dialog.dart';
import '../logic/spelled_words_handler.dart';

class GameTopBarComponent extends StatefulWidget {
  final VoidCallback onInstructions;
  final VoidCallback onHighScores;
  final VoidCallback onLegal;
  final VoidCallback onLogin;
  final ApiService api;
  final SpelledWordsLogic spelledWordsLogic;
  final bool showBorders;

  const GameTopBarComponent({
    super.key,
    required this.onInstructions,
    required this.onHighScores,
    required this.onLegal,
    required this.showBorders,
    required this.onLogin,
    required this.api,
    required this.spelledWordsLogic,
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
    print('GameTopBarComponent: Login state changed');
    setState(() {}); // 🔄 Rebuild when login state changes
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = widget.api.loggedIn ?? false;

    return Container(
      decoration: widget.showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 1.0)) : null,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.circleQuestion, size: 20.0, color: AppStyles.helpIconColor),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: widget.onInstructions,
              tooltip: 'How to Play',
            ),
            const SizedBox(width: 6.0),
            IconButton(
              icon: const Icon(FontAwesomeIcons.chartSimple, size: 20.0, color: AppStyles.helpIconColor),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: widget.onHighScores,
              tooltip: 'High Scores',
            ),
            const SizedBox(width: 6.0),
            IconButton(
              icon: const Icon(FontAwesomeIcons.gavel, size: 20.0, color: AppStyles.helpIconColor),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: widget.onLegal,
              tooltip: 'Legal',
            ),
            const SizedBox(width: 6.0),
            IconButton(
              icon: Icon(
                widget.api.loggedIn ? FontAwesomeIcons.circleUser : FontAwesomeIcons.arrowRightToBracket,
                size: 20.0,
                color: widget.api.loggedIn ? Colors.green : AppStyles.helpIconColor,
              ),
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(),
              onPressed: () {
                if (widget.api.loggedIn) {
                  LogoutDialog.show(context, widget.api); // 🔥 Show logout confirmation
                } else {
                  widget.onLogin(); // 🔥 Show login dialog
                }
              },
              tooltip: widget.api.loggedIn ? 'Logged In' : 'Login',
            ),
            const SizedBox(width: 6.0),
          ],
        ),
      ),
    );
  }
}
