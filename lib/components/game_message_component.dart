// components/game_message_component.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:async';
import 'package:flutter/material.dart';
import '../managers/gameLayoutManager.dart';

class GameMessageComponent extends StatefulWidget {
  final String message;
  final double width;
  final double height;
  final GameLayoutManager gameLayoutManager;

  const GameMessageComponent({
    super.key,
    required this.width,
    required this.height,
    required this.message,
    required this.gameLayoutManager,
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
    // Consider wildcard multiplier messages as important
    return message.contains("multiplied by");
  }

  int _getMessageDuration(String message) {
    // Important messages stay longer
    return _isImportantMessage(message) ? 3 : 2;
  }

  @override
  void didUpdateWidget(GameMessageComponent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.message.isNotEmpty) {
      final now = DateTime.now();
      final newMessageIsImportant = _isImportantMessage(widget.message);

      // If there's no current message, or the new message is important,
      // or the new message is different from the current one,
      // or the current message has been displayed for at least 1.5 seconds
      final shouldUpdateMessage =
          displayMessage == null ||
          newMessageIsImportant ||
          widget.message != displayMessage || // Check if the message is different
          (messageDisplayTime != null && now.difference(messageDisplayTime!).inMilliseconds > 1500);

      if (shouldUpdateMessage) {
        // Cancel any existing timer
        messageTimer?.cancel();

        setState(() {
          displayMessage = widget.message;
          isImportantMessage = newMessageIsImportant;
          messageDisplayTime = now;
        });

        // Set a new timer based on message importance
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
    final textColor = isImportantMessage ? Colors.green : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Center(
        child: Text(
          displayMessage ?? '',
          style: TextStyle(
            color: textColor,
            fontSize: widget.gameLayoutManager.gameMessageFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
