// main.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'styles/app_styles.dart';
import 'logic/word_loader.dart';
import 'logic/grid_loader.dart';
import 'logic/game_layout.dart';
import 'screens/wide_screen.dart';
import 'screens/narrow_screen.dart';
import 'logic/spelled_words_handler.dart';
import 'dialogs/how_to_play_dialog.dart';
import 'dialogs/high_scores_dialog.dart';
import 'dialogs/legal_dialog.dart';
import 'components/game_grid_component.dart';
import 'components/wildcard_column_component.dart';

const bool debugShowBorders = false;
const bool? debugForceIsWeb = null;

void main() {
  runApp(const ReWordApp());
}

class ReWordApp extends StatelessWidget {
  const ReWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re-Word Game',
      theme: AppStyles.appTheme,
      home: const GameLayoutProvider(child: HomeScreen()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _gridKey = GlobalKey<GameGridComponentState>();
  final _wildcardKey = GlobalKey<WildcardColumnComponentState>();
  String submitMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await WordLoader.loadWords();
    await GridLoader.loadGrid(); // Ensure grid loads here too
    setState(() {});
  }

  void submitWord() {
    setState(() {
      _gridKey.currentState?.submitWord(); // Triggers validation and scoring
    });
  }

  void clearWords() {
    setState(() {
      _gridKey.currentState?.clearSelectedTiles();
      _wildcardKey.currentState?.clearSelectedTiles();
      submitMessage = '';
    });
  }

  void _handleMessage(String message) {
    setState(() {
      submitMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizes = GameLayout.of(context).sizes;
    final isWebOverride = debugForceIsWeb ?? sizes['isWeb'] as bool;
    print(
      'screenWidth: ${MediaQuery.of(context).size.width}, debugForceIsWeb: $debugForceIsWeb, isWeb: $isWebOverride',
    );
    final isWeb = isWebOverride;

    return Scaffold(
      body: Center(
        child:
            isWeb
                ? WideScreen(
                  showBorders: debugShowBorders,
                  onSubmit: submitWord, // Updated
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context),
                  onHighScores: () => HighScoresDialog.show(context),
                  onLegal: () => LegalDialog.show(context),
                  gridKey: _gridKey,
                  wildcardKey: _wildcardKey,
                  onMessage: _handleMessage, // Pass callback
                  message: submitMessage, // Updated
                )
                : NarrowScreen(
                  showBorders: debugShowBorders,
                  onSubmit: submitWord, // Updated
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context),
                  onHighScores: () => HighScoresDialog.show(context),
                  onLegal: () => LegalDialog.show(context),
                  gridKey: _gridKey,
                  wildcardKey: _wildcardKey,
                  onMessage: _handleMessage, // Pass callback
                  message: submitMessage, // Updated
                ),
      ),
    );
  }
}
