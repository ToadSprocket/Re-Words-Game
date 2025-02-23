// main.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'styles/app_styles.dart';
import 'logic/word_loader.dart';
import 'logic/grid_loader.dart';
import 'logic/game_layout.dart'; // Add for GameLayout
import 'screens/wide_screen.dart';
import 'screens/narrow_screen.dart';
import 'logic/spelled_words_handler.dart';
import 'layouts/how_to_play_dialog.dart';
import 'layouts/high_scores_dialog.dart';
import 'layouts/legal_dialog.dart';

const bool debugShowBorders = false;
const bool? debugForceIsWeb = false;

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
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await WordLoader.loadWords();
    await GridLoader.loadGrid();
    setState(() {});
  }

  void addWord() {
    if (WordLoader.words.isNotEmpty) {
      String randomWord = WordLoader.words[Random().nextInt(WordLoader.words.length)];
      SpelledWordsLogic.addWord(randomWord);
      setState(() {});
    }
  }

  void clearWords() {
    SpelledWordsLogic.spelledWords.clear();
    SpelledWordsLogic.score = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = debugForceIsWeb ?? MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Center(
        child:
            isWeb
                ? WideScreen(
                  showBorders: debugShowBorders,
                  onSubmit: addWord,
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context),
                  onHighScores: () => HighScoresDialog.show(context),
                  onLegal: () => LegalDialog.show(context),
                )
                : NarrowScreen(
                  showBorders: debugShowBorders,
                  onSubmit: addWord,
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context),
                  onHighScores: () => HighScoresDialog.show(context),
                  onLegal: () => LegalDialog.show(context),
                ),
      ),
    );
  }
}
