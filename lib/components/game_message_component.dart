// File: /lib/components/game_message_component.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'dart:async';
import 'package:flutter/material.dart';
import '../managers/gameManager.dart';
import '../styles/app_styles.dart';

class GameMessageComponent extends StatefulWidget {
  final String message;
  final String currentWord;
  final double width;
  final double height;

  const GameMessageComponent({
    super.key,
    required this.width,
    required this.height,
    required this.message,
    this.currentWord = '',
  });

  @override
  _GameMessageComponentState createState() => _GameMessageComponentState();
}

class _GameMessageComponentState extends State<GameMessageComponent> {
  String? displayMessage;
  bool isImportantMessage = false;
  DateTime? messageDisplayTime;
  Timer? messageTimer;

  @override
  void initState() {
    super.initState();
    messageTimer = null;
  }

  @override
  void dispose() {
    messageTimer?.cancel();
    super.dispose();
  }

  bool _isImportantMessage(String message) {
    return message.contains("multiplied by");
  }

  int _getMessageDuration(String message) {
    return _isImportantMessage(message) ? 3 : 2;
  }

  @override
  void didUpdateWidget(GameMessageComponent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.message.isNotEmpty) {
      final now = DateTime.now();
      final newMessageIsImportant = _isImportantMessage(widget.message);

      final shouldUpdateMessage =
          displayMessage == null ||
          newMessageIsImportant ||
          widget.message != displayMessage ||
          (messageDisplayTime != null && now.difference(messageDisplayTime!).inMilliseconds > 1500);

      if (shouldUpdateMessage) {
        messageTimer?.cancel();

        setState(() {
          displayMessage = widget.message;
          isImportantMessage = newMessageIsImportant;
          messageDisplayTime = now;
        });

        final duration = _getMessageDuration(widget.message);
        messageTimer = Timer(Duration(seconds: duration), () {
          if (mounted) {
            setState(() {
              displayMessage = null;
              isImportantMessage = false;
              messageDisplayTime = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;

    // Determine what to display with priority:
    // 1. Timed feedback messages (errors, wildcard bonuses) — white/green
    // 2. Word being built from selected tiles — spelledWordTextColor (gold)
    // 3. Nothing
    final String textToShow;
    final Color textColor;

    if (displayMessage != null) {
      // Active timed message takes priority
      textToShow = displayMessage!;
      textColor = isImportantMessage ? Colors.green : Colors.white;
    } else if (widget.currentWord.isNotEmpty) {
      // Show the word being built as fallback
      textToShow = widget.currentWord;
      textColor = AppStyles.spelledWordTextColor;
    } else {
      textToShow = '';
      textColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Center(
        child: Text(
          textToShow,
          style: TextStyle(color: textColor, fontSize: layout.gameMessageFontSize, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
