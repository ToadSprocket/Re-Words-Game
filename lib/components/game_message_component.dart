// components/game_message_component.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
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

  @override
  void didUpdateWidget(GameMessageComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.isNotEmpty) {
      setState(() {
        displayMessage = widget.message;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            displayMessage = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Center(
        child: Text(
          displayMessage ?? '',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.gameLayoutManager.gameMessageFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
