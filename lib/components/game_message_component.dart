// components/game_message_component.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class GameMessageComponent extends StatefulWidget {
  final String message;

  const GameMessageComponent({super.key, required this.message});

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
          style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
